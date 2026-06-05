import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:deep_time_2/app/app_debug.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:yaml/yaml.dart';

part 'timeline_seed_helpers.dart';

class TimelineSeeder {
  const TimelineSeeder._();
  static const int _maPrecision = 3;

  static Future<void> seedIfEmpty(Database db) async {
    final result = db.select(
      'SELECT COUNT(*) AS count FROM geologic_divisions',
    );
    final count = result.first['count'] as int;
    final expectedCount = await _expectedDivisionCount();
    final yamlHash = await _currentYamlHash();
    final storedHash = _readSeedHash(db);
    if (count == expectedCount && storedHash == yamlHash) {
      return;
    }

    try {
      if (count > 0) {
        await _logDivisionDateDiffs(db);
        _clearExistingData(db);
      }
      await _seedDivisionsFromYaml(db);
      await _seedSamplePaleontology(db);
      _writeSeedHash(db, yamlHash);
    } catch (error, stackTrace) {
      AppDebug.log(
        'Failed to seed database',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static void _clearExistingData(Database db) {
    db.execute('BEGIN');
    try {
      db.execute('DELETE FROM fossil_ranges');
      db.execute('DELETE FROM paleontology_taxa');
      db.execute('DELETE FROM geologic_divisions');
      db.execute('COMMIT');
    } catch (error) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  static Future<int> _expectedDivisionCount() async =>
      _countDivisionNodes(await _loadNormalizedEons());

  static Future<String> _currentYamlHash() async {
    final eons = await _loadNormalizedEons();
    final canonical = jsonEncode(_canonicalNodeList(eons));
    return _stableFNVHash(canonical);
  }

  static String? _readSeedHash(Database db) {
    final rows = db.select(
      'SELECT value FROM app_meta WHERE key = ? LIMIT 1',
      const ['timeline_seed_hash'],
    );
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  static void _writeSeedHash(Database db, String hash) {
    db.execute('INSERT OR REPLACE INTO app_meta (key, value) VALUES (?, ?)', [
      'timeline_seed_hash',
      hash,
    ]);
  }

  static Future<void> _seedDivisionsFromYaml(Database db) async {
    final eons = await _loadNormalizedEons();
    db.execute('BEGIN');
    final insertDivision = db.prepare('''
INSERT INTO geologic_divisions (
  name,
  rank,
  start_ma,
  start_ma_uncertainty,
  end_ma,
  explanation,
  parent_id
) VALUES (?, ?, ?, ?, ?, ?, ?)
''');

    try {
      _assignEndDates(eons, parentEndMa: 0.0);
      _validateNodeDates(eons);
      for (final node in eons) {
        _insertNode(db, insertDivision, node, parentId: null);
      }
      db.execute('COMMIT');
    } catch (error) {
      db.execute('ROLLBACK');
      rethrow;
    } finally {
      insertDivision.close();
    }
  }

  static Future<void> _seedSamplePaleontology(Database db) async {
    final insertTaxon = db.prepare(
      'INSERT INTO paleontology_taxa (name, summary) VALUES (?, ?)',
    );
    final insertRange = db.prepare(
      'INSERT INTO fossil_ranges (taxon_id, start_ma, end_ma) VALUES (?, ?, ?)',
    );

    try {
      insertTaxon.execute([
        'Non-avian dinosaurs',
        'Diverse terrestrial reptiles spanning the Triassic to Cretaceous.',
      ]);
      final dinosaurId = db.lastInsertRowId;
      insertRange.execute([dinosaurId, _normMa(233.0), _normMa(66.0)]);

      insertTaxon.execute([
        'Mammals',
        'Synapsids that rose to dominance after the K-Pg boundary.',
      ]);
      final mammalId = db.lastInsertRowId;
      insertRange.execute([mammalId, _normMa(200.0), _normMa(0.0)]);

      insertTaxon.execute([
        'Flowering plants',
        'Angiosperms that diversified during the Cretaceous and Cenozoic.',
      ]);
      final floraId = db.lastInsertRowId;
      insertRange.execute([floraId, _normMa(140.0), _normMa(0.0)]);
    } finally {
      insertTaxon.close();
      insertRange.close();
    }
  }

  static List<_DivisionNode> _readNodes(Object? value) {
    if (value is! YamlList) {
      return const [];
    }
    return value.whereType<YamlMap>().map(_DivisionNode.fromYaml).toList();
  }

  static Future<List<_DivisionNode>> _loadNormalizedEons() async {
    final yamlText = await rootBundle.loadString('data/time_divisions.yaml');
    final document = loadYaml(yamlText) as YamlMap;
    final eons = _readNodes(document['eons']);
    _assignEndDates(eons, parentEndMa: 0.0);
    _validateNodeDates(eons);
    return eons;
  }

  static void _assignEndDates(
    List<_DivisionNode> nodes, {
    required double parentEndMa,
  }) {
    final sorted = List<_DivisionNode>.of(nodes)
      ..sort((a, b) => b.startMa.compareTo(a.startMa));
    for (var index = 0; index < sorted.length; index++) {
      final current = sorted[index];
      final next = index + 1 < sorted.length ? sorted[index + 1] : null;
      current.endMa = _normMa(next?.startMa ?? parentEndMa);
      _assignEndDates(current.children, parentEndMa: current.endMa);
    }
  }

  static void _validateNodeDates(List<_DivisionNode> nodes) {
    for (final node in nodes) {
      if (node.startMa < 0) {
        throw StateError(
          'Invalid start_ma for ${node.rank}:${node.name}: ${node.startMa}',
        );
      }
      if (node.endMa < 0) {
        throw StateError(
          'Invalid end_ma for ${node.rank}:${node.name}: ${node.endMa}',
        );
      }
      if (node.startMa < node.endMa) {
        throw StateError(
          'Invalid range for ${node.rank}:${node.name}: ${node.startMa} < ${node.endMa}',
        );
      }
      if (node.uncertaintyMa != null && node.uncertaintyMa! < 0) {
        throw StateError(
          'Invalid uncertainty_ma for ${node.rank}:${node.name}: ${node.uncertaintyMa}',
        );
      }
      _validateNodeDates(node.children);
    }
  }

  static List<Map<String, Object?>> _canonicalNodeList(
    List<_DivisionNode> nodes,
  ) {
    final out = <Map<String, Object?>>[];
    for (final node in nodes) {
      out.add({
        'name': node.name,
        'rank': node.rank,
        'start_ma': node.startMa,
        'end_ma': node.endMa,
        'uncertainty_ma': node.uncertaintyMa,
        'children': _canonicalNodeList(node.children),
      });
    }
    return out;
  }

  static Future<void> _logDivisionDateDiffs(Database db) async {
    if (!AppDebug.enabled) {
      return;
    }
    final currentRows = db.select('''
SELECT name, rank, start_ma, end_ma, start_ma_uncertainty
FROM geologic_divisions
''');
    final currentByKey =
        <String, ({double start, double end, double? uncertainty})>{};
    for (final row in currentRows) {
      final key = '${row['rank']}::${row['name']}';
      currentByKey[key] = (
        start: _normMa((row['start_ma'] as num).toDouble()),
        end: _normMa((row['end_ma'] as num).toDouble()),
        uncertainty: row['start_ma_uncertainty'] == null
            ? null
            : _normMa((row['start_ma_uncertainty'] as num).toDouble()),
      );
    }

    final nextEons = await _loadNormalizedEons();
    final nextByKey =
        <String, ({double start, double end, double? uncertainty})>{};
    void collect(List<_DivisionNode> nodes) {
      for (final node in nodes) {
        nextByKey['${node.rank}::${node.name}'] = (
          start: node.startMa,
          end: node.endMa,
          uncertainty: node.uncertaintyMa,
        );
        collect(node.children);
      }
    }

    collect(nextEons);

    for (final entry in nextByKey.entries) {
      final before = currentByKey[entry.key];
      final after = entry.value;
      if (before == null) {
        continue;
      }
      final changed =
          before.start != after.start ||
          before.end != after.end ||
          before.uncertainty != after.uncertainty;
      if (changed) {
        AppDebug.log(
          'Date diff ${entry.key}: '
          'start ${before.start} -> ${after.start}, '
          'end ${before.end} -> ${after.end}, '
          'uncertainty ${before.uncertainty} -> ${after.uncertainty}',
        );
      }
    }
  }

  static double _normMa(double value) =>
      double.parse(value.toStringAsFixed(_maPrecision));

  static void _insertNode(
    Database db,
    PreparedStatement stmt,
    _DivisionNode node, {
    required int? parentId,
  }) {
    stmt.execute([
      node.name,
      node.rank,
      node.startMa,
      node.uncertaintyMa,
      node.endMa,
      node.explanation,
      parentId,
    ]);
    final nodeId = db.lastInsertRowId;
    for (final child in node.children) {
      _insertNode(db, stmt, child, parentId: nodeId);
    }
  }
}

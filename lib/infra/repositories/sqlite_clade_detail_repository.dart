import 'dart:io';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:deep_time_2/domain/models/clade.dart';
import 'package:deep_time_2/domain/models/clade_zoom_level.dart';

class SqliteCladeDetailRepository {
  SqliteCladeDetailRepository({required this.assetPath});

  final String assetPath;

  Future<List<Clade>> fetchSubtreeForRoot(String rootId) async {
    final dbFile = await _materializeAssetDatabase();
    if (!dbFile.existsSync()) {
      return const [];
    }
    final db = sqlite3.open(dbFile.path);
    try {
      final result = db.select(
        '''
        SELECT d.*
        FROM clades_detail d
        JOIN clade_detail_roots r ON r.descendant_id = d.id
        WHERE r.root_id = ?
        ORDER BY r.depth ASC, d.display_priority ASC, d.id ASC
        ''',
        [rootId],
      );
      return result.map(_mapRow).toList();
    } finally {
      db.close();
    }
  }

  Future<File> _materializeAssetDatabase() async {
    final supportDir = await getApplicationSupportDirectory();
    await supportDir.create(recursive: true);
    final file = File(p.join(supportDir.path, p.basename(assetPath)));
    if (file.existsSync()) {
      return file;
    }
    final bytes = await rootBundle.load(assetPath);
    await file.writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      flush: true,
    );
    return file;
  }

  Clade _mapRow(Row row) {
    return Clade(
      id: row['id'] as String,
      label: (row['common_label'] as String?) ?? (row['scientific_label'] as String),
      scientificRank: (row['scientific_rank'] as String?) ?? 'clade',
      parentId: row['parent_id'] as String?,
      startMa: (row['start_ma'] as num?)?.toDouble() ?? 0.0,
      endMa: (row['end_ma'] as num?)?.toDouble() ?? 0.0,
      rangeNote: row['range_note'] as String?,
      confidence: row['confidence'] as String?,
      displayGroups: _readJsonStringList(row['display_groups_json']),
      displayPriority: (row['display_priority'] as num?)?.toInt() ?? 999,
      minZoomLevel: parseCladeZoomLevel(
        (row['min_zoom_level'] as String?) ?? CladeZoomLevel.epoch.id,
      ),
      shortDescription: row['short_description'] as String?,
      representativeTaxa: _readJsonStringList(row['representative_taxa_json']),
      extinctionNote: row['extinction_note'] as String?,
      tags: _readJsonStringList(row['tags_json']),
      scientificLabel: row['scientific_label'] as String?,
      openTreeName: row['opentree_name'] as String?,
      ottId: (row['ott_id'] as num?)?.toInt(),
      branchPriority: (row['branch_priority'] as num?)?.toInt(),
      cladisticRole: row['cladistic_role'] as String?,
      includeInMainTree: _readSqlBool(row['include_in_main_tree']),
      collapsedByDefault: _readSqlBool(row['collapsed_by_default']),
      zoomable: _readSqlBool(row['zoomable']) ?? false,
      detailSource: 'sqlite',
      detailScope: 'descendants',
    );
  }

  List<String> _readJsonStringList(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(value);
    if (decoded is! List) {
      return const [];
    }
    return decoded.whereType<String>().toList();
  }

  bool? _readSqlBool(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value != 0;
    }
    return null;
  }
}

import 'package:flutter/services.dart';
import 'package:deep_time_2/domain/models/clade.dart';
import 'package:deep_time_2/domain/models/clade_zoom_level.dart';
import 'package:deep_time_2/domain/repositories/clade_repository.dart';
import 'package:yaml/yaml.dart';

class YamlCladeRepository implements CladeRepository {
  YamlCladeRepository({required this.assetPath});

  final String assetPath;

  @override
  Future<List<Clade>> fetchAll() async {
    final yamlText = await rootBundle.loadString(assetPath);
    final document = loadYaml(yamlText);
    if (document is! YamlList) {
      throw StateError('Expected a YAML list in $assetPath');
    }
    final clades = document.whereType<YamlMap>().map(_parseClade).toList();
    _validateUniqueIds(clades);
    _validateLivingClades(clades);
    return clades;
  }

  Clade _parseClade(YamlMap entry) {
    final id = _requireString(entry, 'id');
    final label = _requireStringWithFallback(
      entry,
      primaryKey: 'common_label',
      fallbackKey: 'label',
    );
    final scientificRank = _requireString(entry, 'scientific_rank');
    final startMa = _requireDouble(entry, 'start_ma');
    final endMa = _requireDouble(entry, 'end_ma');
    final displayGroups = _readStringList(entry['display_groups']);
    final displayPriority = _requireInt(entry, 'display_priority');
    final minZoomLevel = parseCladeZoomLevel(
      _requireString(entry, 'min_zoom_level'),
    );
    return Clade(
      id: id,
      label: label,
      scientificRank: scientificRank,
      parentId: _readString(entry['parent_id']),
      startMa: startMa,
      endMa: endMa,
      rangeNote: _readString(entry['range_note']),
      confidence: _readString(entry['confidence']),
      displayGroups: displayGroups,
      displayPriority: displayPriority,
      minZoomLevel: minZoomLevel,
      shortDescription: _readString(entry['short_description']),
      representativeTaxa: _readStringList(entry['representative_taxa']),
      extinctionNote: _readString(entry['extinction_note']),
      tags: _readStringList(entry['tags']),
      scientificLabel: _readString(entry['scientific_label']),
      openTreeName: _readString(entry['opentree_name']),
      ottId: _readInt(entry['ott_id']),
      branchPriority: _readInt(entry['branch_priority']),
      cladisticRole: _readString(entry['cladistic_role']),
      includeInMainTree: _readBool(entry['include_in_main_tree']),
      collapsedByDefault: _readBool(entry['collapsed_by_default']),
      openTree: _readOpenTreeMetadata(entry['opentree']),
      zoomable: _readBool(entry['zoomable']) ?? false,
      detailSource: _readString(entry['detail_source']),
      detailScope: _readString(entry['detail_scope']),
      startMaDerivation: _readString(entry['start_ma_derivation']),
      startMaNote: _readString(entry['start_ma_note']),
      startMaSources: _readDateSourceList(entry['start_ma_sources']),
    );
  }

  void _validateUniqueIds(List<Clade> clades) {
    final ids = <String>{};
    for (final clade in clades) {
      if (!ids.add(clade.id)) {
        throw StateError('Duplicate clade id: ${clade.id}');
      }
    }
  }

  void _validateLivingClades(List<Clade> clades) {
    for (final clade in clades) {
      if (clade.endMa < 0) {
        throw StateError('Clade ${clade.id} has negative end_ma');
      }
    }
  }

  String _requireString(YamlMap map, String key) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    throw StateError('Missing required "$key" in $assetPath');
  }

  String _requireStringWithFallback(
    YamlMap map, {
    required String primaryKey,
    required String fallbackKey,
  }) {
    final primary = map[primaryKey];
    if (primary is String && primary.trim().isNotEmpty) {
      return primary.trim();
    }
    final fallback = map[fallbackKey];
    if (fallback is String && fallback.trim().isNotEmpty) {
      return fallback.trim();
    }
    throw StateError(
      'Missing required "$primaryKey" (or "$fallbackKey") in $assetPath',
    );
  }

  String? _readString(Object? value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
  }

  double _requireDouble(YamlMap map, String key) {
    final value = _readDouble(map[key]);
    if (value == null) {
      throw StateError('Missing required "$key" in $assetPath');
    }
    return value;
  }

  double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  int _requireInt(YamlMap map, String key) {
    final value = map[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    throw StateError('Missing required "$key" in $assetPath');
  }

  int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  bool? _readBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
    return null;
  }

  List<String> _readStringList(Object? value) {
    if (value is! YamlList) {
      return const [];
    }
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  CladeOpenTreeMetadata? _readOpenTreeMetadata(Object? value) {
    if (value is! YamlMap) {
      return null;
    }
    return CladeOpenTreeMetadata(
      ottId: _readInt(value['ott_id']),
      matchedName: _readString(value['matched_name']),
      uniqueName: _readString(value['unique_name']),
      rank: _readString(value['rank']),
      flags: _readStringList(value['flags']),
      lineageIds: _readIntList(value['lineage_ids']),
      checkedAt: _readString(value['checked_at']),
    );
  }

  List<int> _readIntList(Object? value) {
    if (value is! YamlList) {
      return const [];
    }
    return value.map(_readInt).whereType<int>().toList();
  }

  List<CladeDateSource> _readDateSourceList(Object? value) {
    if (value is! YamlList) {
      return const [];
    }
    final sources = <CladeDateSource>[];
    for (final item in value.whereType<YamlMap>()) {
      final label = _readString(item['label']);
      if (label == null || label.isEmpty) {
        continue;
      }
      sources.add(CladeDateSource(label: label, url: _readString(item['url'])));
    }
    return sources;
  }
}

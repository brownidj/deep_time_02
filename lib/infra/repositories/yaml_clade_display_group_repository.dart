import 'package:flutter/services.dart';
import 'package:deep_time_2/domain/models/clade_display_group.dart';
import 'package:deep_time_2/domain/repositories/clade_display_group_repository.dart';
import 'package:yaml/yaml.dart';

class YamlCladeDisplayGroupRepository implements CladeDisplayGroupRepository {
  YamlCladeDisplayGroupRepository({required this.assetPath});

  final String assetPath;

  @override
  Future<List<CladeDisplayGroup>> fetchDisplayGroups() async {
    final yamlText = await rootBundle.loadString(assetPath);
    final document = loadYaml(yamlText);
    if (document is! YamlList) {
      throw StateError('Expected a YAML list in $assetPath');
    }

    final groups = document.whereType<YamlMap>().map(_parseGroup).toList();
    _validateUniqueIds(groups);
    return groups;
  }

  CladeDisplayGroup _parseGroup(YamlMap entry) {
    final id = _requireString(entry, 'id');
    final label = _requireString(entry, 'label');
    final description = _requireString(entry, 'description');
    return CladeDisplayGroup(id: id, label: label, description: description);
  }

  void _validateUniqueIds(List<CladeDisplayGroup> groups) {
    final ids = <String>{};
    for (final group in groups) {
      if (!ids.add(group.id)) {
        throw StateError('Duplicate clade display group id: ${group.id}');
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
}

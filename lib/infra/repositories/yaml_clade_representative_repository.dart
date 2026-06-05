import 'package:flutter/services.dart';
import 'package:deep_time_2/domain/repositories/clade_representative_repository.dart';
import 'package:yaml/yaml.dart';

class YamlCladeRepresentativeRepository
    implements CladeRepresentativeRepository {
  YamlCladeRepresentativeRepository({required this.assetPath});

  final String assetPath;

  @override
  Future<List<String>> fetchRepresentativeIds() async {
    final yamlText = await rootBundle.loadString(assetPath);
    final document = loadYaml(yamlText);
    if (document is! YamlList) {
      throw StateError('Expected a YAML list in $assetPath');
    }
    final ids = <String>[];
    for (final entry in document) {
      if (entry is! String) {
        throw StateError('Invalid clade id entry in $assetPath');
      }
      final trimmed = entry.trim();
      if (trimmed.isNotEmpty) {
        ids.add(trimmed);
      }
    }
    return ids;
  }
}

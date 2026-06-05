import 'package:flutter/services.dart';
import 'package:deep_time_2/domain/models/timeline_palette.dart';
import 'package:deep_time_2/domain/repositories/timeline_palette_repository.dart';
import 'package:yaml/yaml.dart';

class YamlTimelinePaletteRepository implements TimelinePaletteRepository {
  YamlTimelinePaletteRepository({required this.assetPath});

  final String assetPath;

  @override
  Future<TimelinePalette> fetchPalette() async {
    final yamlText = await rootBundle.loadString(assetPath);
    final document = loadYaml(yamlText) as YamlMap;
    final eons = document['eons'];
    if (eons is! YamlList) {
      throw StateError('Missing eons list in $assetPath');
    }

    final colors = <String, int>{};
    for (final entry in eons) {
      if (entry is! YamlMap) {
        continue;
      }
      _collectDivisionColors(entry, colors, parentKey: null);
    }

    if (colors.isEmpty) {
      throw StateError('No division colors found in $assetPath');
    }

    return TimelinePalette(divisionColors: colors);
  }

  void _collectDivisionColors(
    YamlMap node,
    Map<String, int> output, {
    required String? parentKey,
  }) {
    final name = node['name'] as String?;
    final rank = node['rank'] as String?;
    final startRaw = node['start_ma'] ?? node['end_ma'];
    final color = node['color'] as String?;

    if (name == null || rank == null || startRaw == null) {
      throw StateError(
        'Division node missing name/rank/start_ma in $assetPath',
      );
    }
    if (color == null) {
      throw StateError('Division "$name" is missing color in $assetPath');
    }

    final startMa = _parseDouble(startRaw);
    if (startMa == null) {
      throw StateError('Invalid start_ma for "$name" in $assetPath');
    }

    final key = divisionColorKey(name: name, rank: rank, parentKey: parentKey);
    output[key] = _parseColor(color);

    final children = node['children'];
    if (children is YamlList) {
      for (final child in children) {
        if (child is YamlMap) {
          _collectDivisionColors(child, output, parentKey: key);
        }
      }
    }
  }

  double? _parseDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  int _parseColor(String input) {
    final cleaned = input.trim();
    if (cleaned.startsWith('#')) {
      final hex = cleaned.substring(1);
      if (hex.length == 6) {
        return int.parse('FF$hex', radix: 16);
      }
      if (hex.length == 8) {
        return int.parse(hex, radix: 16);
      }
    }
    if (cleaned.startsWith('0x')) {
      return int.parse(cleaned.substring(2), radix: 16);
    }
    throw StateError('Invalid color value: $input');
  }
}

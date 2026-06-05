import 'package:deep_time_2/domain/models/paleo_ecology_entry.dart';
import 'package:deep_time_2/domain/repositories/paleo_ecology_repository.dart';
import 'package:deep_time_2/domain/models/geologic_rank.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

class YamlPaleoEcologyRepository implements PaleoEcologyRepository {
  YamlPaleoEcologyRepository({required this.assetPath});

  final String assetPath;

  @override
  Future<List<PaleoEcologyEntry>> fetchEntries() async {
    final yamlText = await rootBundle.loadString(assetPath);
    return parseEntries(yamlText);
  }

  List<PaleoEcologyEntry> parseEntries(String yamlText) {
    final document = loadYaml(yamlText) as YamlMap;
    final list = document['paleo_ecology'];
    if (list is! YamlList) {
      return const [];
    }
    return list.whereType<YamlMap>().map(_parseEntry).toList();
  }

  PaleoEcologyEntry _parseEntry(YamlMap map) {
    final metrics = _readMetrics(map);
    return PaleoEcologyEntry(
      rank: _requireRank(map),
      name: _requireString(map, 'name'),
      path: _requireStringList(map, 'path'),
      avgTempDeltaC: metrics.avgTempDeltaC,
      avgHumidityDeltaPercent: metrics.avgHumidityDeltaPercent,
      avgCo2Ppm: metrics.avgCo2Ppm,
      seaLevelDeltaM: metrics.seaLevelDeltaM,
      icehouseGreenhouseState: _readString(map['icehouse_greenhouse_state']),
      dominantEcology: _readString(map['dominant_ecology']),
      confidence: _readString(map['confidence']),
      note: _readString(map['note']),
      sources: _readOptionalStringList(map['sources']),
    );
  }

  GeologicRank _requireRank(YamlMap map) {
    final value = _requireString(map, 'rank');
    for (final rank in GeologicRank.values) {
      if (rank.name == value) {
        return rank;
      }
    }
    throw StateError('Invalid rank "$value" in $assetPath');
  }

  List<String> _requireStringList(YamlMap map, String key) {
    final value = map[key];
    if (value is! YamlList) {
      throw StateError('Missing required string list "$key" in $assetPath');
    }
    final out = [
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
    if (out.length != value.length || out.isEmpty) {
      throw StateError('Invalid string list "$key" in $assetPath');
    }
    return out;
  }

  List<String> _readOptionalStringList(Object? value) {
    if (value is! YamlList) {
      return const [];
    }
    final out = [
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
    return out;
  }

  _PaleoEcologyMetrics _readMetrics(YamlMap map) {
    final temp = _readDouble(map['avg_temp_delta_c']);
    final humidity = _readDouble(map['avg_humidity_delta_percent']);
    final co2 = _readDouble(map['avg_co2_ppm']);
    final seaLevel = _readDouble(map['sea_level_delta_m']);
    return _PaleoEcologyMetrics(
      avgTempDeltaC: temp,
      avgHumidityDeltaPercent: humidity,
      avgCo2Ppm: co2,
      seaLevelDeltaM: seaLevel,
    );
  }

  String _requireString(YamlMap map, String key) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    throw StateError('Missing required string "$key" in $assetPath');
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

  String? _readString(Object? value) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }
}

class _PaleoEcologyMetrics {
  const _PaleoEcologyMetrics({
    required this.avgTempDeltaC,
    required this.avgHumidityDeltaPercent,
    required this.avgCo2Ppm,
    required this.seaLevelDeltaM,
  });

  final double? avgTempDeltaC;
  final double? avgHumidityDeltaPercent;
  final double? avgCo2Ppm;
  final double? seaLevelDeltaM;
}

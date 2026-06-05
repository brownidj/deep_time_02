import 'package:deep_time_2/domain/models/geologic_rank.dart';

class PaleoEcologyEntry {
  const PaleoEcologyEntry({
    required this.rank,
    required this.name,
    required this.path,
    this.avgTempDeltaC,
    this.avgHumidityDeltaPercent,
    this.avgCo2Ppm,
    this.seaLevelDeltaM,
    this.icehouseGreenhouseState,
    this.dominantEcology,
    this.confidence,
    this.note,
    this.sources = const [],
  });

  final GeologicRank rank;
  final String name;
  final List<String> path;
  final double? avgTempDeltaC;
  final double? avgHumidityDeltaPercent;
  final double? avgCo2Ppm;
  final double? seaLevelDeltaM;
  final String? icehouseGreenhouseState;
  final String? dominantEcology;
  final String? confidence;
  final String? note;
  final List<String> sources;

  bool get hasMetricSummary =>
      avgTempDeltaC != null ||
      avgHumidityDeltaPercent != null ||
      avgCo2Ppm != null ||
      seaLevelDeltaM != null;

  bool get hasCompleteMetricSummary =>
      avgTempDeltaC != null &&
      avgHumidityDeltaPercent != null &&
      avgCo2Ppm != null &&
      seaLevelDeltaM != null;

  String get lookupKey => lookupKeyFor(rank: rank, path: path);

  static String lookupKeyFor({
    required GeologicRank rank,
    required List<String> path,
  }) {
    return '${rank.name}:${path.map(_normalizePathPart).join('/')}';
  }

  static String _normalizePathPart(String value) {
    return value.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }
}

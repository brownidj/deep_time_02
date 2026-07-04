import 'package:deep_time_2/domain/models/geologic_rank.dart';

class PaleoEcologyEntry {
  const PaleoEcologyEntry({
    required this.rank,
    required this.name,
    required this.path,
    this.avgTempDeltaC,
    this.avgHumidityDeltaPercent,
    this.avgCo2Ppm,
    this.avgO2Percent,
    this.seaLevelDeltaM,
    this.icehouseGreenhouseState,
    this.dominantEcology,
    this.confidence,
    this.note,
    this.geographicAnchor = const [],
    this.spatialExtent,
    this.spatialConfidence,
    this.hemisphericBias,
    this.manifestationType = const [],
    this.latitudinalExpression = const {},
    this.regionalExpression = const {},
    this.sources = const [],
  });

  final GeologicRank rank;
  final String name;
  final List<String> path;
  final double? avgTempDeltaC;
  final double? avgHumidityDeltaPercent;
  final double? avgCo2Ppm;
  final double? avgO2Percent;
  final double? seaLevelDeltaM;
  final String? icehouseGreenhouseState;
  final String? dominantEcology;
  final String? confidence;
  final String? note;
  final List<String> geographicAnchor;
  final String? spatialExtent;
  final String? spatialConfidence;
  final String? hemisphericBias;
  final List<String> manifestationType;
  final Map<String, String> latitudinalExpression;
  final Map<String, String> regionalExpression;
  final List<String> sources;

  bool get hasMetricSummary =>
      avgTempDeltaC != null ||
      avgHumidityDeltaPercent != null ||
      avgCo2Ppm != null ||
      avgO2Percent != null ||
      seaLevelDeltaM != null;

  bool get hasCompleteMetricSummary =>
      avgTempDeltaC != null &&
      avgHumidityDeltaPercent != null &&
      avgCo2Ppm != null &&
      avgO2Percent != null &&
      seaLevelDeltaM != null;

  bool get hasGeographicSummary =>
      spatialExtent != null ||
      hemisphericBias != null ||
      geographicAnchor.isNotEmpty;

  String get lookupKey => lookupKeyFor(rank: rank, path: path);

  PaleoEcologyEntry copyWith({
    GeologicRank? rank,
    String? name,
    List<String>? path,
    double? avgTempDeltaC,
    double? avgHumidityDeltaPercent,
    double? avgCo2Ppm,
    double? avgO2Percent,
    double? seaLevelDeltaM,
    String? icehouseGreenhouseState,
    String? dominantEcology,
    String? confidence,
    String? note,
    List<String>? geographicAnchor,
    String? spatialExtent,
    String? spatialConfidence,
    String? hemisphericBias,
    List<String>? manifestationType,
    Map<String, String>? latitudinalExpression,
    Map<String, String>? regionalExpression,
    List<String>? sources,
  }) {
    return PaleoEcologyEntry(
      rank: rank ?? this.rank,
      name: name ?? this.name,
      path: path ?? this.path,
      avgTempDeltaC: avgTempDeltaC ?? this.avgTempDeltaC,
      avgHumidityDeltaPercent:
          avgHumidityDeltaPercent ?? this.avgHumidityDeltaPercent,
      avgCo2Ppm: avgCo2Ppm ?? this.avgCo2Ppm,
      avgO2Percent: avgO2Percent ?? this.avgO2Percent,
      seaLevelDeltaM: seaLevelDeltaM ?? this.seaLevelDeltaM,
      icehouseGreenhouseState:
          icehouseGreenhouseState ?? this.icehouseGreenhouseState,
      dominantEcology: dominantEcology ?? this.dominantEcology,
      confidence: confidence ?? this.confidence,
      note: note ?? this.note,
      geographicAnchor: geographicAnchor ?? this.geographicAnchor,
      spatialExtent: spatialExtent ?? this.spatialExtent,
      spatialConfidence: spatialConfidence ?? this.spatialConfidence,
      hemisphericBias: hemisphericBias ?? this.hemisphericBias,
      manifestationType: manifestationType ?? this.manifestationType,
      latitudinalExpression:
          latitudinalExpression ?? this.latitudinalExpression,
      regionalExpression: regionalExpression ?? this.regionalExpression,
      sources: sources ?? this.sources,
    );
  }

  Iterable<String> ancestorLookupKeys() sync* {
    final currentDepth = _rankDepth(rank);
    for (var depth = currentDepth - 1; depth >= 1; depth -= 1) {
      final parentRank = _rankForDepth(depth);
      if (parentRank == null || path.length < depth) {
        continue;
      }
      yield lookupKeyFor(rank: parentRank, path: path.take(depth).toList());
    }
  }

  static String lookupKeyFor({
    required GeologicRank rank,
    required List<String> path,
  }) {
    return '${rank.name}:${path.map(_normalizePathPart).join('/')}';
  }

  static String _normalizePathPart(String value) {
    return value.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  static int _rankDepth(GeologicRank rank) {
    switch (rank) {
      case GeologicRank.eon:
        return 1;
      case GeologicRank.era:
        return 2;
      case GeologicRank.period:
        return 3;
      case GeologicRank.epoch:
        return 4;
      case GeologicRank.stage:
      case GeologicRank.age:
        return 5;
    }
  }

  static GeologicRank? _rankForDepth(int depth) {
    switch (depth) {
      case 1:
        return GeologicRank.eon;
      case 2:
        return GeologicRank.era;
      case 3:
        return GeologicRank.period;
      case 4:
        return GeologicRank.epoch;
      case 5:
        return GeologicRank.stage;
      default:
        return null;
    }
  }
}

PaleoEcologyEntry resolvePaleoEcologyDisplayEntry(
  PaleoEcologyEntry entry,
  Map<String, PaleoEcologyEntry> entriesByKey,
) {
  var resolved = entry;
  for (final key in entry.ancestorLookupKeys()) {
    final ancestor = entriesByKey[key];
    if (ancestor == null) {
      continue;
    }
    resolved = resolved.copyWith(
      geographicAnchor: resolved.geographicAnchor.isNotEmpty
          ? resolved.geographicAnchor
          : ancestor.geographicAnchor,
      spatialExtent: resolved.spatialExtent ?? ancestor.spatialExtent,
      spatialConfidence:
          resolved.spatialConfidence ?? ancestor.spatialConfidence,
      hemisphericBias: resolved.hemisphericBias ?? ancestor.hemisphericBias,
      manifestationType: resolved.manifestationType.isNotEmpty
          ? resolved.manifestationType
          : ancestor.manifestationType,
      latitudinalExpression: resolved.latitudinalExpression.isNotEmpty
          ? resolved.latitudinalExpression
          : ancestor.latitudinalExpression,
      regionalExpression: resolved.regionalExpression.isNotEmpty
          ? resolved.regionalExpression
          : ancestor.regionalExpression,
    );
  }
  return resolved;
}

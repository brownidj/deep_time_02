import 'package:deep_time_2/domain/models/paleo_ecology_entry.dart';

String? paleoEcologySummaryText(
  PaleoEcologyEntry entry, {
  bool showInheritedMarker = false,
}) {
  final lines = <String>[];
  final firstLineParts = <String>[
    if (entry.avgTempDeltaC != null)
      'T\u00A0${_withSign(entry.avgTempDeltaC!)}\u00B0C',
    if (entry.avgHumidityDeltaPercent != null)
      'RH\u00A0${_withSign(entry.avgHumidityDeltaPercent!)}%',
    if (entry.seaLevelDeltaM != null)
      'SL\u00A0${_withSign(entry.seaLevelDeltaM!)}m',
  ];
  if (firstLineParts.isNotEmpty) {
    lines.add(firstLineParts.join('; '));
  }
  final secondLineParts = <String>[
    if (entry.avgO2Percent != null)
      'O2:\u00A0${_formatUnsigned(entry.avgO2Percent!)}%',
    if (entry.avgCo2Ppm != null)
      'CO2\u00A0${_formatUnsigned(entry.avgCo2Ppm!)}ppm',
  ];
  if (secondLineParts.isNotEmpty) {
    lines.add(secondLineParts.join('; '));
  }

  final geographyParts = <String>[
    if (entry.spatialExtent != null)
      'Ex: ${_formatLabelValue(entry.spatialExtent!)}',
    if (entry.hemisphericBias != null && entry.hemisphericBias != 'both')
      'Bi: ${_formatLabelValue(entry.hemisphericBias!)}',
  ];
  if (geographyParts.isNotEmpty) {
    if (showInheritedMarker && entry.geographicAnchor.isEmpty) {
      geographyParts[0] = '${geographyParts[0]}*';
    }
    lines.add(geographyParts.join('; '));
  }
  if (entry.geographicAnchor.isNotEmpty) {
    final prefix = showInheritedMarker ? 'An*:' : 'An:';
    lines.add('$prefix ${entry.geographicAnchor.first}');
  }

  return lines.isEmpty ? null : lines.join('\n');
}

String _formatUnsigned(double value) {
  final magnitude = value.abs();
  if (magnitude == magnitude.roundToDouble()) {
    return magnitude.toStringAsFixed(0);
  }
  return magnitude
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _withSign(double value) {
  final sign = value >= 0 ? '+' : '-';
  final magnitude = value.abs();
  final rounded = magnitude == magnitude.roundToDouble()
      ? magnitude.toStringAsFixed(0)
      : magnitude
            .toStringAsFixed(2)
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), '');
  return '$sign$rounded';
}

String _formatLabelValue(String value) {
  final normalized = value.trim().replaceAll('_', ' ');
  if (normalized.isEmpty) {
    return normalized;
  }
  return normalized
      .split(RegExp(r'\s+'))
      .map((word) {
        final lower = word.toLowerCase();
        if (lower.length <= 1) {
          return lower.toUpperCase();
        }
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}

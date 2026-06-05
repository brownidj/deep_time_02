import 'package:deep_time_2/domain/models/paleo_ecology_entry.dart';

String? paleoEcologySummaryText(PaleoEcologyEntry entry) {
  final parts = <String>[
    if (entry.avgTempDeltaC != null)
      'Temp:\u00A0${_withSign(entry.avgTempDeltaC!)}\u00B0C',
    if (entry.avgCo2Ppm != null)
      'CO2\u00A0${_formatUnsigned(entry.avgCo2Ppm!)}ppm',
    if (entry.avgHumidityDeltaPercent != null)
      'RH:\u00A0${_withSign(entry.avgHumidityDeltaPercent!)}%',
    if (entry.seaLevelDeltaM != null)
      'SL\u00A0${_withSign(entry.seaLevelDeltaM!)}m',
  ];
  return parts.isEmpty ? null : parts.join('; ');
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

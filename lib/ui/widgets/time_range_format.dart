String formatTimeRange({
  required double startMa,
  double? endMa,
  int startPrecision = 1,
  int endPrecision = 1,
  int durationPrecision = 1,
}) {
  final parts = <String>[
    'Start ${startMa.toStringAsFixed(startPrecision)} Ma',
  ];
  if (endMa == null) {
    return '${startMa.toStringAsFixed(startPrecision)} Ma';
  }
  parts.add('End ${endMa.toStringAsFixed(endPrecision)} Ma');
  final duration = (startMa - endMa).abs();
  parts.add('Myr ${duration.toStringAsFixed(durationPrecision)}');
  return parts.join(' - ');
}

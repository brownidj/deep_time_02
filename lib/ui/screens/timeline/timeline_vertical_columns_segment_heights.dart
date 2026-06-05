part of 'timeline_vertical_columns.dart';

List<double> _computeProportionalHeights<T>(
  List<T> segments, {
  required double height,
  required double unitsTotal,
  required double Function(T segment) unitSpan,
}) {
  final heights = <double>[];
  for (final segment in segments) {
    heights.add(height * (unitSpan(segment) / unitsTotal));
  }
  return heights;
}

List<double> _computeHeightsWithMinimums<T>(
  List<T> segments, {
  required double height,
  required double unitsTotal,
  required List<double> minHeights,
  required double Function(T segment) unitSpan,
}) {
  if (segments.isEmpty || height <= 0 || unitsTotal <= 0) {
    return List<double>.filled(segments.length, 0.0);
  }
  var totalMin = 0.0;
  for (final minHeight in minHeights) {
    totalMin += minHeight;
  }
  if (totalMin > height && totalMin > 0) {
    final scale = height / totalMin;
    return [for (final minHeight in minHeights) minHeight * scale];
  }
  final heights = List<double>.filled(segments.length, 0.0);
  final remaining = List<int>.generate(segments.length, (i) => i);
  var remainingHeight = height;
  var remainingUnits = unitsTotal;

  while (true) {
    var changed = false;
    for (var i = 0; i < remaining.length; i++) {
      final index = remaining[i];
      final segment = segments[index];
      final proportional =
          remainingHeight * (unitSpan(segment) / remainingUnits);
      if (proportional + 0.5 < minHeights[index]) {
        heights[index] = minHeights[index];
        remainingHeight -= heights[index];
        remainingUnits -= unitSpan(segment);
        remaining.removeAt(i);
        i -= 1;
        changed = true;
        if (remainingHeight <= 0 || remainingUnits <= 0) {
          break;
        }
      }
    }
    if (!changed || remainingHeight <= 0 || remainingUnits <= 0) {
      break;
    }
  }

  if (remainingHeight <= 0 || remainingUnits <= 0) {
    for (final index in remaining) {
      heights[index] = 0.0;
    }
    return heights;
  }

  for (final index in remaining) {
    final segment = segments[index];
    heights[index] = remainingHeight * (unitSpan(segment) / remainingUnits);
  }
  return heights;
}

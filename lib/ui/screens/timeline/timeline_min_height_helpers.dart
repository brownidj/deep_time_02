import 'package:flutter/widgets.dart';
import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/domain/models/geologic_division.dart';
import 'package:deep_time_2/domain/models/paleo_ecology_entry.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_min_height_helpers_calculations.dart';
export 'package:deep_time_2/ui/screens/timeline/timeline_min_height_helpers_paleo.dart';
export 'package:deep_time_2/ui/screens/timeline/timeline_min_height_helpers_calculations.dart';

class MinHeightMaps {
  const MinHeightMaps({
    required this.stageHeights,
    required this.epochHeights,
    required this.periodHeights,
    required this.eraHeights,
    required this.eonHeights,
  });

  final Map<int, double> stageHeights;
  final Map<int, double> epochHeights;
  final Map<int, double> periodHeights;
  final Map<int, double> eraHeights;
  final Map<int, double> eonHeights;
}

MinHeightMaps buildMinHeightMaps(
  TimelineLayoutSnapshot layout,
  TextStyle? stageStyle, {
  TextStyle? epochStyle,
  TextStyle? periodStyle,
  TextStyle? eraStyle,
  TextStyle? eonStyle,
  List<GeologicDivision> divisions = const [],
  List<PaleoEcologyEntry> paleoEcology = const [],
  double paleoWidth = 0,
  TextStyle? paleoStyle,
  double verticalPadding = 4,
}) {
  final stageHeights = buildStageMinHeights(
    layout.stageSegments,
    stageStyle,
    verticalPadding: verticalPadding,
    divisions: divisions,
    paleoEcology: paleoEcology,
    paleoWidth: paleoWidth,
    paleoStyle: paleoStyle,
  );
  final epochHeights = buildEpochHeights(
    layout.epochSegments,
    layout.stageSegments,
    stageHeights,
    epochStyle ?? stageStyle,
    verticalPadding: verticalPadding,
  );
  final periodHeights = buildPeriodHeights(
    layout.periodSegments,
    layout.epochSegments,
    epochHeights,
    periodStyle,
    verticalPadding: verticalPadding,
  );
  final eraHeights = buildEraHeights(
    layout.eraSegments,
    layout.periodSegments,
    periodHeights,
    eraStyle ?? periodStyle ?? stageStyle,
    verticalPadding: verticalPadding,
  );
  final eonHeights = buildEonHeights(
    layout.eonSegments,
    layout.eraSegments,
    eraHeights,
    eonStyle ?? eraStyle ?? periodStyle ?? stageStyle,
    verticalPadding: verticalPadding,
  );
  return MinHeightMaps(
    stageHeights: stageHeights,
    epochHeights: epochHeights,
    periodHeights: periodHeights,
    eraHeights: eraHeights,
    eonHeights: eonHeights,
  );
}

List<double> boundaryPositionsWithMinimums<T>(
  List<T> segments, {
  required double height,
  required double unitsTotal,
  required List<double> minHeights,
  required double Function(T segment) unitSpan,
}) {
  if (segments.isEmpty || unitsTotal <= 0 || height <= 0) {
    return const [];
  }
  final heights = _computeHeightsWithMinimums(
    segments,
    height: height,
    unitsTotal: unitsTotal,
    minHeights: minHeights,
    unitSpan: unitSpan,
  );
  final positions = <double>[];
  var cursor = 0.0;
  for (var i = 0; i < segments.length - 1; i++) {
    cursor += heights[i];
    positions.add(cursor);
  }
  return positions;
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

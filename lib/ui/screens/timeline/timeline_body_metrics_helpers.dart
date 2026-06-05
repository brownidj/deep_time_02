part of 'timeline_body_metrics.dart';

extension TimelineBodyMetricsGeometry on TimelineBodyMetrics {
  double unitSpanToHeight(double unitSpan, {double? unitsTotal}) {
    if (unitSpan <= 0) {
      return 0;
    }
    final total = unitsTotal ?? totalUnits;
    if (total <= 0 || scrollHeight <= 0) {
      return 0;
    }
    return scrollHeight * (unitSpan / total);
  }

  double unitPositionToY(double unitPosition, {double? unitsTotal}) {
    if (unitPosition <= 0) {
      return 0;
    }
    final total = unitsTotal ?? totalUnits;
    if (total <= 0 || scrollHeight <= 0) {
      return 0;
    }
    return scrollHeight * (unitPosition / total);
  }

  double trackX(TimelineTrack track) {
    return trackStartXs[track] ?? 0.0;
  }

  double trackWidth(TimelineTrack track) {
    return trackWidths[track] ?? defaultTrackWidth;
  }

  double gapBefore(TimelineTrack track) {
    return trackLeadingGaps[track] ?? 0.0;
  }

  double gapAfter(TimelineTrack track) {
    return trackTrailingGaps[track] ?? 0.0;
  }

  Rect columnRectForTrack(
    TimelineTrack track, {
    double top = 0.0,
    double? height,
  }) {
    final columnHeight = height ?? scrollHeight;
    return Rect.fromLTWH(trackX(track), top, trackWidth(track), columnHeight);
  }
}

List<double> _rowBoundaryPositionsForHeight(
  List<TimelineRowSegment> segments,
  double totalUnits,
  double scrollHeight,
) {
  if (segments.isEmpty || totalUnits <= 0 || scrollHeight <= 0) {
    return const [];
  }
  final positions = <double>[];
  var cursor = 0.0;
  for (var i = 0; i < segments.length - 1; i++) {
    cursor += segments[i].unitSpan;
    positions.add(scrollHeight * (cursor / totalUnits));
  }
  return positions;
}

List<double> _bandBoundaryPositionsForHeight(
  List<TimelineBandSegment> segments,
  double totalUnits,
  double scrollHeight,
) {
  if (segments.isEmpty || totalUnits <= 0 || scrollHeight <= 0) {
    return const [];
  }
  final positions = <double>[];
  var cursor = 0.0;
  for (var i = 0; i < segments.length - 1; i++) {
    cursor += segments[i].unitSpan;
    positions.add(scrollHeight * (cursor / totalUnits));
  }
  return positions;
}

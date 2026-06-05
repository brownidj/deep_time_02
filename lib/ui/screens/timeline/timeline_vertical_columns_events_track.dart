part of 'timeline_vertical_columns.dart';

const double _standardVerticalEventBarWidth = 24.0;

Widget _buildEventsTrack({
  required double width,
  required double height,
  required TimelineLayoutSnapshot layout,
  required TimelineBodyMetrics metrics,
  required DeepTimePalette palette,
}) {
  return _VerticalEventsColumn(
    width: width,
    height: height,
    events: layout.eventSegments,
    totalUnits: metrics.periodUnits,
    palette: palette,
    fixedLaneWidth: _standardVerticalEventBarWidth,
  );
}

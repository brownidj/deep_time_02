import 'package:deep_time_2/ui/screens/timeline/timeline_orientation.dart';

class TimelineVerticalColumnsLayout {
  const TimelineVerticalColumnsLayout({
    required this.useFixedHeights,
    required this.extinctionLineLeft,
    required this.eventLineLeft,
  });

  final bool useFixedHeights;
  final double extinctionLineLeft;
  final double eventLineLeft;
}

TimelineVerticalColumnsLayout buildVerticalColumnsLayout({
  required List<TimelineTrack> trackOrder,
  required double Function(TimelineTrack track) scaledWidth,
  required double Function(TimelineTrack track) trackWidth,
  required bool useFixedHeights,
}) {
  final trackStarts = <TimelineTrack, double>{};
  var trackCursor = 0.0;
  for (var i = 0; i < trackOrder.length; i += 1) {
    final track = trackOrder[i];
    final isFirst = i == 0;
    trackCursor += leadingGapForTrack(track, isFirstVisible: isFirst);
    trackStarts[track] = trackCursor;
    final isLast = track == trackOrder.last;
    trackCursor +=
        scaledWidth(track) + trailingGapForTrack(track, isLastVisible: isLast);
  }
  double trackRight(TimelineTrack track) =>
      (trackStarts[track] ?? 0.0) + scaledWidth(track);

  double previousTrackRight(TimelineTrack track) {
    final index = trackOrder.indexOf(track);
    if (index <= 0) {
      return trackStarts[track] ?? 0.0;
    }
    final previous = trackOrder[index - 1];
    return trackRight(previous);
  }

  final eraRight = trackRight(TimelineTrack.era);
  final extLeft = trackStarts[TimelineTrack.extinctions] ?? 0.0;
  final eventsLeft = trackStarts[TimelineTrack.events] ?? 0.0;
  final extinctionLineLeft =
      previousTrackRight(TimelineTrack.extinctions) - extLeft;
  final eventLineLeft = eraRight - eventsLeft;
  return TimelineVerticalColumnsLayout(
    useFixedHeights: useFixedHeights,
    extinctionLineLeft: extinctionLineLeft,
    eventLineLeft: eventLineLeft,
  );
}

import 'dart:math' as math;

import 'package:deep_time_2/ui/screens/timeline/timeline_body_metrics.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_orientation.dart';

const Set<TimelineTrack> kFixedTimelineTracks = {
  TimelineTrack.ma,
  TimelineTrack.eon,
  TimelineTrack.era,
  TimelineTrack.period,
  TimelineTrack.epoch,
  TimelineTrack.stage,
  TimelineTrack.paleoEcology,
  TimelineTrack.rlife,
  TimelineTrack.extinctions,
  TimelineTrack.continents,
  TimelineTrack.waterways,
  TimelineTrack.events,
};

Map<TimelineTrack, double> resolveTimelineTrackWidths({
  required TimelineBodyMetrics metrics,
  required double maxWidth,
  TimelineTrack? expandedTrack,
}) {
  if (!maxWidth.isFinite || maxWidth <= 0 || metrics.trackColumnsWidth <= 0) {
    return {
      for (final track in metrics.trackOrder) track: metrics.trackWidth(track),
    };
  }

  var fixedWidth = 0.0;
  var flexibleBaseWidth = 0.0;
  var gapWidth = 0.0;
  var totalBaseTrackWidth = 0.0;
  for (final track in metrics.trackOrder) {
    final trackBaseWidth = metrics.trackWidth(track);
    final trackGapWidth = metrics.gapBefore(track) + metrics.gapAfter(track);
    gapWidth += trackGapWidth;
    totalBaseTrackWidth += trackBaseWidth;
    fixedWidth += trackGapWidth;
    if (kFixedTimelineTracks.contains(track)) {
      fixedWidth += trackBaseWidth;
      continue;
    }
    flexibleBaseWidth += trackBaseWidth;
  }

  if (gapWidth + totalBaseTrackWidth > maxWidth) {
    final availableTrackWidth = math.max(0.0, maxWidth - gapWidth);
    final shrinkScale = totalBaseTrackWidth <= 0
        ? 1.0
        : availableTrackWidth / totalBaseTrackWidth;
    return {
      for (final track in metrics.trackOrder)
        track: metrics.trackWidth(track) * shrinkScale,
    };
  }

  final remainingForFlexible = math.max(0.0, maxWidth - fixedWidth);
  final expandedIsFlexible =
      expandedTrack != null &&
      metrics.trackOrder.contains(expandedTrack) &&
      !kFixedTimelineTracks.contains(expandedTrack);

  if (expandedIsFlexible) {
    return {
      for (final track in metrics.trackOrder)
        track: kFixedTimelineTracks.contains(track)
            ? metrics.trackWidth(track)
            : track == expandedTrack
            ? remainingForFlexible
            : metrics.trackWidth(track),
    };
  }

  final flexibleScale = flexibleBaseWidth <= 0
      ? 1.0
      : remainingForFlexible / flexibleBaseWidth;

  return {
    for (final track in metrics.trackOrder)
      track: kFixedTimelineTracks.contains(track)
          ? metrics.trackWidth(track)
          : metrics.trackWidth(track) * flexibleScale,
  };
}

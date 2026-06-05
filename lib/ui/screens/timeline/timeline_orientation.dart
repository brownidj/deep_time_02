import 'package:flutter/foundation.dart';

enum TimelineTrack {
  ma,
  eon,
  era,
  period,
  epoch,
  stage,
  paleoEcology,
  rlife,
  extinctions,
  continents,
  waterways,
  events,
  clades,
}

const List<TimelineTrack> kDefaultTimelineTrackOrder = <TimelineTrack>[
  TimelineTrack.ma,
  TimelineTrack.eon,
  TimelineTrack.era,
  TimelineTrack.period,
  TimelineTrack.epoch,
  TimelineTrack.stage,
  TimelineTrack.continents,
  TimelineTrack.waterways,
  TimelineTrack.paleoEcology,
  TimelineTrack.rlife,
  TimelineTrack.extinctions,
  TimelineTrack.events,
  TimelineTrack.clades,
];

const double kTimelineStandardInterColumnGap = 10.0;

double leadingGapForTrack(TimelineTrack track, {required bool isFirstVisible}) {
  if (isFirstVisible) {
    return 0.0;
  }
  switch (track) {
    case TimelineTrack.continents:
    case TimelineTrack.waterways:
    case TimelineTrack.paleoEcology:
    case TimelineTrack.rlife:
      return kTimelineStandardInterColumnGap;
    case TimelineTrack.ma:
    case TimelineTrack.eon:
    case TimelineTrack.era:
    case TimelineTrack.period:
    case TimelineTrack.epoch:
    case TimelineTrack.stage:
    case TimelineTrack.extinctions:
    case TimelineTrack.events:
    case TimelineTrack.clades:
      return 0.0;
  }
}

double trailingGapForTrack(TimelineTrack track, {required bool isLastVisible}) {
  if (isLastVisible) {
    return 0.0;
  }
  return 0.0;
}

@immutable
class TimelineOrientationConfig {
  const TimelineOrientationConfig({
    this.trackWidths = const <TimelineTrack, double>{},
    this.defaultTrackWidth = 112.0,
    this.verticalHeaderHeight = 44.0,
    this.minUnitHeight = 96.0,
  });

  final Map<TimelineTrack, double> trackWidths;
  final double defaultTrackWidth;
  final double verticalHeaderHeight;
  final double minUnitHeight;

  double trackWidthFor(TimelineTrack track) {
    return trackWidths[track] ?? defaultTrackWidth;
  }
}

const TimelineOrientationConfig kDefaultTimelineOrientation =
    TimelineOrientationConfig();

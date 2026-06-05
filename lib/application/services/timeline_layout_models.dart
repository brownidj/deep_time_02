import 'package:deep_time_2/domain/models/geologic_division.dart';
import 'package:deep_time_2/domain/models/geologic_rank.dart';

class TimelineBandSegment {
  const TimelineBandSegment({
    required this.id,
    required this.label,
    required this.rank,
    required this.startMa,
    required this.endMa,
    required this.colorKey,
    required this.isGap,
    required this.unitSpan,
    this.explanation,
  });

  final int id;
  final String label;
  final GeologicRank rank;
  final double startMa;
  final double endMa;
  final String colorKey;
  final bool isGap;
  final double unitSpan;
  final String? explanation;

  double get durationMa => startMa - endMa;
}

class TimelineRowSegment {
  const TimelineRowSegment({
    required this.id,
    required this.label,
    required this.rank,
    required this.startMa,
    required this.endMa,
    required this.colorKey,
    required this.isGap,
    required this.unitSpan,
    this.secondaryLabel,
    this.explanation,
  });

  final int id;
  final String label;
  final GeologicRank rank;
  final double startMa;
  final double endMa;
  final String colorKey;
  final bool isGap;
  final double unitSpan;
  final String? secondaryLabel;
  final String? explanation;

  double get durationMa => startMa - endMa;
}

enum TimelineEventType { point, bar }

class TimelineEventSegment {
  const TimelineEventSegment({
    this.id,
    required this.label,
    required this.shortLabel,
    required this.type,
    this.explanation,
    this.image,
    this.sourcePage,
    this.imageLicense,
    this.imageLicenseUrl,
    this.imageAuthor,
    this.imageCredit,
    this.localAssetImage,
    required this.startMa,
    required this.endMa,
    required this.startUnit,
    required this.endUnit,
    required this.colorKey,
  });

  final String? id;
  final String label;
  final String shortLabel;
  final TimelineEventType type;
  final String? explanation;
  final String? image;
  final String? sourcePage;
  final String? imageLicense;
  final String? imageLicenseUrl;
  final String? imageAuthor;
  final String? imageCredit;
  final String? localAssetImage;
  final double startMa;
  final double endMa;
  final double startUnit;
  final double endUnit;
  final String colorKey;
}

class TimelineLayoutSnapshot {
  const TimelineLayoutSnapshot({
    required this.divisions,
    required this.eonSegments,
    required this.eraSegments,
    required this.periodSegments,
    required this.epochSegments,
    required this.stageSegments,
    required this.rlifeSegments,
    required this.eventSegments,
    required this.continentSegments,
    this.waterwaySegments = const [],
    required this.oldestMa,
    required this.youngestMa,
    this.fixedHeight,
  });

  final List<GeologicDivision> divisions;
  final List<TimelineBandSegment> eonSegments;
  final List<TimelineBandSegment> eraSegments;
  final List<TimelineRowSegment> periodSegments;
  final List<TimelineRowSegment> epochSegments;
  final List<TimelineRowSegment> stageSegments;
  final List<TimelineRowSegment> rlifeSegments;
  final List<TimelineEventSegment> eventSegments;
  final List<TimelineEventSegment> continentSegments;
  final List<TimelineEventSegment> waterwaySegments;
  final double oldestMa;
  final double youngestMa;
  final double? fixedHeight;

  TimelineRowSegments get rowSegments => TimelineRowSegments(
    periods: periodSegments,
    epochs: epochSegments,
    stages: stageSegments,
  );
}

class TimelineRowSegments {
  const TimelineRowSegments({
    required this.periods,
    required this.epochs,
    required this.stages,
  });

  final List<TimelineRowSegment> periods;
  final List<TimelineRowSegment> epochs;
  final List<TimelineRowSegment> stages;

  List<TimelineRowSegment> forRank(GeologicRank rank) {
    switch (rank) {
      case GeologicRank.period:
        return periods;
      case GeologicRank.epoch:
        return epochs;
      case GeologicRank.stage:
        return stages;
      case GeologicRank.eon:
      case GeologicRank.era:
      case GeologicRank.age:
        return const [];
    }
  }

  List<TimelineRowSegment> operator [](GeologicRank rank) => forRank(rank);
}

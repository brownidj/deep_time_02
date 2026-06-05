import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/domain/models/geologic_rank.dart';

TimelineLayoutSnapshot layoutWithLongStage() {
  return const TimelineLayoutSnapshot(
    divisions: [],
    eonSegments: [
      TimelineBandSegment(
        id: 1,
        label: 'TestEon',
        rank: GeologicRank.eon,
        startMa: 260,
        endMa: 0,
        colorKey: 'eon|test',
        isGap: false,
        unitSpan: 1,
      ),
    ],
    eraSegments: [
      TimelineBandSegment(
        id: 2,
        label: 'TestEra',
        rank: GeologicRank.era,
        startMa: 260,
        endMa: 0,
        colorKey: 'era|test',
        isGap: false,
        unitSpan: 1,
      ),
    ],
    periodSegments: [
      TimelineRowSegment(
        id: 3,
        label: 'TestPeriod',
        rank: GeologicRank.period,
        startMa: 260,
        endMa: 0,
        colorKey: 'period|test',
        isGap: false,
        unitSpan: 1,
      ),
    ],
    epochSegments: [
      TimelineRowSegment(
        id: 4,
        label: 'TestEpoch',
        rank: GeologicRank.epoch,
        startMa: 260,
        endMa: 0,
        colorKey: 'epoch|test',
        isGap: false,
        unitSpan: 1,
      ),
    ],
    stageSegments: [
      TimelineRowSegment(
        id: 5,
        label: 'Wuchiapingian',
        rank: GeologicRank.stage,
        startMa: 260,
        endMa: 0,
        colorKey: 'stage|test',
        isGap: false,
        unitSpan: 1,
      ),
    ],
    rlifeSegments: [],
    eventSegments: [],
    continentSegments: [],
    oldestMa: 260,
    youngestMa: 0,
  );
}

TimelineLayoutSnapshot precambrianPeriodLayout() {
  return const TimelineLayoutSnapshot(
    divisions: [],
    eonSegments: [
      TimelineBandSegment(
        id: 10,
        label: 'TestEon',
        rank: GeologicRank.eon,
        startMa: 635,
        endMa: 0,
        colorKey: 'eon|test',
        isGap: false,
        unitSpan: 1,
      ),
    ],
    eraSegments: [
      TimelineBandSegment(
        id: 11,
        label: 'TestEra',
        rank: GeologicRank.era,
        startMa: 635,
        endMa: 0,
        colorKey: 'era|test',
        isGap: false,
        unitSpan: 1,
      ),
    ],
    periodSegments: [
      TimelineRowSegment(
        id: 12,
        label: 'Ediacaran',
        rank: GeologicRank.period,
        startMa: 635,
        endMa: 0,
        colorKey: 'period|test',
        isGap: false,
        unitSpan: 1,
      ),
    ],
    epochSegments: [],
    stageSegments: [],
    rlifeSegments: [],
    eventSegments: [],
    continentSegments: [],
    oldestMa: 635,
    youngestMa: 0,
  );
}

double? findNearestSizedBoxHeight(WidgetTester tester, Finder textFinder) {
  final sizedBoxes = find.ancestor(
    of: textFinder,
    matching: find.byType(SizedBox),
  );
  for (final element in sizedBoxes.evaluate()) {
    final widget = element.widget;
    if (widget is SizedBox && widget.height != null) {
      return widget.height;
    }
  }
  return null;
}

double? findNearestSizedBoxWidth(WidgetTester tester, Finder textFinder) {
  final sizedBoxes = find.ancestor(
    of: textFinder,
    matching: find.byType(SizedBox),
  );
  for (final element in sizedBoxes.evaluate()) {
    final widget = element.widget;
    if (widget is SizedBox && widget.width != null) {
      return widget.width;
    }
  }
  return null;
}

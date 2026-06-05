import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/domain/models/geologic_rank.dart';
import 'package:deep_time_2/domain/models/timeline_palette.dart';
import 'package:deep_time_2/ui/theme/deep_time_palette.dart';

DeepTimePalette testPalette() {
  return DeepTimePalette(
    const TimelinePalette(
      divisionColors: {
        'eon|test': 0xFF111111,
        'era|test': 0xFF222222,
        'period|test': 0xFF333333,
        'period|test2': 0xFF334444,
        'epoch|test': 0xFF444444,
        'stage|test': 0xFF555555,
        'rlife|test': 0xFF666666,
      },
    ),
  );
}

TimelineLayoutSnapshot singleSpanLayout({
  List<TimelineEventSegment> eventSegments = const [],
}) {
  return TimelineLayoutSnapshot(
    divisions: const [],
    eonSegments: const [
      TimelineBandSegment(
        id: 1,
        label: 'TestEon',
        rank: GeologicRank.eon,
        startMa: 100,
        endMa: 0,
        colorKey: 'eon|test',
        isGap: false,
        unitSpan: 1,
      ),
    ],
    eraSegments: const [
      TimelineBandSegment(
        id: 2,
        label: 'TestEra',
        rank: GeologicRank.era,
        startMa: 100,
        endMa: 0,
        colorKey: 'era|test',
        isGap: false,
        unitSpan: 1,
      ),
    ],
    periodSegments: const [
      TimelineRowSegment(
        id: 3,
        label: 'TestPeriod',
        rank: GeologicRank.period,
        startMa: 100,
        endMa: 0,
        colorKey: 'period|test',
        isGap: false,
        unitSpan: 1,
      ),
    ],
    epochSegments: const [
      TimelineRowSegment(
        id: 4,
        label: 'TestEpoch',
        rank: GeologicRank.epoch,
        startMa: 100,
        endMa: 0,
        colorKey: 'epoch|test',
        isGap: false,
        unitSpan: 1,
      ),
    ],
    stageSegments: const [
      TimelineRowSegment(
        id: 5,
        label: 'TestStage',
        rank: GeologicRank.stage,
        startMa: 100,
        endMa: 0,
        colorKey: 'stage|test',
        isGap: false,
        unitSpan: 1,
      ),
    ],
    rlifeSegments: const [
      TimelineRowSegment(
        id: 6,
        label: 'TestRLife',
        rank: GeologicRank.period,
        startMa: 100,
        endMa: 0,
        colorKey: 'rlife|test',
        isGap: false,
        unitSpan: 1,
      ),
    ],
    eventSegments: eventSegments,
    continentSegments: const [],
    oldestMa: 100,
    youngestMa: 0,
  );
}

TimelineLayoutSnapshot splitPeriodLayout() {
  return TimelineLayoutSnapshot(
    divisions: const [],
    eonSegments: const [
      TimelineBandSegment(
        id: 1,
        label: 'TestEon',
        rank: GeologicRank.eon,
        startMa: 100,
        endMa: 0,
        colorKey: 'eon|test',
        isGap: false,
        unitSpan: 2,
      ),
    ],
    eraSegments: const [
      TimelineBandSegment(
        id: 2,
        label: 'TestEra',
        rank: GeologicRank.era,
        startMa: 100,
        endMa: 0,
        colorKey: 'era|test',
        isGap: false,
        unitSpan: 2,
      ),
    ],
    periodSegments: const [
      TimelineRowSegment(
        id: 3,
        label: 'OlderPeriod',
        rank: GeologicRank.period,
        startMa: 100,
        endMa: 50,
        colorKey: 'period|test',
        isGap: false,
        unitSpan: 1,
      ),
      TimelineRowSegment(
        id: 4,
        label: 'YoungerPeriod',
        rank: GeologicRank.period,
        startMa: 50,
        endMa: 0,
        colorKey: 'period|test2',
        isGap: false,
        unitSpan: 1,
      ),
    ],
    epochSegments: const [
      TimelineRowSegment(
        id: 5,
        label: 'TestEpoch',
        rank: GeologicRank.epoch,
        startMa: 100,
        endMa: 0,
        colorKey: 'epoch|test',
        isGap: false,
        unitSpan: 2,
      ),
    ],
    stageSegments: const [
      TimelineRowSegment(
        id: 6,
        label: 'TestStage',
        rank: GeologicRank.stage,
        startMa: 100,
        endMa: 0,
        colorKey: 'stage|test',
        isGap: false,
        unitSpan: 2,
      ),
    ],
    rlifeSegments: const [
      TimelineRowSegment(
        id: 7,
        label: 'TestRLife',
        rank: GeologicRank.period,
        startMa: 100,
        endMa: 0,
        colorKey: 'rlife|test',
        isGap: false,
        unitSpan: 2,
      ),
    ],
    eventSegments: const [],
    continentSegments: const [],
    oldestMa: 100,
    youngestMa: 0,
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/domain/models/clade.dart';
import 'package:deep_time_2/domain/models/geologic_rank.dart';
import 'package:deep_time_2/domain/models/timeline_marker_catalog.dart';
import 'package:deep_time_2/ui/models/clade_label_mode.dart';
import 'package:deep_time_2/ui/models/clade_view_mode.dart';
import 'package:deep_time_2/ui/models/time_label_mode.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_body.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_orientation.dart';

import 'timeline_row_alignment_helpers.dart';

Future<void> pumpFocusedCladeTestBody(
  WidgetTester tester, {
  required TimelineLayoutSnapshot layout,
  required List<Clade> clades,
  required Map<String, List<Clade>> childrenByParentId,
  required String activeCladeRootId,
  required String activeCladeRootLabel,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 2000,
          height: 1200,
          child: Column(
            children: [
              TimelineBody(
                layout: layout,
                palette: testPalette(),
                markers: const TimelineMarkerCatalog(events: [], extinctions: []),
                labelMode: TimeLabelMode.geologicTime,
                scrollController: ScrollController(),
                selectedId: null,
                onBandSelect: (_) {},
                onSelect: (_) {},
                clades: clades,
                cladeViewMode: CladeViewMode.byCategory,
                cladeCategoryId: 'all',
                cladeLabelMode: CladeLabelMode.common,
                cladeRepresentativeIds: const [],
                cladeSearchQuery: '',
                cladeSpotlightId: null,
                activeCladeRootId: activeCladeRootId,
                activeCladeRootLabel: activeCladeRootLabel,
                childrenByParentId: childrenByParentId,
                onCladeSpotlight: (_) {},
                visibleTracks: {...kDefaultTimelineTrackOrder}
                  ..remove(TimelineTrack.paleoEcology),
                paleoEcology: const [],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

TimelineLayoutSnapshot focusedPinnedStripLayout() {
  return TimelineLayoutSnapshot(
    divisions: const [],
    eonSegments: const [
      TimelineBandSegment(
        id: 1,
        label: 'Hadean',
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
    eventSegments: const [],
    continentSegments: const [],
    oldestMa: 100,
    youngestMa: 0,
  );
}

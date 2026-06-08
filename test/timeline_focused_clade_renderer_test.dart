import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/domain/models/clade.dart';
import 'package:deep_time_2/domain/models/clade_zoom_level.dart';
import 'package:deep_time_2/domain/models/geologic_rank.dart';
import 'package:deep_time_2/domain/models/timeline_marker_catalog.dart';
import 'package:deep_time_2/ui/models/clade_label_mode.dart';
import 'package:deep_time_2/ui/models/clade_view_mode.dart';
import 'package:deep_time_2/ui/models/time_label_mode.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_body.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_orientation.dart';

import 'timeline_row_alignment_helpers.dart';

void main() {
  testWidgets('Focused renderer gives same-depth clades distinct lanes', (
    tester,
  ) async {
    await setLargeSurface(tester);
    final palette = testPalette();
    final layout = splitPeriodLayout();
    const markers = TimelineMarkerCatalog(events: [], extinctions: []);
    const clades = [
      Clade(
        id: 'dinosauria',
        label: 'Dinosauria',
        scientificRank: 'clade',
        startMa: 95,
        endMa: 0,
        displayGroups: ['all'],
        displayPriority: 0,
        minZoomLevel: CladeZoomLevel.whole,
        zoomable: true,
      ),
      Clade(
        id: 'ornithischia',
        label: 'Ornithischia',
        scientificRank: 'clade',
        parentId: 'dinosauria',
        startMa: 85,
        endMa: 0,
        displayGroups: ['all'],
        displayPriority: 1,
        minZoomLevel: CladeZoomLevel.whole,
        zoomable: true,
      ),
      Clade(
        id: 'saurischia',
        label: 'Saurischia',
        scientificRank: 'clade',
        parentId: 'dinosauria',
        startMa: 82,
        endMa: 0,
        displayGroups: ['all'],
        displayPriority: 2,
        minZoomLevel: CladeZoomLevel.whole,
        zoomable: true,
      ),
      Clade(
        id: 'theropoda',
        label: 'Theropoda',
        scientificRank: 'clade',
        parentId: 'saurischia',
        startMa: 70,
        endMa: 0,
        displayGroups: ['all'],
        displayPriority: 3,
        minZoomLevel: CladeZoomLevel.whole,
      ),
      Clade(
        id: 'ornithopoda',
        label: 'Ornithopoda',
        scientificRank: 'clade',
        parentId: 'ornithischia',
        startMa: 68,
        endMa: 0,
        displayGroups: ['all'],
        displayPriority: 4,
        minZoomLevel: CladeZoomLevel.whole,
      ),
    ];
    final childrenByParentId = <String, List<Clade>>{
      'dinosauria': [clades[1], clades[2]],
      'ornithischia': [clades[4]],
      'saurischia': [clades[3]],
    };

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
                  palette: palette,
                  markers: markers,
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
                  activeCladeRootId: 'dinosauria',
                  activeCladeRootLabel: 'Dinosauria',
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

    final ornithischiaFinder = find.byKey(
      const ValueKey('focused-clade-label-ornithischia'),
    );
    final saurischiaFinder = find.byKey(
      const ValueKey('focused-clade-label-saurischia'),
    );
    expect(ornithischiaFinder, findsOneWidget);
    expect(saurischiaFinder, findsOneWidget);

    final ornithischiaDx = tester.getTopLeft(ornithischiaFinder).dx;
    final saurischiaDx = tester.getTopLeft(saurischiaFinder).dx;
    expect((ornithischiaDx - saurischiaDx).abs(), greaterThan(20.0));
  });

  testWidgets(
    'Focused renderer suppresses inline label when pinned strip label is visible',
    (tester) async {
      await setLargeSurface(tester);
      final palette = testPalette();
      final layout = _focusedPinnedStripLayout();
      const markers = TimelineMarkerCatalog(events: [], extinctions: []);
      const clades = [
        Clade(
          id: 'root_clade',
          label: 'Root Clade',
          scientificRank: 'clade',
          startMa: 100,
          endMa: 0,
          displayGroups: ['all'],
          displayPriority: 0,
          minZoomLevel: CladeZoomLevel.whole,
          zoomable: true,
        ),
        Clade(
          id: 'child_clade',
          label: 'Child Clade',
          scientificRank: 'clade',
          parentId: 'root_clade',
          startMa: 80,
          endMa: 0,
          displayGroups: ['all'],
          displayPriority: 1,
          minZoomLevel: CladeZoomLevel.whole,
        ),
      ];
      final childrenByParentId = <String, List<Clade>>{
        'root_clade': [clades[1]],
      };

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
                    palette: palette,
                    markers: markers,
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
                    activeCladeRootId: 'root_clade',
                    activeCladeRootLabel: 'Root Clade',
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

      expect(
        find.byKey(const ValueKey('focused-clade-label-root_clade')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('clade-top-strip')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('clade-top-strip-label-root_clade')),
        findsOneWidget,
      );
    },
  );
}

TimelineLayoutSnapshot _focusedPinnedStripLayout() {
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

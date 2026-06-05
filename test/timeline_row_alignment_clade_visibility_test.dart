import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deep_time_2/domain/models/clade.dart';
import 'package:deep_time_2/domain/models/clade_zoom_level.dart';
import 'package:deep_time_2/domain/models/timeline_marker_catalog.dart';
import 'package:deep_time_2/ui/models/clade_view_mode.dart';
import 'package:deep_time_2/ui/models/time_label_mode.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_body.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_orientation.dart';

import 'timeline_row_alignment_helpers.dart';

void main() {
  testWidgets('Representative clade view includes LUCA ancestor', (
    tester,
  ) async {
    await _setLargeSurface(tester);
    final palette = testPalette();
    final layout = splitPeriodLayout();
    const markers = TimelineMarkerCatalog(events: [], extinctions: []);
    const clades = [
      Clade(
        id: 'luca',
        label: 'LUCA',
        scientificRank: 'test',
        startMa: 100,
        endMa: 0,
        displayGroups: ['all'],
        displayPriority: 0,
        minZoomLevel: CladeZoomLevel.whole,
      ),
      Clade(
        id: 'child_clade',
        label: 'Child Clade',
        scientificRank: 'test',
        parentId: 'luca',
        startMa: 50,
        endMa: 0,
        displayGroups: ['all'],
        displayPriority: 1,
        minZoomLevel: CladeZoomLevel.epoch,
      ),
    ];

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
                  cladeViewMode: CladeViewMode.representativeOnly,
                  cladeCategoryId: 'all',
                  cladeRepresentativeIds: const ['child_clade'],
                  cladeSearchQuery: '',
                  cladeSpotlightId: null,
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

    expect(find.byKey(const ValueKey('vertical-clade-luca')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('vertical-clade-child_clade')),
      findsOneWidget,
    );
  });

  testWidgets('Sibling clades use separate horizontal lanes', (tester) async {
    await _setLargeSurface(tester);
    final palette = testPalette();
    final layout = splitPeriodLayout();
    const markers = TimelineMarkerCatalog(events: [], extinctions: []);
    const clades = [
      Clade(
        id: 'parent_clade',
        label: 'Parent Clade',
        scientificRank: 'test',
        startMa: 100,
        endMa: 0,
        displayGroups: ['all'],
        displayPriority: 0,
        minZoomLevel: CladeZoomLevel.whole,
      ),
      Clade(
        id: 'sibling_a',
        label: 'Sibling A',
        scientificRank: 'test',
        parentId: 'parent_clade',
        startMa: 50,
        endMa: 0,
        displayGroups: ['all'],
        displayPriority: 1,
        minZoomLevel: CladeZoomLevel.epoch,
      ),
      Clade(
        id: 'sibling_b',
        label: 'Sibling B',
        scientificRank: 'test',
        parentId: 'parent_clade',
        startMa: 50,
        endMa: 0,
        displayGroups: ['all'],
        displayPriority: 2,
        minZoomLevel: CladeZoomLevel.epoch,
      ),
    ];

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
                  cladeViewMode: CladeViewMode.representativeOnly,
                  cladeCategoryId: 'all',
                  cladeRepresentativeIds: const ['sibling_a', 'sibling_b'],
                  cladeSearchQuery: '',
                  cladeSpotlightId: null,
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

    final siblingA = tester.getRect(
      find.byKey(const ValueKey('vertical-clade-sibling_a')),
    );
    final siblingB = tester.getRect(
      find.byKey(const ValueKey('vertical-clade-sibling_b')),
    );

    expect((siblingA.left - siblingB.left).abs(), greaterThan(8.0));
  });

  testWidgets('Clade column shows top strip and narrow scrollbar', (
    tester,
  ) async {
    await _setLargeSurface(tester);
    final palette = testPalette();
    final layout = splitPeriodLayout();
    const markers = TimelineMarkerCatalog(events: [], extinctions: []);
    const clades = [
      Clade(
        id: 'luca',
        label: 'LUCA',
        scientificRank: 'test',
        startMa: 80,
        endMa: 0,
        displayGroups: ['all'],
        displayPriority: 0,
        minZoomLevel: CladeZoomLevel.whole,
      ),
      Clade(
        id: 'bacteria',
        label: 'Bacteria',
        scientificRank: 'test',
        parentId: 'luca',
        startMa: 60,
        endMa: 0,
        displayGroups: ['all'],
        displayPriority: 1,
        minZoomLevel: CladeZoomLevel.whole,
      ),
    ];

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
                  cladeViewMode: CladeViewMode.representativeOnly,
                  cladeCategoryId: 'all',
                  cladeRepresentativeIds: const [],
                  cladeSearchQuery: '',
                  cladeSpotlightId: null,
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

    expect(find.byKey(const ValueKey('clade-top-strip')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('clade-top-strip-label-luca')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('clade-scrollbar')), findsOneWidget);
  });
}

Future<void> _setLargeSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(2000, 1200));
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
}

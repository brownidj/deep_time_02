import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deep_time_2/domain/models/clade.dart';
import 'package:deep_time_2/domain/models/clade_zoom_level.dart';
import 'package:deep_time_2/domain/models/timeline_marker_catalog.dart';
import 'package:deep_time_2/ui/models/clade_label_mode.dart';
import 'package:deep_time_2/ui/models/clade_view_mode.dart';
import 'package:deep_time_2/ui/models/time_label_mode.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_body.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_column_headers.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_orientation.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_vertical_columns.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_vertical_overlays.dart';

import 'timeline_row_alignment_helpers.dart';

void main() {
  testWidgets('Timeline shows top column headers and vertical columns', (
    tester,
  ) async {
    await setLargeSurface(tester);
    final palette = testPalette();
    final layout = singleSpanLayout();
    const markers = TimelineMarkerCatalog(events: [], extinctions: []);

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
                  clades: const [],
                  cladeViewMode: CladeViewMode.representativeOnly,
                  cladeLabelMode: CladeLabelMode.common,
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

    expect(find.byType(TimelineColumnHeaders), findsOneWidget);
    expect(find.byType(TimelineVerticalColumns), findsOneWidget);
    expect(find.byType(TimelineVerticalOverlays), findsOneWidget);
    expect(find.text('Eon'), findsOneWidget);
    expect(find.text('Clades'), findsOneWidget);

    final headerTop = tester.getTopLeft(find.byType(TimelineColumnHeaders)).dy;
    final timelineTop = tester
        .getTopLeft(find.byType(TimelineVerticalColumns))
        .dy;
    expect(headerTop, lessThan(timelineTop));
  });

  testWidgets('Vertical mode renders clade bars and taps spotlight callback', (
    tester,
  ) async {
    await setLargeSurface(tester);
    final palette = testPalette();
    final layout = splitPeriodLayout();
    const markers = TimelineMarkerCatalog(events: [], extinctions: []);
    const clades = [
      Clade(
        id: 'vertical_test_clade',
        label: 'Vertical Test Clade',
        scientificRank: 'test',
        startMa: 95,
        endMa: 5,
        displayGroups: ['all'],
        displayPriority: 0,
        minZoomLevel: CladeZoomLevel.whole,
      ),
    ];

    String? tappedId;
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
                  cladeLabelMode: CladeLabelMode.common,
                  cladeCategoryId: 'all',
                  cladeRepresentativeIds: const [],
                  cladeSearchQuery: '',
                  cladeSpotlightId: null,
                  onCladeSpotlight: (clade) => tappedId = clade.id,
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

    expect(tester.takeException(), isNull);
    final barFinder = find.byKey(
      const ValueKey('vertical-clade-vertical_test_clade'),
    );
    expect(barFinder, findsOneWidget);

    await tester.ensureVisible(barFinder);
    await tester.pumpAndSettle();
    final tapPoint = tester.getTopLeft(barFinder) + const Offset(4, 4);
    await tester.tapAt(tapPoint);
    await tester.pumpAndSettle();
    expect(tappedId, 'vertical_test_clade');
  });

  testWidgets('Clades header shows active root context', (tester) async {
    await setLargeSurface(tester);
    final palette = testPalette();
    final layout = splitPeriodLayout();
    const markers = TimelineMarkerCatalog(events: [], extinctions: []);
    const clades = [
      Clade(
        id: 'dinosauria',
        label: 'Dinosauria',
        scientificRank: 'clade',
        startMa: 231,
        endMa: 0,
        displayGroups: ['all'],
        displayPriority: 0,
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
                  cladeViewMode: CladeViewMode.byCategory,
                  cladeLabelMode: CladeLabelMode.common,
                  cladeCategoryId: 'all',
                  cladeRepresentativeIds: const [],
                  cladeSearchQuery: '',
                  cladeSpotlightId: null,
                  activeCladeRootId: 'dinosauria',
                  activeCladeRootLabel: 'Dinosauria',
                  childrenByParentId: const {},
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
    expect(find.text('Clades: Dinosauria'), findsOneWidget);
  });
}

Future<void> setLargeSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(2000, 1200));
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
}

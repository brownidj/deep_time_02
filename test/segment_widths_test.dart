import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deep_time_2/domain/models/timeline_marker_catalog.dart';
import 'package:deep_time_2/ui/models/clade_view_mode.dart';
import 'package:deep_time_2/ui/models/time_label_mode.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_body.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_orientation.dart';

import 'timeline_layout_test_helpers.dart';
import 'timeline_row_alignment_helpers.dart';

void main() {
  testWidgets('Stage column width fits longest stage label', (tester) async {
    await _setLargeSurface(tester);
    final layout = layoutWithLongStage();
    final palette = testPalette();
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
                  cladeCategoryId: 'all',
                  cladeRepresentativeIds: const [],
                  cladeSearchQuery: '',
                  cladeSpotlightId: null,
                  onCladeSpotlight: (_) {},
                  visibleTracks: Set<TimelineTrack>.from(
                    kDefaultTimelineTrackOrder,
                  ),
                  paleoEcology: const [],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    const longLabel = 'Wuchiapingian';
    final stageFinder = find.text(longLabel);
    expect(stageFinder, findsOneWidget);

    final stageText = tester.widget<Text>(stageFinder);
    final stageStyle = stageText.style;
    expect(stageStyle, isNotNull);

    final painter = TextPainter(
      text: TextSpan(text: longLabel, style: stageStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final requiredWidth = painter.width + 12;

    final tileWidth = findNearestSizedBoxWidth(tester, stageFinder);
    expect(tileWidth, isNotNull);
    expect(tileWidth! + 0.1, greaterThanOrEqualTo(requiredWidth));
  });

  testWidgets('Pre-Cambrian periods without epochs use label-length height', (
    tester,
  ) async {
    await _setLargeSurface(tester);
    final layout = precambrianPeriodLayout();
    final palette = testPalette();
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
                  cladeCategoryId: 'all',
                  cladeRepresentativeIds: const [],
                  cladeSearchQuery: '',
                  cladeSpotlightId: null,
                  onCladeSpotlight: (_) {},
                  visibleTracks: Set<TimelineTrack>.from(
                    kDefaultTimelineTrackOrder,
                  ),
                  paleoEcology: const [],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    const periodLabel = 'Ediacaran';
    final periodFinder = find.text(periodLabel);
    expect(periodFinder, findsOneWidget);

    final periodText = tester.widget<Text>(periodFinder);
    final periodStyle = periodText.style;
    expect(periodStyle, isNotNull);

    final painter = TextPainter(
      text: TextSpan(text: periodLabel, style: periodStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final requiredHeight = painter.width + 8;

    final tileHeight = findNearestSizedBoxHeight(tester, periodFinder);
    expect(tileHeight, isNotNull);
    expect(tileHeight! + 0.1, greaterThanOrEqualTo(requiredHeight));
  });
}

Future<void> _setLargeSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(2000, 1200));
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
}

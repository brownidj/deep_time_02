import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/domain/models/geologic_rank.dart';
import 'package:deep_time_2/domain/models/timeline_marker_catalog.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_extinction_markers.dart';

void main() {
  testWidgets('Major extinction marker tip aligns with era-period boundary', (
    tester,
  ) async {
    const periodSegments = [
      TimelineRowSegment(
        id: 1,
        label: 'Carboniferous',
        rank: GeologicRank.period,
        startMa: 299,
        endMa: 252,
        colorKey: '',
        isGap: false,
        unitSpan: 1,
        secondaryLabel: null,
      ),
      TimelineRowSegment(
        id: 2,
        label: 'Permian',
        rank: GeologicRank.period,
        startMa: 252,
        endMa: 201,
        colorKey: '',
        isGap: false,
        unitSpan: 1,
        secondaryLabel: null,
      ),
    ];
    const extinctions = [
      ExtinctionDefinition(
        label: 'End-Permian',
        shortLabel: 'EP',
        isMajor: true,
        anchor: ExtinctionAnchor(
          type: ExtinctionAnchorType.period,
          label: 'Permian',
        ),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 200,
            child: ExtinctionMarkers(
              width: 400,
              height: 200,
              lineTop: 0,
              triangleTip: 100,
              periodSegments: periodSegments,
              stageSegments: const [],
              extinctions: extinctions,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final markerFinder = find.ancestor(
      of: find.text('End-Permian'),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox &&
            widget.height == ExtinctionMarkers.majorMarkerHeight,
      ),
    );
    expect(markerFinder, findsOneWidget);

    final markerTop = tester.getTopLeft(markerFinder).dy;
    final markerBottom = tester.getBottomLeft(markerFinder).dy;
    final markerHeight = markerBottom - markerTop;

    expect(markerHeight, ExtinctionMarkers.majorMarkerHeight);
    expect(markerTop, 100);
  });
}

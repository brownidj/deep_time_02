import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_event_markers.dart';

void main() {
  testWidgets('Point marker label is below the triangle', (tester) async {
    const events = [
      TimelineEventSegment(
        label: 'CE',
        shortLabel: 'CE',
        type: TimelineEventType.point,
        startMa: 100,
        endMa: 100,
        startUnit: 0.5,
        endUnit: 0.5,
        colorKey: '',
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 200,
            child: EventPointMarkers(
              width: 400,
              totalUnits: 1,
              events: events,
              height: 200,
              lineTop: 20,
              markerTop: 140,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final textFinder = find.text('CE');
    expect(textFinder, findsOneWidget);

    final customPaintFinder = find.descendant(
      of: find.byType(EventPointMarkers),
      matching: find.byType(CustomPaint),
    );
    expect(customPaintFinder, findsOneWidget);

    final textTop = tester.getTopLeft(textFinder).dy;
    final triangleBottom = tester.getBottomLeft(customPaintFinder).dy;

    expect(textTop, greaterThanOrEqualTo(triangleBottom));
  });

  testWidgets('Point marker line ends at boundary', (tester) async {
    const events = [
      TimelineEventSegment(
        label: 'PETM',
        shortLabel: 'PETM',
        type: TimelineEventType.point,
        startMa: 56,
        endMa: 56,
        startUnit: 0.5,
        endUnit: 0.5,
        colorKey: '',
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 200,
            child: EventPointMarkers(
              width: 400,
              totalUnits: 1,
              events: events,
              height: 200,
              lineTop: 20,
              markerTop: 140,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final lineFinder = find.byWidgetPredicate((widget) {
      if (widget is! Container) {
        return false;
      }
      return widget.color == EventPointMarkers.markerColor;
    });
    expect(lineFinder, findsWidgets);
    final firstLineTop = tester.getTopLeft(lineFinder.first).dy;
    expect(firstLineTop, 20);
  });

  testWidgets('Point marker triangle points up', (tester) async {
    const events = [
      TimelineEventSegment(
        label: 'PETM',
        shortLabel: 'PETM',
        type: TimelineEventType.point,
        startMa: 56,
        endMa: 56,
        startUnit: 0.5,
        endUnit: 0.5,
        colorKey: '',
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 200,
            child: EventPointMarkers(
              width: 400,
              totalUnits: 1,
              events: events,
              height: 200,
              lineTop: 20,
              markerTop: 140,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final triangleFinder = find.descendant(
      of: find.byType(EventPointMarkers),
      matching: find.byType(CustomPaint),
    );
    expect(triangleFinder, findsOneWidget);
    final triangleTop = tester.getTopLeft(triangleFinder).dy;
    final triangleBottom = tester.getBottomLeft(triangleFinder).dy;
    expect(triangleTop, lessThan(triangleBottom));
  });
}

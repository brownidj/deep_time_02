import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_event_markers.dart';

void main() {
  testWidgets('Point marker short label opens explanation on long press', (
    tester,
  ) async {
    const events = [
      TimelineEventSegment(
        label: 'PETM biotic event',
        shortLabel: 'PETM',
        type: TimelineEventType.point,
        explanation: 'Example explanation text.',
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

    await tester.ensureVisible(find.text('PETM'));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('PETM'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('PETM biotic event'), findsOneWidget);
    expect(find.text('Example explanation text.'), findsOneWidget);
  });

  testWidgets('Point marker line opens explanation on long press', (
    tester,
  ) async {
    const events = [
      TimelineEventSegment(
        label: 'PETM biotic event',
        shortLabel: 'PETM',
        type: TimelineEventType.point,
        explanation: 'Example explanation text.',
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
              showMarkers: false,
              showLines: false,
              showLineHitTargets: true,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.longPressAt(const Offset(200, 60));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('PETM biotic event'), findsOneWidget);
  });
}

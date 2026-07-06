import 'package:deep_time_2/domain/models/timeline_marker_catalog.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_body_metrics.dart';
import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/ui/models/time_label_mode.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_body_helpers.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_column_headers.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_orientation.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_track_widths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'timeline_layout_test_helpers.dart';

void main() {
  test(
    'default track order places waterways between continents and paleo-ecology',
    () {
      final continentsIndex = kDefaultTimelineTrackOrder.indexOf(
        TimelineTrack.continents,
      );
      final waterwaysIndex = kDefaultTimelineTrackOrder.indexOf(
        TimelineTrack.waterways,
      );
      final paleoIndex = kDefaultTimelineTrackOrder.indexOf(
        TimelineTrack.paleoEcology,
      );
      final rlifeIndex = kDefaultTimelineTrackOrder.indexOf(
        TimelineTrack.rlife,
      );

      expect(continentsIndex, isNonNegative);
      expect(waterwaysIndex, greaterThan(continentsIndex));
      expect(paleoIndex, greaterThan(waterwaysIndex));
      expect(rlifeIndex, greaterThan(paleoIndex));
    },
  );

  test('hiding hideable tracks closes remaining columns', () {
    final layout = layoutWithLongStage();
    const markers = TimelineMarkerCatalog(events: [], extinctions: []);
    final metrics = TimelineBodyMetrics.fromLayout(
      layout: layout,
      markers: markers,
      constraints: const BoxConstraints.tightFor(width: 1200, height: 800),
      trackOrder: [
        TimelineTrack.ma,
        TimelineTrack.eon,
        TimelineTrack.era,
        TimelineTrack.period,
        TimelineTrack.epoch,
        TimelineTrack.stage,
        TimelineTrack.extinctions,
        TimelineTrack.events,
        TimelineTrack.clades,
      ],
    );

    expect(metrics.trackOrder.contains(TimelineTrack.continents), isFalse);
    expect(metrics.trackOrder.contains(TimelineTrack.waterways), isFalse);
    expect(metrics.trackOrder.contains(TimelineTrack.paleoEcology), isFalse);
    expect(metrics.trackOrder.contains(TimelineTrack.rlife), isFalse);
    expect(
      metrics.trackX(TimelineTrack.extinctions),
      metrics.trackX(TimelineTrack.stage) +
          metrics.trackWidth(TimelineTrack.stage),
    );
  });

  test(
    'gap policy keeps fixed columns tight and hideable columns left-guttered',
    () {
      final layout = layoutWithLongStage();
      const markers = TimelineMarkerCatalog(events: [], extinctions: []);
      final metrics = TimelineBodyMetrics.fromLayout(
        layout: layout,
        markers: markers,
        constraints: const BoxConstraints.tightFor(width: 1200, height: 800),
      );

      expect(metrics.gapAfter(TimelineTrack.eon), 0);
      expect(metrics.gapAfter(TimelineTrack.era), 0);
      expect(metrics.gapAfter(TimelineTrack.period), 0);
      expect(metrics.gapAfter(TimelineTrack.epoch), 0);
      expect(metrics.gapAfter(TimelineTrack.stage), 0);
      expect(metrics.gapAfter(TimelineTrack.continents), 0);
      expect(metrics.gapAfter(TimelineTrack.waterways), 0);
      expect(metrics.gapAfter(TimelineTrack.paleoEcology), 0);
      expect(metrics.gapAfter(TimelineTrack.rlife), 0);
      expect(metrics.gapBefore(TimelineTrack.ma), 0);
      expect(metrics.gapBefore(TimelineTrack.eon), 0);
      expect(metrics.gapBefore(TimelineTrack.stage), 0);
      expect(
        metrics.gapBefore(TimelineTrack.continents),
        kTimelineStandardInterColumnGap,
      );
      expect(
        metrics.gapBefore(TimelineTrack.paleoEcology),
        kTimelineStandardInterColumnGap,
      );
      expect(
        metrics.gapBefore(TimelineTrack.waterways),
        kTimelineStandardInterColumnGap,
      );
      expect(
        metrics.gapBefore(TimelineTrack.rlife),
        kTimelineStandardInterColumnGap,
      );
      expect(metrics.gapBefore(TimelineTrack.extinctions), 0);
    },
  );

  test('extinction column butts against the visible column to its left', () {
    final layout = layoutWithLongStage();
    const markers = TimelineMarkerCatalog(events: [], extinctions: []);
    final metrics = TimelineBodyMetrics.fromLayout(
      layout: layout,
      markers: markers,
      constraints: const BoxConstraints.tightFor(width: 1200, height: 800),
      trackOrder: [
        TimelineTrack.ma,
        TimelineTrack.eon,
        TimelineTrack.era,
        TimelineTrack.period,
        TimelineTrack.epoch,
        TimelineTrack.stage,
        TimelineTrack.continents,
        TimelineTrack.paleoEcology,
        TimelineTrack.extinctions,
        TimelineTrack.events,
        TimelineTrack.clades,
      ],
    );

    expect(
      metrics.trackX(TimelineTrack.extinctions),
      metrics.trackX(TimelineTrack.paleoEcology) +
          metrics.trackWidth(TimelineTrack.paleoEcology),
    );
  });

  testWidgets('events column stays title-width while clades takes remainder', (
    tester,
  ) async {
    final layout = layoutWithLongStage();
    const markers = TimelineMarkerCatalog(events: [], extinctions: []);
    const eventTitleWidth = 52.0;
    const cladeBaseWidth = 100.0;
    final metrics = TimelineBodyMetrics.fromLayout(
      layout: layout,
      markers: markers,
      constraints: const BoxConstraints.tightFor(width: 800, height: 600),
      config: const TimelineOrientationConfig(
        trackWidths: {
          TimelineTrack.events: eventTitleWidth,
          TimelineTrack.clades: cladeBaseWidth,
        },
      ),
      trackOrder: const [TimelineTrack.events, TimelineTrack.clades],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 800,
          child: TimelineColumnHeaders(
            metrics: metrics,
            labelMode: TimeLabelMode.geologicTime,
          ),
        ),
      ),
    );

    final headerBoxes = find.byType(DecoratedBox);
    expect(headerBoxes, findsNWidgets(2));

    final eventsRect = tester.getRect(headerBoxes.at(0));
    final cladesRect = tester.getRect(headerBoxes.at(1));

    expect(eventsRect.width, eventTitleWidth);
    expect(cladesRect.width, 800 - eventTitleWidth);
  });

  testWidgets('paleo-ecology header shows geography legend', (tester) async {
    final metrics = TimelineBodyMetrics.fromLayout(
      layout: layoutWithLongStage(),
      markers: const TimelineMarkerCatalog(events: [], extinctions: []),
      constraints: const BoxConstraints.tightFor(width: 1200, height: 600),
      config: const TimelineOrientationConfig(
        trackWidths: {TimelineTrack.paleoEcology: 220},
      ),
      trackOrder: const [TimelineTrack.paleoEcology],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 220,
          child: TimelineColumnHeaders(
            metrics: metrics,
            labelMode: TimeLabelMode.geologicTime,
          ),
        ),
      ),
    );

    expect(find.text('Paleo-ecology'), findsOneWidget);
    expect(find.text('Extent | Bias | Anchor'), findsOneWidget);
  });

  test(
    'track width resolver shrinks tracks when total width exceeds viewport',
    () {
      final metrics = TimelineBodyMetrics.fromLayout(
        layout: layoutWithLongStage(),
        markers: const TimelineMarkerCatalog(events: [], extinctions: []),
        constraints: const BoxConstraints.tightFor(width: 1000, height: 600),
        config: const TimelineOrientationConfig(
          trackWidths: {
            TimelineTrack.ma: 220,
            TimelineTrack.eon: 220,
            TimelineTrack.era: 220,
            TimelineTrack.period: 220,
            TimelineTrack.epoch: 220,
          },
        ),
        trackOrder: const [
          TimelineTrack.ma,
          TimelineTrack.eon,
          TimelineTrack.era,
          TimelineTrack.period,
          TimelineTrack.epoch,
        ],
      );

      final resolved = resolveTimelineTrackWidths(
        metrics: metrics,
        maxWidth: 1000,
      );
      final totalWidth = metrics.trackOrder.fold<double>(0.0, (sum, track) {
        return sum +
            metrics.gapBefore(track) +
            resolved[track]! +
            metrics.gapAfter(track);
      });

      expect(totalWidth, closeTo(1000, 0.01));
      expect(
        resolved[TimelineTrack.ma]!,
        lessThan(metrics.trackWidth(TimelineTrack.ma)),
      );
    },
  );

  test('events width accounts for overlapping bar lanes', () {
    const events = [
      TimelineEventSegment(
        label: 'Older event',
        shortLabel: 'Older',
        type: TimelineEventType.bar,
        startMa: 100,
        endMa: 40,
        startUnit: 1,
        endUnit: 0.4,
        colorKey: 'period|test',
      ),
      TimelineEventSegment(
        label: 'Overlapping event',
        shortLabel: 'Overlap',
        type: TimelineEventType.bar,
        startMa: 80,
        endMa: 20,
        startUnit: 0.8,
        endUnit: 0.2,
        colorKey: 'period|test',
      ),
    ];

    expect(overlappingEventBarLaneCount(events), 2);
    expect(eventBarTrackWidth(events), (2 * 32) + 4 + 6);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/domain/models/geologic_rank.dart';
import 'package:deep_time_2/domain/models/timeline_marker_catalog.dart';
import 'package:deep_time_2/domain/models/timeline_palette.dart';
import 'package:deep_time_2/ui/models/clade_view_mode.dart';
import 'package:deep_time_2/ui/models/time_label_mode.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_body.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_orientation.dart';
import 'package:deep_time_2/ui/theme/deep_time_palette.dart';

void main() {
  testWidgets(
    'Vertical mode extinction marker opens explanation on long press',
    (tester) async {
      await _setLargeSurface(tester);
      final palette = DeepTimePalette(
        const TimelinePalette(
          divisionColors: {
            'eon|test': 0xFF111111,
            'era|test': 0xFF222222,
            'period|test': 0xFF333333,
            'epoch|test': 0xFF444444,
            'stage|test': 0xFF555555,
            'rlife|test': 0xFF666666,
          },
        ),
      );
      final layout = TimelineLayoutSnapshot(
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
        eventSegments: const [],
        continentSegments: const [],
        oldestMa: 100,
        youngestMa: 0,
      );
      const markers = TimelineMarkerCatalog(
        events: [],
        extinctions: [
          ExtinctionDefinition(
            label: 'Cretaceous-Paleogene extinction',
            shortLabel: 'KPg',
            isMajor: false,
            explanation: 'Vertical extinction explanation.',
            anchor: ExtinctionAnchor(
              type: ExtinctionAnchorType.period,
              label: 'TestPeriod',
            ),
          ),
        ],
      );

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

      await tester.ensureVisible(find.text('KPg'));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('KPg'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Cretaceous-Paleogene extinction'), findsOneWidget);
      expect(find.text('Vertical extinction explanation.'), findsOneWidget);
    },
  );
}

Future<void> _setLargeSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(2000, 1200));
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
}

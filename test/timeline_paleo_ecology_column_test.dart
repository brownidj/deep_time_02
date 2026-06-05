import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/domain/models/geologic_division.dart';
import 'package:deep_time_2/domain/models/geologic_rank.dart';
import 'package:deep_time_2/domain/models/paleo_ecology_entry.dart';
import 'package:deep_time_2/domain/models/timeline_marker_catalog.dart';
import 'package:deep_time_2/domain/models/timeline_palette.dart';
import 'package:deep_time_2/ui/models/clade_view_mode.dart';
import 'package:deep_time_2/ui/models/time_label_mode.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_body.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_orientation.dart';
import 'package:deep_time_2/ui/theme/deep_time_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'paleo-ecology painted edge reaches extinction column when rlife is hidden',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      final layout = TimelineLayoutSnapshot(
        divisions: const [],
        eonSegments: const [
          TimelineBandSegment(
            id: 1,
            label: 'TestEon',
            rank: GeologicRank.eon,
            startMa: 260,
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
            startMa: 260,
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
            startMa: 260,
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
            startMa: 260,
            endMa: 0,
            colorKey: 'epoch|test',
            isGap: false,
            unitSpan: 1,
          ),
        ],
        stageSegments: const [
          TimelineRowSegment(
            id: 5,
            label: 'Wuchiapingian',
            rank: GeologicRank.stage,
            startMa: 260,
            endMa: 0,
            colorKey: 'stage|test',
            isGap: false,
            unitSpan: 1,
          ),
        ],
        rlifeSegments: const [],
        eventSegments: const [],
        continentSegments: const [],
        oldestMa: 260,
        youngestMa: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1400,
              height: 800,
              child: Column(
                children: [
                  TimelineBody(
                    layout: layout,
                    palette: DeepTimePalette(
                      const TimelinePalette(
                        divisionColors: {
                          'eon|test': 0xFFEDE7C8,
                          'era|test': 0xFFEDE7C8,
                          'period|test': 0xFFEDE7C8,
                          'epoch|test': 0xFFEDE7C8,
                          'stage|test': 0xFFEDE7C8,
                        },
                      ),
                    ),
                    markers: const TimelineMarkerCatalog(
                      events: [],
                      extinctions: [
                        ExtinctionDefinition(
                          label: 'Test extinction',
                          shortLabel: 'TE',
                          isMajor: true,
                          anchor: ExtinctionAnchor(
                            type: ExtinctionAnchorType.stage,
                            label: 'Wuchiapingian',
                          ),
                        ),
                      ],
                    ),
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
                    visibleTracks: const {
                      TimelineTrack.ma,
                      TimelineTrack.eon,
                      TimelineTrack.era,
                      TimelineTrack.period,
                      TimelineTrack.epoch,
                      TimelineTrack.stage,
                      TimelineTrack.paleoEcology,
                      TimelineTrack.extinctions,
                    },
                    paleoEcology: const [
                      PaleoEcologyEntry(
                        rank: GeologicRank.stage,
                        name: 'Wuchiapingian',
                        path: ['Wuchiapingian'],
                        avgTempDeltaC: 5,
                        avgHumidityDeltaPercent: -4,
                        avgCo2Ppm: 1400,
                        seaLevelDeltaM: 15,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final paleoBox = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('paleo-ecology-block-stage:wuchiapingian')),
      );
      final extinctionBox = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('vertical-extinction-marker-TE')),
      );
      final paleoRight =
          paleoBox.localToGlobal(Offset.zero).dx + paleoBox.size.width;
      final extinctionLeft = extinctionBox.localToGlobal(Offset.zero).dx;

      expect(paleoRight, closeTo(extinctionLeft, 0.01));
    },
  );

  testWidgets('Paleo-ecology resolves higher-rank fallback blocks', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1800, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    const hadean = GeologicDivision(
      id: 1,
      name: 'Hadean',
      rank: GeologicRank.eon,
      startMa: 4567,
      endMa: 4031,
    );
    final layout = TimelineLayoutSnapshot(
      divisions: const [hadean],
      eonSegments: const [
        TimelineBandSegment(
          id: 1,
          label: 'Hadean',
          rank: GeologicRank.eon,
          startMa: 4567,
          endMa: 4031,
          colorKey: 'eon|hadean',
          isGap: false,
          unitSpan: 1,
        ),
      ],
      eraSegments: const [],
      periodSegments: const [],
      epochSegments: const [],
      stageSegments: const [
        TimelineRowSegment(
          id: -1,
          label: '',
          rank: GeologicRank.stage,
          startMa: 4567,
          endMa: 4031,
          colorKey: '',
          isGap: true,
          unitSpan: 1,
        ),
      ],
      rlifeSegments: const [],
      eventSegments: const [],
      continentSegments: const [],
      oldestMa: 4567,
      youngestMa: 4031,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1800,
            height: 900,
            child: Column(
              children: [
                TimelineBody(
                  layout: layout,
                  palette: DeepTimePalette(
                    const TimelinePalette(
                      divisionColors: {'eon|hadean': 0xFFA4348B},
                    ),
                  ),
                  markers: const TimelineMarkerCatalog(
                    events: [],
                    extinctions: [],
                  ),
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
                  visibleTracks: {...kDefaultTimelineTrackOrder},
                  paleoEcology: const [
                    PaleoEcologyEntry(
                      rank: GeologicRank.eon,
                      name: 'Hadean',
                      path: ['Hadean'],
                      avgTempDeltaC: 12,
                      avgHumidityDeltaPercent: -2,
                      avgCo2Ppm: 6000,
                      seaLevelDeltaM: -100,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Temp:'), findsOneWidget);
    expect(find.textContaining('CO2'), findsOneWidget);
  });
}

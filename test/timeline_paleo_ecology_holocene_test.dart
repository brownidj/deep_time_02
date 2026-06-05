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
  testWidgets('Paleo-ecology resolves Holocene stage blocks', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1800, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    const phanerozoic = GeologicDivision(
      id: 1,
      name: 'Phanerozoic',
      rank: GeologicRank.eon,
      startMa: 541,
      endMa: 0,
    );
    const cenozoic = GeologicDivision(
      id: 2,
      name: 'Cenozoic',
      rank: GeologicRank.era,
      startMa: 66,
      endMa: 0,
      parentId: 1,
    );
    const quaternary = GeologicDivision(
      id: 3,
      name: 'Quaternary',
      rank: GeologicRank.period,
      startMa: 2.58,
      endMa: 0,
      parentId: 2,
    );
    const holocene = GeologicDivision(
      id: 4,
      name: 'Holocene',
      rank: GeologicRank.epoch,
      startMa: 0.0117,
      endMa: 0,
      parentId: 3,
    );
    const northgrippian = GeologicDivision(
      id: 5,
      name: 'Northgrippian',
      rank: GeologicRank.stage,
      startMa: 0.0082,
      endMa: 0.0042,
      parentId: 4,
    );
    const meghalayan = GeologicDivision(
      id: 6,
      name: 'Meghalayan',
      rank: GeologicRank.stage,
      startMa: 0.0042,
      endMa: 0,
      parentId: 4,
    );

    final layout = TimelineLayoutSnapshot(
      divisions: const [
        phanerozoic,
        cenozoic,
        quaternary,
        holocene,
        northgrippian,
        meghalayan,
      ],
      eonSegments: const [
        TimelineBandSegment(
          id: 1,
          label: 'Phanerozoic',
          rank: GeologicRank.eon,
          startMa: 541,
          endMa: 0,
          colorKey: 'eon|phanerozoic',
          isGap: false,
          unitSpan: 2,
        ),
      ],
      eraSegments: const [
        TimelineBandSegment(
          id: 2,
          label: 'Cenozoic',
          rank: GeologicRank.era,
          startMa: 66,
          endMa: 0,
          colorKey: 'era|cenozoic',
          isGap: false,
          unitSpan: 2,
        ),
      ],
      periodSegments: const [
        TimelineRowSegment(
          id: 3,
          label: 'Quaternary',
          rank: GeologicRank.period,
          startMa: 2.58,
          endMa: 0,
          colorKey: 'period|quaternary',
          isGap: false,
          unitSpan: 2,
        ),
      ],
      epochSegments: const [
        TimelineRowSegment(
          id: 4,
          label: 'Holocene',
          rank: GeologicRank.epoch,
          startMa: 0.0117,
          endMa: 0,
          colorKey: 'epoch|holocene',
          isGap: false,
          unitSpan: 2,
        ),
      ],
      stageSegments: const [
        TimelineRowSegment(
          id: 5,
          label: 'Northgrippian',
          rank: GeologicRank.stage,
          startMa: 0.0082,
          endMa: 0.0042,
          colorKey: 'stage|northgrippian',
          isGap: false,
          unitSpan: 1,
        ),
        TimelineRowSegment(
          id: 6,
          label: 'Meghalayan',
          rank: GeologicRank.stage,
          startMa: 0.0042,
          endMa: 0,
          colorKey: 'stage|meghalayan',
          isGap: false,
          unitSpan: 1,
        ),
      ],
      rlifeSegments: const [],
      eventSegments: const [],
      continentSegments: const [],
      oldestMa: 0.0082,
      youngestMa: 0,
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
                      divisionColors: {
                        'eon|phanerozoic': 0xFFAAAAAA,
                        'era|cenozoic': 0xFFBBBBBB,
                        'period|quaternary': 0xFFCCCCCC,
                        'epoch|holocene': 0xFFDDDDDD,
                        'stage|northgrippian': 0xFFEDE7C8,
                        'stage|meghalayan': 0xFFEDE7C8,
                      },
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
                      rank: GeologicRank.stage,
                      name: 'Northgrippian',
                      path: [
                        'Phanerozoic',
                        'Cenozoic',
                        'Quaternary',
                        'Holocene',
                        'Northgrippian',
                      ],
                      avgTempDeltaC: 0,
                      avgHumidityDeltaPercent: 0,
                      avgCo2Ppm: 300,
                      seaLevelDeltaM: -2,
                    ),
                    PaleoEcologyEntry(
                      rank: GeologicRank.stage,
                      name: 'Meghalayan',
                      path: [
                        'Phanerozoic',
                        'Cenozoic',
                        'Quaternary',
                        'Holocene',
                        'Meghalayan',
                      ],
                      avgTempDeltaC: 0.5,
                      avgHumidityDeltaPercent: 0,
                      avgCo2Ppm: 400,
                      seaLevelDeltaM: 0,
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

    expect(find.textContaining('CO2\u00A0300ppm'), findsOneWidget);
    expect(find.textContaining('CO2\u00A0400ppm'), findsOneWidget);
  });
}

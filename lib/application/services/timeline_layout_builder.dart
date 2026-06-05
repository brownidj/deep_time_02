import 'package:deep_time_2/application/services/timeline_layout_builder_right_to_left.dart';
import 'package:deep_time_2/application/services/timeline_layout_events.dart';
import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/application/services/timeline_layout_rlife.dart';
import 'package:deep_time_2/domain/models/timeline_marker_catalog.dart';
import 'package:deep_time_2/domain/models/geologic_division.dart';
import 'package:deep_time_2/domain/models/geologic_rank.dart';

class TimelineLayoutBuilder {
  TimelineLayoutSnapshot build(
    List<GeologicDivision> divisions,
    TimelineMarkerCatalog markers,
    List<TimelineEventDefinition> continents,
    List<TimelineEventDefinition> waterways,
  ) {
    if (divisions.isEmpty) {
      return const TimelineLayoutSnapshot(
        divisions: [],
        eonSegments: [],
        eraSegments: [],
        periodSegments: [],
        epochSegments: [],
        stageSegments: [],
        rlifeSegments: [],
        eventSegments: [],
        continentSegments: [],
        oldestMa: 0,
        youngestMa: 0,
        fixedHeight: null,
      );
    }

    final divisionById = {
      for (final division in divisions) division.id: division,
    };
    final childrenByParentId = <int, List<GeologicDivision>>{};
    for (final division in divisions) {
      final parentId = division.parentId;
      if (parentId == null) {
        continue;
      }
      childrenByParentId.putIfAbsent(parentId, () => []).add(division);
    }

    final eons =
        divisions
            .where((division) => division.rank == GeologicRank.eon)
            .toList()
          ..sort((a, b) => b.startMa.compareTo(a.startMa));
    if (eons.isEmpty) {
      return const TimelineLayoutSnapshot(
        divisions: [],
        eonSegments: [],
        eraSegments: [],
        periodSegments: [],
        epochSegments: [],
        stageSegments: [],
        rlifeSegments: [],
        eventSegments: [],
        continentSegments: [],
        oldestMa: 0,
        youngestMa: 0,
        fixedHeight: null,
      );
    }

    final oldestMa = eons.first.startMa;
    final youngestMa = eons.last.endMa;

    final layoutBuilder = RightToLeftDivisionLayout(
      divisions: divisions,
      divisionById: divisionById,
      childrenByParentId: childrenByParentId,
    );
    final layout = layoutBuilder.build();

    final rlifeBuilder = TimelineRLifeBuilder(divisionById: divisionById);
    final rlifeSegments = rlifeBuilder.buildRLifeRowFromPeriods(
      layout.periodSegments,
    );
    final eventsBuilder = TimelineEventsBuilder(definitions: markers.events);
    final eventSegments = eventsBuilder.buildEventsRow(
      periodSegments: layout.periodSegments,
      eraSegments: layout.eraSegments,
    );
    final continentsBuilder = TimelineEventsBuilder(definitions: continents);
    final continentSegments = continentsBuilder.buildEventsRow(
      periodSegments: layout.periodSegments,
      eraSegments: layout.eraSegments,
    );
    final waterwaysBuilder = TimelineEventsBuilder(definitions: waterways);
    final waterwaySegments = waterwaysBuilder.buildEventsRow(
      periodSegments: layout.periodSegments,
      eraSegments: layout.eraSegments,
    );

    return TimelineLayoutSnapshot(
      divisions: divisions,
      eonSegments: layout.eonSegments,
      eraSegments: layout.eraSegments,
      periodSegments: layout.periodSegments,
      epochSegments: layout.epochSegments,
      stageSegments: layout.stageSegments,
      rlifeSegments: rlifeSegments,
      eventSegments: eventSegments,
      continentSegments: continentSegments,
      waterwaySegments: waterwaySegments,
      oldestMa: oldestMa,
      youngestMa: youngestMa,
      fixedHeight: layout.fixedHeight,
    );
  }
}

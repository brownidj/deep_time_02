import 'package:flutter_test/flutter_test.dart';
import 'package:deep_time_2/application/services/timeline_layout_service.dart';
import 'package:deep_time_2/domain/models/geologic_division.dart';
import 'package:deep_time_2/domain/models/geologic_rank.dart';
import 'package:deep_time_2/domain/models/timeline_marker_catalog.dart';
import 'package:deep_time_2/domain/models/timeline_palette.dart';

void main() {
  test(
    'build creates period/epoch rows and keeps Carboniferous epochs contiguous',
    () {
      final divisions = [
        const GeologicDivision(
          id: 1,
          name: 'Phanerozoic',
          rank: GeologicRank.eon,
          startMa: 541,
          endMa: 0,
          parentId: null,
        ),
        const GeologicDivision(
          id: 2,
          name: 'Paleozoic',
          rank: GeologicRank.era,
          startMa: 541,
          endMa: 252,
          parentId: 1,
        ),
        const GeologicDivision(
          id: 3,
          name: 'Carboniferous',
          rank: GeologicRank.period,
          startMa: 358.86,
          endMa: 298.9,
          parentId: 2,
        ),
        const GeologicDivision(
          id: 4,
          name: 'Mississippian',
          rank: GeologicRank.epoch,
          startMa: 358.86,
          endMa: 323.4,
          parentId: 3,
        ),
        const GeologicDivision(
          id: 5,
          name: 'Pennsylvanian',
          rank: GeologicRank.epoch,
          startMa: 323.4,
          endMa: 298.9,
          parentId: 3,
        ),
        const GeologicDivision(
          id: 6,
          name: 'Permian',
          rank: GeologicRank.period,
          startMa: 298.9,
          endMa: 252,
          parentId: 2,
        ),
        const GeologicDivision(
          id: 7,
          name: 'Cisuralian',
          rank: GeologicRank.epoch,
          startMa: 298.9,
          endMa: 272.95,
          parentId: 6,
        ),
        const GeologicDivision(
          id: 8,
          name: 'Asselian',
          rank: GeologicRank.period,
          startMa: 298.9,
          endMa: 293.5,
          parentId: 7,
        ),
      ];

      final service = TimelineLayoutService();
      final layout = service.build(
        divisions,
        _testMarkers(),
        const [],
        const [],
      );
      final epochLabels = layout.epochSegments
          .where((segment) => !segment.isGap)
          .map((segment) {
            return segment.label;
          })
          .toList();
      final periodLabels = layout.periodSegments
          .where((segment) => !segment.isGap)
          .map((segment) {
            return segment.label;
          })
          .toList();

      expect(epochLabels, ['Mississippian', 'Pennsylvanian', 'Cisuralian']);
      expect(periodLabels, ['Carboniferous', 'Permian']);
      expect(
        layout.epochSegments
            .firstWhere((s) => s.label == 'Mississippian')
            .endMa,
        layout.epochSegments
            .firstWhere((s) => s.label == 'Pennsylvanian')
            .startMa,
      );
      expect(layout.eraSegments, hasLength(1));
      expect(layout.eonSegments, hasLength(1));
    },
  );

  test('build orders periods oldest to youngest regardless of input order', () {
    final divisions = [
      const GeologicDivision(
        id: 1,
        name: 'Phanerozoic',
        rank: GeologicRank.eon,
        startMa: 541,
        endMa: 0,
        parentId: null,
      ),
      const GeologicDivision(
        id: 2,
        name: 'Paleozoic',
        rank: GeologicRank.era,
        startMa: 541,
        endMa: 252,
        parentId: 1,
      ),
      const GeologicDivision(
        id: 3,
        name: 'Permian',
        rank: GeologicRank.period,
        startMa: 298.9,
        endMa: 252,
        parentId: 2,
      ),
      const GeologicDivision(
        id: 4,
        name: 'Carboniferous',
        rank: GeologicRank.period,
        startMa: 358.86,
        endMa: 298.9,
        parentId: 2,
      ),
      const GeologicDivision(
        id: 5,
        name: 'Devonian',
        rank: GeologicRank.period,
        startMa: 419.2,
        endMa: 358.86,
        parentId: 2,
      ),
    ];

    final service = TimelineLayoutService();
    final layout = service.build(divisions, _testMarkers(), const [], const []);
    final periodLabels = layout.periodSegments
        .where((segment) => !segment.isGap)
        .map((segment) => segment.label)
        .toList();

    expect(periodLabels, ['Devonian', 'Carboniferous', 'Permian']);
  });

  test('build orders eons oldest to youngest regardless of input order', () {
    final divisions = [
      const GeologicDivision(
        id: 1,
        name: 'Phanerozoic',
        rank: GeologicRank.eon,
        startMa: 541,
        endMa: 0,
        parentId: null,
      ),
      const GeologicDivision(
        id: 2,
        name: 'Hadean',
        rank: GeologicRank.eon,
        startMa: 4567,
        endMa: 4031,
        parentId: null,
      ),
      const GeologicDivision(
        id: 3,
        name: 'Archean',
        rank: GeologicRank.eon,
        startMa: 4031,
        endMa: 2500,
        parentId: null,
      ),
      const GeologicDivision(
        id: 4,
        name: 'Proterozoic',
        rank: GeologicRank.eon,
        startMa: 2500,
        endMa: 541,
        parentId: null,
      ),
    ];

    final service = TimelineLayoutService();
    final layout = service.build(divisions, _testMarkers(), const [], const []);
    final eonLabels = layout.eonSegments
        .where((segment) => !segment.isGap)
        .map((segment) => segment.label)
        .toList();

    expect(eonLabels, ['Hadean', 'Archean', 'Proterozoic', 'Phanerozoic']);
  });

  test('build includes event segments with period-based color keys', () {
    final divisions = [
      const GeologicDivision(
        id: 1,
        name: 'Phanerozoic',
        rank: GeologicRank.eon,
        startMa: 66,
        endMa: 0,
        parentId: null,
      ),
      const GeologicDivision(
        id: 2,
        name: 'Cenozoic',
        rank: GeologicRank.era,
        startMa: 66,
        endMa: 0,
        parentId: 1,
      ),
      const GeologicDivision(
        id: 3,
        name: 'Paleogene',
        rank: GeologicRank.period,
        startMa: 66,
        endMa: 23,
        parentId: 2,
      ),
      const GeologicDivision(
        id: 4,
        name: 'Neogene',
        rank: GeologicRank.period,
        startMa: 23,
        endMa: 0,
        parentId: 2,
      ),
    ];

    final service = TimelineLayoutService();
    final layout = service.build(divisions, _testMarkers(), const [], const []);

    expect(layout.eventSegments, isNotEmpty);

    final petm = layout.eventSegments.firstWhere(
      (e) => e.label == 'PETM biotic event',
    );
    expect(petm.type.name, 'point');

    final expectedKey = divisionColorKey(
      name: 'Paleogene',
      rank: 'period',
      parentKey: divisionColorKey(
        name: 'Cenozoic',
        rank: 'era',
        parentKey: divisionColorKey(name: 'Phanerozoic', rank: 'eon'),
      ),
    );
    expect(petm.colorKey, expectedKey);
  });
}

TimelineMarkerCatalog _testMarkers() {
  return const TimelineMarkerCatalog(
    events: [
      TimelineEventDefinition(
        label: 'PETM biotic event',
        shortLabel: 'PETM',
        kind: TimelineEventKind.point,
        atMa: 56,
      ),
      TimelineEventDefinition(
        label: 'Rise of mammals',
        shortLabel: 'Mammal rise',
        kind: TimelineEventKind.bar,
        startMa: 66,
        endMa: 23,
      ),
    ],
    extinctions: [],
  );
}

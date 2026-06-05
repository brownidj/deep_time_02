import 'package:flutter_test/flutter_test.dart';
import 'package:deep_time_2/application/services/clade_visibility_resolver.dart';
import 'package:deep_time_2/domain/models/clade.dart';
import 'package:deep_time_2/domain/models/clade_zoom_level.dart';

void main() {
  const resolver = CladeVisibilityResolver(maxClades: 2);

  const clades = [
    Clade(
      id: 'a',
      label: 'Alpha',
      scientificRank: 'class',
      startMa: 500,
      endMa: 400,
      displayGroups: ['marine_invertebrates'],
      displayPriority: 10,
      minZoomLevel: CladeZoomLevel.period,
    ),
    Clade(
      id: 'b',
      label: 'Beta',
      scientificRank: 'class',
      startMa: 300,
      endMa: 200,
      displayGroups: ['plants'],
      displayPriority: 5,
      minZoomLevel: CladeZoomLevel.era,
    ),
    Clade(
      id: 'c',
      label: 'Gamma',
      scientificRank: 'class',
      startMa: 100,
      endMa: 0,
      displayGroups: ['mammals_birds'],
      displayPriority: 20,
      minZoomLevel: CladeZoomLevel.epoch,
    ),
  ];

  test('zoom level mapping follows scale thresholds', () {
    expect(resolver.zoomLevelForScale(1.0), CladeZoomLevel.whole);
    expect(resolver.zoomLevelForScale(2.0), CladeZoomLevel.phanerozoic);
    expect(resolver.zoomLevelForScale(2.7), CladeZoomLevel.era);
    expect(resolver.zoomLevelForScale(3.2), CladeZoomLevel.period);
    expect(resolver.zoomLevelForScale(3.6), CladeZoomLevel.epoch);
  });

  test('filters by overlap and min zoom level', () {
    final visible = resolver.resolve(
      clades: clades,
      zoomLevel: CladeZoomLevel.period,
      visibleStartMa: 450,
      visibleEndMa: 250,
    );
    expect(visible.map((c) => c.id).toList(), ['b', 'a']);
  });

  test('filters by display group when provided', () {
    final visible = resolver.resolve(
      clades: clades,
      zoomLevel: CladeZoomLevel.epoch,
      visibleStartMa: 600,
      visibleEndMa: 0,
      displayGroupId: 'plants',
    );
    expect(visible.length, 1);
    expect(visible.first.id, 'b');
  });

  test('caps to max clades by priority', () {
    final visible = resolver.resolve(
      clades: clades,
      zoomLevel: CladeZoomLevel.epoch,
      visibleStartMa: 600,
      visibleEndMa: 0,
    );
    expect(visible.length, 2);
    expect(visible.map((c) => c.id).toList(), ['b', 'a']);
  });
}

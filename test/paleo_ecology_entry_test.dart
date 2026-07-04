import 'package:deep_time_2/domain/models/geologic_rank.dart';
import 'package:deep_time_2/domain/models/paleo_ecology_entry.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_min_height_helpers_paleo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves geographic display fields from nearest ancestors', () {
    const period = PaleoEcologyEntry(
      rank: GeologicRank.period,
      name: 'Jurassic',
      path: ['Phanerozoic', 'Mesozoic', 'Jurassic'],
      geographicAnchor: ['Tethys', 'Panthalassa margins'],
      spatialExtent: 'global',
      hemisphericBias: 'both',
      manifestationType: ['warming'],
    );
    const stage = PaleoEcologyEntry(
      rank: GeologicRank.stage,
      name: 'Toarcian',
      path: ['Phanerozoic', 'Mesozoic', 'Jurassic', 'Lower', 'Toarcian'],
      spatialExtent: 'ocean_basin',
      manifestationType: ['ocean_anoxia'],
    );

    final entriesByKey = {period.lookupKey: period, stage.lookupKey: stage};

    final resolved = resolvePaleoEcologyDisplayEntry(stage, entriesByKey);

    expect(resolved.spatialExtent, 'ocean_basin');
    expect(resolved.manifestationType, ['ocean_anoxia']);
    expect(resolved.geographicAnchor, ['Tethys', 'Panthalassa margins']);
    expect(resolved.hemisphericBias, 'both');
  });

  test('reports inherited geography source rank', () {
    const period = PaleoEcologyEntry(
      rank: GeologicRank.period,
      name: 'Triassic',
      path: ['Phanerozoic', 'Mesozoic', 'Triassic'],
      geographicAnchor: ['Central Atlantic Magmatic Province'],
      spatialExtent: 'global',
    );
    const stage = PaleoEcologyEntry(
      rank: GeologicRank.stage,
      name: 'Carnian',
      path: ['Phanerozoic', 'Mesozoic', 'Triassic', 'Upper', 'Carnian'],
    );

    final resolution = resolvePaleoEcologyDisplay(stage, {
      period.lookupKey: period,
      stage.lookupKey: stage,
    });

    expect(resolution.entry.spatialExtent, 'global');
    expect(resolution.entry.geographicAnchor, [
      'Central Atlantic Magmatic Province',
    ]);
    expect(resolution.inheritedFromRank, GeologicRank.period);
  });

  test('summary uses compact geography labels', () {
    const entry = PaleoEcologyEntry(
      rank: GeologicRank.stage,
      name: 'Test Stage',
      path: ['Phanerozoic', 'Cenozoic', 'Quaternary', 'Holocene', 'Test Stage'],
      spatialExtent: 'global',
      hemisphericBias: 'southern',
      geographicAnchor: ['Gondwana'],
    );

    expect(
      paleoEcologySummaryText(entry),
      'Ex: Global; Bi: Southern\nAn: Gondwana',
    );
  });
}

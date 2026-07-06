import 'package:deep_time_2/domain/models/geologic_rank.dart';
import 'package:deep_time_2/domain/models/paleo_ecology_entry.dart';
import 'package:deep_time_2/infra/repositories/yaml_paleo_ecology_repository.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_min_height_helpers_paleo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';
import 'dart:io';

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

  test('summary marks inherited geography with a small star', () {
    const entry = PaleoEcologyEntry(
      rank: GeologicRank.stage,
      name: 'Test Stage',
      path: ['Phanerozoic', 'Mesozoic', 'Triassic', 'Upper', 'Test Stage'],
      spatialExtent: 'global',
      geographicAnchor: ['Central Atlantic Magmatic Province'],
    );

    expect(
      paleoEcologySummaryText(entry, showInheritedMarker: true),
      'Ex: Global\nAn*: Central Atlantic Magmatic Province',
    );
  });

  test('project paleo data covers every stage block with resolved geography', () {
    final repository = YamlPaleoEcologyRepository(
      assetPath: 'data/paleo_ecology.yaml',
    );
    final entries = repository.parseEntries(
      File('data/paleo_ecology.yaml').readAsStringSync(),
    );
    final entriesByKey = {for (final entry in entries) entry.lookupKey: entry};
    final stagePaths = _collectStagePathsFromDivisionsYaml();

    final missingStageEntries = <List<String>>[];
    final unresolvedGeographyStages = <List<String>>[];

    for (final path in stagePaths) {
      final key = PaleoEcologyEntry.lookupKeyFor(
        rank: GeologicRank.stage,
        path: path,
      );
      final entry = entriesByKey[key];
      if (entry == null) {
        missingStageEntries.add(path);
        continue;
      }
      if (!entry.hasMetricSummary) {
        continue;
      }
      final resolved = resolvePaleoEcologyDisplayEntry(entry, entriesByKey);
      final hasGeography =
          resolved.spatialExtent != null ||
          (resolved.hemisphericBias != null &&
              resolved.hemisphericBias != 'both') ||
          resolved.geographicAnchor.isNotEmpty;
      if (!hasGeography) {
        unresolvedGeographyStages.add(path);
      }
    }

    expect(
      missingStageEntries,
      isEmpty,
      reason:
          'Missing stage paleo entries: ${missingStageEntries.map((path) => path.join(' > ')).join(', ')}',
    );
    expect(
      unresolvedGeographyStages,
      isEmpty,
      reason:
          'Stage blocks missing resolved geography: ${unresolvedGeographyStages.map((path) => path.join(' > ')).join(', ')}',
    );
  });
}

List<List<String>> _collectStagePathsFromDivisionsYaml() {
  final document =
      loadYaml(File('data/time_divisions.yaml').readAsStringSync()) as YamlMap;
  final out = <List<String>>[];

  void visitNodes(Object? rawNodes, List<String> path) {
    if (rawNodes is! YamlList) {
      return;
    }
    for (final item in rawNodes.whereType<YamlMap>()) {
      final name = item['name'];
      final rank = item['rank'];
      if (name is! String || rank is! String) {
        continue;
      }
      final nextPath = [...path, name.trim()];
      if (rank.trim() == GeologicRank.stage.name) {
        out.add(nextPath);
      }
      visitNodes(item['children'], nextPath);
    }
  }

  visitNodes(document['eons'], const []);
  return out;
}

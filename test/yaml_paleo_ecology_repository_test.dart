import 'dart:io';

import 'package:deep_time_2/domain/models/geologic_rank.dart';
import 'package:deep_time_2/infra/repositories/yaml_paleo_ecology_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses rank and path based entries with optional metrics', () {
    final repository = YamlPaleoEcologyRepository(
      assetPath: 'data/paleo_ecology.yaml',
    );

    final entries = repository.parseEntries('''
paleo_ecology:
  - rank: eon
    name: Hadean
    path:
      - Hadean
  - rank: period
    name: Ediacaran
    path:
      - Proterozoic
      - Neoproterozoic
      - Ediacaran
    avg_temp_delta_c: -2.0
    avg_humidity_delta_percent: 1.0
    avg_co2_ppm: 2500
    sea_level_delta_m: 40.0
''');

    expect(entries, hasLength(2));
    expect(entries.first.rank, GeologicRank.eon);
    expect(entries.first.name, 'Hadean');
    expect(entries.first.path, ['Hadean']);
    expect(entries.first.hasMetricSummary, isFalse);

    expect(entries.last.rank, GeologicRank.period);
    expect(
      entries.last.lookupKey,
      'period:proterozoic/neoproterozoic/ediacaran',
    );
    expect(entries.last.hasMetricSummary, isTrue);
  });

  test('parses partially populated metric sets', () {
    final repository = YamlPaleoEcologyRepository(
      assetPath: 'data/paleo_ecology.yaml',
    );

    final entries = repository.parseEntries('''
paleo_ecology:
  - rank: period
    name: Ediacaran
    path:
      - Proterozoic
      - Neoproterozoic
      - Ediacaran
    avg_temp_delta_c: -2.0
    avg_co2_ppm: 2500
''');

    expect(entries.single.avgTempDeltaC, -2.0);
    expect(entries.single.avgHumidityDeltaPercent, isNull);
    expect(entries.single.avgCo2Ppm, 2500);
    expect(entries.single.seaLevelDeltaM, isNull);
    expect(entries.single.hasMetricSummary, isTrue);
    expect(entries.single.hasCompleteMetricSummary, isFalse);
  });

  test('parses contextual paleo fields including sources', () {
    final repository = YamlPaleoEcologyRepository(
      assetPath: 'data/paleo_ecology.yaml',
    );

    final entries = repository.parseEntries('''
paleo_ecology:
  - rank: stage
    name: Chattian
    path:
      - Phanerozoic
      - Cenozoic
      - Paleogene
      - Oligocene
      - Chattian
    avg_temp_delta_c: +2.0
    avg_humidity_delta_percent: -1.0
    avg_co2_ppm: 600
    sea_level_delta_m: +20.0
    icehouse_greenhouse_state: icehouse
    dominant_ecology: late Oligocene cooler ecosystems
    confidence: moderate
    note: Oligocene values reflect cooler icehouse conditions.
    sources:
      - Source A
      - Source B
''');

    final entry = entries.single;
    expect(entry.icehouseGreenhouseState, 'icehouse');
    expect(entry.dominantEcology, 'late Oligocene cooler ecosystems');
    expect(entry.confidence, 'moderate');
    expect(entry.note, 'Oligocene values reflect cooler icehouse conditions.');
    expect(entry.sources, ['Source A', 'Source B']);
  });

  test('project paleo ecology file includes higher-rank entries', () {
    final repository = YamlPaleoEcologyRepository(
      assetPath: 'data/paleo_ecology.yaml',
    );
    final entries = repository.parseEntries(
      File('data/paleo_ecology.yaml').readAsStringSync(),
    );

    expect(
      entries.any(
        (entry) =>
            entry.rank == GeologicRank.eon &&
            entry.name == 'Hadean' &&
            entry.hasMetricSummary &&
            !entry.hasCompleteMetricSummary,
      ),
      isTrue,
    );
    expect(
      entries.any(
        (entry) =>
            entry.rank == GeologicRank.stage &&
            entry.name == 'Fortunian' &&
            entry.hasMetricSummary,
      ),
      isTrue,
    );
  });
}

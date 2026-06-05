import 'dart:io';

import 'package:deep_time_2/domain/models/timeline_marker_catalog.dart';
import 'package:deep_time_2/infra/repositories/yaml_waterway_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses waterway bars from yaml', () {
    final repository = YamlWaterwayRepository(assetPath: 'data/waterways.yaml');

    final waterways = repository.parseWaterways('''
waterways:
  - label: Tethys Ocean
    short_label: Tethys
    start_ma: 250
    end_ma: 50
    explanation: Major Mesozoic ocean between Gondwana and Laurasia.
''');

    expect(waterways, hasLength(1));
    expect(waterways.single.label, 'Tethys Ocean');
    expect(waterways.single.shortLabel, 'Tethys');
    expect(waterways.single.kind, TimelineEventKind.bar);
    expect(waterways.single.startMa, 250);
    expect(waterways.single.endMa, 50);
    expect(
      waterways.single.explanation,
      'Major Mesozoic ocean between Gondwana and Laurasia.',
    );
  });

  test('parses existing seas root from waterways yaml', () {
    final repository = YamlWaterwayRepository(assetPath: 'data/waterways.yaml');

    final waterways = repository.parseWaterways('''
seas:
  - label: Western Interior Seaway
    short_label: W. Interior Seaway
    type: bar
    start_ma: 100
    end_ma: 66
''');

    expect(waterways, hasLength(1));
    expect(waterways.single.label, 'Western Interior Seaway');
    expect(waterways.single.shortLabel, 'W. Interior Seaway');
    expect(waterways.single.kind, TimelineEventKind.bar);
  });

  test('project waterways file is valid yaml', () {
    final repository = YamlWaterwayRepository(assetPath: 'data/waterways.yaml');

    final waterways = repository.parseWaterways(
      File('data/waterways.yaml').readAsStringSync(),
    );

    expect(waterways, isNotEmpty);
    expect(
      waterways.map((waterway) => waterway.label),
      containsAll(['Panthalassa', 'Tethys Ocean', 'Western Interior Seaway']),
    );
  });
}

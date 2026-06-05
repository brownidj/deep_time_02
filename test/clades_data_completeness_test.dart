import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('project clade data includes requested backbone and detail clades', () {
    final document = loadYaml(File('data/clades.yaml').readAsStringSync());
    expect(document, isA<YamlList>());
    final clades = {
      for (final entry in (document as YamlList).whereType<YamlMap>())
        entry['id'] as String: entry,
    };

    const expectedIds = {
      'luca',
      'bacteria',
      'archaea',
      'eukaryota',
      'archaeplastida',
      'animalia',
      'bilateria',
      'protostomia',
      'arthropoda',
      'trilobita',
      'mollusca',
      'deuterostomia',
      'echinodermata',
      'chordata',
      'vertebrata',
      'gnathostomata',
      'osteichthyes',
      'tetrapoda',
      'amniota',
      'synapsida',
      'therapsida',
      'mammalia',
      'sauropsida',
      'diapsida',
      'archosauria',
      'pterosauria',
      'dinosauria',
      'non_avian_dinosaurs',
      'aves',
      'angiospermae',
      'poaceae',
      'primates',
      'hominini',
      'homo',
      'homo_sapiens',
    };

    expect(clades.keys, containsAll(expectedIds));
    expect(clades['dinosauria']?['end_ma'], 0.0);
    expect(clades['dinosauria']?['parent_id'], 'archosauria');
    expect(clades['non_avian_dinosaurs']?['end_ma'], 66.0);
    expect(clades['aves']?['parent_id'], 'dinosauria');
  });

  test('representative clade list includes every clade', () {
    final cladeDocument = loadYaml(File('data/clades.yaml').readAsStringSync());
    final cladeIds = {
      for (final entry in (cladeDocument as YamlList).whereType<YamlMap>())
        entry['id'] as String,
    };
    final representativeDocument = loadYaml(
      File('data/clade_representative_ids.yaml').readAsStringSync(),
    );
    expect(representativeDocument, isA<YamlList>());
    final ids = (representativeDocument as YamlList)
        .whereType<String>()
        .toSet();

    expect(ids, cladeIds);
  });

  test('optional OpenTree-oriented fields have valid shapes when present', () {
    final document = loadYaml(File('data/clades.yaml').readAsStringSync());
    expect(document, isA<YamlList>());
    final clades = (document as YamlList).whereType<YamlMap>();

    for (final entry in clades) {
      final ottId = entry['ott_id'];
      expect(ottId == null || ottId is num || ottId is String, isTrue);

      final includeInMainTree = entry['include_in_main_tree'];
      expect(
        includeInMainTree == null ||
            includeInMainTree is bool ||
            includeInMainTree is String,
        isTrue,
      );

      final collapsedByDefault = entry['collapsed_by_default'];
      expect(
        collapsedByDefault == null ||
            collapsedByDefault is bool ||
            collapsedByDefault is String,
        isTrue,
      );

      final openTree = entry['opentree'];
      expect(openTree == null || openTree is YamlMap, isTrue);
      if (openTree is YamlMap) {
        final lineageIds = openTree['lineage_ids'];
        expect(lineageIds == null || lineageIds is YamlList, isTrue);
        final flags = openTree['flags'];
        expect(flags == null || flags is YamlList, isTrue);
      }
    }
  });

  test('clades use common_label and scientific_label schema', () {
    final document = loadYaml(File('data/clades.yaml').readAsStringSync());
    expect(document, isA<YamlList>());
    final clades = (document as YamlList).whereType<YamlMap>();

    for (final entry in clades) {
      final common = entry['common_label'];
      final scientific = entry['scientific_label'];
      expect(common, isA<String>());
      expect((common as String).trim(), isNotEmpty);
      expect(scientific, isA<String>());
      expect((scientific as String).trim(), isNotEmpty);
      expect(entry.containsKey('label'), isFalse);
    }
  });
}

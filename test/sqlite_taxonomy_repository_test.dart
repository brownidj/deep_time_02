import 'package:deep_time_2/domain/models/taxonomy_taxon.dart';
import 'package:deep_time_2/infra/db/taxonomy_database.dart';
import 'package:deep_time_2/infra/repositories/sqlite_taxonomy_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late TaxonomyDatabase database;
  late SqliteTaxonomyRepository repository;

  setUp(() async {
    database = await TaxonomyDatabase.openInMemory();
    repository = SqliteTaxonomyRepository(database);
  });

  tearDown(() {
    database.close();
  });

  test('upsert and fetch taxon by id preserves dates and source ids', () async {
    const taxon = TaxonomyTaxon(
      id: 'animalia',
      name: 'Animalia',
      rank: 'kingdom',
      commonName: 'animals',
      summary: 'Multicellular animals',
      sourceIds: TaxonomySourceIds(
        ottId: 691846,
        ncbiId: 33208,
        gbifId: 1,
        pbdbId: 123,
      ),
      synonyms: ['Metazoa'],
      fossilDate: TaxonomyFossilDate(
        firstAppearanceMa: 635.0,
        source: 'PBDB',
        confidence: 'high',
      ),
      molecularDate: TaxonomyMolecularDate(
        originMa: 770.0,
        originMinMa: 700.0,
        originMaxMa: 800.0,
        source: 'TimeTree',
      ),
      displayDate: TaxonomyDisplayDate(
        startMa: 770.0,
        basis: TaxonomyDateBasis.molecularClock,
      ),
      hasChildren: true,
      sourceBackbone: 'OpenTree',
      lastFetchedAt: '2026-06-06T00:00:00Z',
    );

    await repository.upsertTaxon(taxon);
    final stored = await repository.fetchTaxonById('animalia');

    expect(stored, isNotNull);
    expect(stored!.name, 'Animalia');
    expect(stored.rank, 'kingdom');
    expect(stored.commonName, 'animals');
    expect(stored.sourceIds.ottId, 691846);
    expect(stored.fossilDate.firstAppearanceMa, 635.0);
    expect(stored.molecularDate.originMaxMa, 800.0);
    expect(stored.displayDate.basis, TaxonomyDateBasis.molecularClock);
    expect(stored.synonyms, ['Metazoa']);
  });

  test('fetchChildren orders siblings by name', () async {
    await repository.upsertTaxa(const [
      TaxonomyTaxon(id: 'life', name: 'Life', rank: 'root', hasChildren: true),
      TaxonomyTaxon(
        id: 'eukaryota',
        parentId: 'life',
        name: 'Eukaryota',
        rank: 'domain',
      ),
      TaxonomyTaxon(
        id: 'archaea',
        parentId: 'life',
        name: 'Archaea',
        rank: 'domain',
      ),
    ]);

    final children = await repository.fetchChildren('life');

    expect(children.map((taxon) => taxon.id).toList(), [
      'archaea',
      'eukaryota',
    ]);
  });

  test('fetchLineage returns ancestors from root to selected taxon', () async {
    await repository.upsertTaxa(const [
      TaxonomyTaxon(id: 'life', name: 'Life', rank: 'root'),
      TaxonomyTaxon(
        id: 'eukaryota',
        parentId: 'life',
        name: 'Eukaryota',
        rank: 'domain',
      ),
      TaxonomyTaxon(
        id: 'animalia',
        parentId: 'eukaryota',
        name: 'Animalia',
        rank: 'kingdom',
      ),
    ]);

    final lineage = await repository.fetchLineage('animalia');

    expect(lineage.map((taxon) => taxon.id).toList(), [
      'life',
      'eukaryota',
      'animalia',
    ]);
  });

  test(
    'searchByName matches taxon names, common names, and synonyms',
    () async {
      await repository.upsertTaxa(const [
        TaxonomyTaxon(
          id: 'animalia',
          name: 'Animalia',
          rank: 'kingdom',
          commonName: 'animals',
          synonyms: ['Metazoa'],
        ),
        TaxonomyTaxon(
          id: 'fungi',
          name: 'Fungi',
          rank: 'kingdom',
          commonName: 'fungi',
        ),
      ]);

      final byName = await repository.searchByName('Animal');
      final byCommon = await repository.searchByName('animals');
      final bySynonym = await repository.searchByName('Metazoa');

      expect(byName.map((taxon) => taxon.id), contains('animalia'));
      expect(byCommon.map((taxon) => taxon.id), contains('animalia'));
      expect(bySynonym.map((taxon) => taxon.id), contains('animalia'));
    },
  );
}

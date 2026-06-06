import 'package:deep_time_2/domain/models/taxonomy_taxon.dart';
import 'package:deep_time_2/domain/repositories/taxonomy_repository.dart';
import 'package:deep_time_2/infra/db/taxonomy_database.dart';
import 'package:sqlite3/sqlite3.dart';

class SqliteTaxonomyRepository implements TaxonomyRepository {
  SqliteTaxonomyRepository(this._database);

  final TaxonomyDatabase _database;

  Database get _db => _database.raw;

  @override
  Future<TaxonomyTaxon?> fetchTaxonById(String id) async {
    final rows = _db.select(
      'SELECT * FROM taxonomy_taxa WHERE id = ? LIMIT 1',
      [id],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _mapTaxon(rows.first);
  }

  @override
  Future<TaxonomyTaxon?> fetchTaxonByOttId(int ottId) async {
    final rows = _db.select(
      'SELECT * FROM taxonomy_taxa WHERE ott_id = ? LIMIT 1',
      [ottId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _mapTaxon(rows.first);
  }

  @override
  Future<List<TaxonomyTaxon>> fetchRootTaxa() async {
    final rows = _db.select(
      'SELECT * FROM taxonomy_taxa WHERE parent_id IS NULL ORDER BY name',
    );
    return rows.map(_mapTaxon).toList(growable: false);
  }

  @override
  Future<List<TaxonomyTaxon>> fetchChildren(String parentTaxonId) async {
    final rows = _db.select(
      'SELECT * FROM taxonomy_taxa WHERE parent_id = ? ORDER BY name',
      [parentTaxonId],
    );
    return rows.map(_mapTaxon).toList(growable: false);
  }

  @override
  Future<List<TaxonomyTaxon>> fetchLineage(String taxonId) async {
    final lineage = <TaxonomyTaxon>[];
    var current = await fetchTaxonById(taxonId);
    final visited = <String>{};
    while (current != null && visited.add(current.id)) {
      lineage.add(current);
      final parentId = current.parentId;
      if (parentId == null || parentId.isEmpty) {
        break;
      }
      current = await fetchTaxonById(parentId);
    }
    return lineage.reversed.toList(growable: false);
  }

  @override
  Future<List<TaxonomyTaxon>> searchByName(
    String query, {
    int limit = 20,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return const [];
    }
    final rows = _db.select(
      '''
SELECT DISTINCT t.*
FROM taxonomy_taxa t
LEFT JOIN taxonomy_synonyms s ON s.taxon_id = t.id
WHERE t.name LIKE ? OR COALESCE(t.common_name, '') LIKE ? OR COALESCE(s.synonym, '') LIKE ?
ORDER BY t.name
LIMIT ?
''',
      ['%$normalized%', '%$normalized%', '%$normalized%', limit],
    );
    return rows.map(_mapTaxon).toList(growable: false);
  }

  @override
  Future<void> upsertTaxon(TaxonomyTaxon taxon) async {
    await upsertTaxa([taxon]);
  }

  @override
  Future<void> upsertTaxa(List<TaxonomyTaxon> taxa) async {
    if (taxa.isEmpty) {
      return;
    }
    _db.execute('BEGIN');
    try {
      final taxonStmt = _db.prepare('''
INSERT INTO taxonomy_taxa (
  id,
  parent_id,
  name,
  rank,
  common_name,
  summary,
  ott_id,
  ncbi_id,
  gbif_id,
  pbdb_id,
  fossil_first_ma,
  fossil_first_source,
  fossil_first_confidence,
  molecular_origin_ma,
  molecular_origin_min_ma,
  molecular_origin_max_ma,
  molecular_source,
  display_start_ma,
  display_start_basis,
  has_children,
  source_backbone,
  last_fetched_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(id) DO UPDATE SET
  parent_id = excluded.parent_id,
  name = excluded.name,
  rank = excluded.rank,
  common_name = excluded.common_name,
  summary = excluded.summary,
  ott_id = excluded.ott_id,
  ncbi_id = excluded.ncbi_id,
  gbif_id = excluded.gbif_id,
  pbdb_id = excluded.pbdb_id,
  fossil_first_ma = excluded.fossil_first_ma,
  fossil_first_source = excluded.fossil_first_source,
  fossil_first_confidence = excluded.fossil_first_confidence,
  molecular_origin_ma = excluded.molecular_origin_ma,
  molecular_origin_min_ma = excluded.molecular_origin_min_ma,
  molecular_origin_max_ma = excluded.molecular_origin_max_ma,
  molecular_source = excluded.molecular_source,
  display_start_ma = excluded.display_start_ma,
  display_start_basis = excluded.display_start_basis,
  has_children = excluded.has_children,
  source_backbone = excluded.source_backbone,
  last_fetched_at = excluded.last_fetched_at
''');
      final deleteSynonymsStmt = _db.prepare(
        'DELETE FROM taxonomy_synonyms WHERE taxon_id = ?',
      );
      final synonymStmt = _db.prepare(
        'INSERT OR IGNORE INTO taxonomy_synonyms (taxon_id, synonym) VALUES (?, ?)',
      );
      try {
        for (final taxon in taxa) {
          taxonStmt.execute([
            taxon.id,
            taxon.parentId,
            taxon.name,
            taxon.rank,
            taxon.commonName,
            taxon.summary,
            taxon.sourceIds.ottId,
            taxon.sourceIds.ncbiId,
            taxon.sourceIds.gbifId,
            taxon.sourceIds.pbdbId,
            taxon.fossilDate.firstAppearanceMa,
            taxon.fossilDate.source,
            taxon.fossilDate.confidence,
            taxon.molecularDate.originMa,
            taxon.molecularDate.originMinMa,
            taxon.molecularDate.originMaxMa,
            taxon.molecularDate.source,
            taxon.displayDate.startMa,
            taxon.displayDate.basis.id,
            taxon.hasChildren ? 1 : 0,
            taxon.sourceBackbone,
            taxon.lastFetchedAt,
          ]);
          deleteSynonymsStmt.execute([taxon.id]);
          for (final synonym in taxon.synonyms) {
            synonymStmt.execute([taxon.id, synonym]);
          }
        }
      } finally {
        taxonStmt.close();
        deleteSynonymsStmt.close();
        synonymStmt.close();
      }
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  @override
  Future<void> deleteTaxon(String id) async {
    final stmt = _db.prepare('DELETE FROM taxonomy_taxa WHERE id = ?');
    try {
      stmt.execute([id]);
    } finally {
      stmt.close();
    }
  }

  TaxonomyTaxon _mapTaxon(Row row) {
    final id = row['id'] as String;
    return TaxonomyTaxon(
      id: id,
      parentId: row['parent_id'] as String?,
      name: row['name'] as String,
      rank: row['rank'] as String,
      commonName: row['common_name'] as String?,
      summary: row['summary'] as String?,
      sourceIds: TaxonomySourceIds(
        ottId: (row['ott_id'] as num?)?.toInt(),
        ncbiId: (row['ncbi_id'] as num?)?.toInt(),
        gbifId: (row['gbif_id'] as num?)?.toInt(),
        pbdbId: (row['pbdb_id'] as num?)?.toInt(),
      ),
      synonyms: _fetchSynonyms(id),
      fossilDate: TaxonomyFossilDate(
        firstAppearanceMa: (row['fossil_first_ma'] as num?)?.toDouble(),
        source: row['fossil_first_source'] as String?,
        confidence: row['fossil_first_confidence'] as String?,
      ),
      molecularDate: TaxonomyMolecularDate(
        originMa: (row['molecular_origin_ma'] as num?)?.toDouble(),
        originMinMa: (row['molecular_origin_min_ma'] as num?)?.toDouble(),
        originMaxMa: (row['molecular_origin_max_ma'] as num?)?.toDouble(),
        source: row['molecular_source'] as String?,
      ),
      displayDate: TaxonomyDisplayDate(
        startMa: (row['display_start_ma'] as num?)?.toDouble(),
        basis: parseTaxonomyDateBasis(row['display_start_basis'] as String?),
      ),
      hasChildren: (row['has_children'] as num?)?.toInt() == 1,
      sourceBackbone: row['source_backbone'] as String?,
      lastFetchedAt: row['last_fetched_at'] as String?,
    );
  }

  List<String> _fetchSynonyms(String taxonId) {
    final rows = _db.select(
      'SELECT synonym FROM taxonomy_synonyms WHERE taxon_id = ? ORDER BY synonym',
      [taxonId],
    );
    return [
      for (final row in rows)
        if (row['synonym'] is String) row['synonym'] as String,
    ];
  }
}

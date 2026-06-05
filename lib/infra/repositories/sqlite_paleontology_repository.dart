import 'package:deep_time_2/domain/models/fossil_range.dart';
import 'package:deep_time_2/domain/models/paleontology_taxon.dart';
import 'package:deep_time_2/domain/repositories/paleontology_repository.dart';
import 'package:deep_time_2/infra/db/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

class SqlitePaleontologyRepository implements PaleontologyRepository {
  SqlitePaleontologyRepository(this._database);

  final AppDatabase _database;

  Database get _db => _database.raw;

  @override
  Future<int> insertTaxon(PaleontologyTaxon taxon) async {
    final stmt = _db.prepare(
      'INSERT INTO paleontology_taxa (name, summary) VALUES (?, ?)',
    );
    try {
      stmt.execute([taxon.name, taxon.summary]);
      return _db.lastInsertRowId;
    } finally {
      stmt.close();
    }
  }

  @override
  Future<PaleontologyTaxon?> fetchTaxonById(int id) async {
    final result = _db.select('SELECT * FROM paleontology_taxa WHERE id = ?', [
      id,
    ]);
    if (result.isEmpty) {
      return null;
    }
    return _mapTaxon(result.first);
  }

  @override
  Future<List<PaleontologyTaxon>> fetchAllTaxa() async {
    final result = _db.select('SELECT * FROM paleontology_taxa ORDER BY name');
    return result.map(_mapTaxon).toList();
  }

  @override
  Future<void> updateTaxon(PaleontologyTaxon taxon) async {
    final stmt = _db.prepare(
      'UPDATE paleontology_taxa SET name = ?, summary = ? WHERE id = ?',
    );
    try {
      stmt.execute([taxon.name, taxon.summary, taxon.id]);
    } finally {
      stmt.close();
    }
  }

  @override
  Future<void> deleteTaxon(int id) async {
    final stmt = _db.prepare('DELETE FROM paleontology_taxa WHERE id = ?');
    try {
      stmt.execute([id]);
    } finally {
      stmt.close();
    }
  }

  @override
  Future<int> insertRange(FossilRange range) async {
    final stmt = _db.prepare(
      'INSERT INTO fossil_ranges (taxon_id, start_ma, end_ma) VALUES (?, ?, ?)',
    );
    try {
      stmt.execute([range.taxonId, range.startMa, range.endMa]);
      return _db.lastInsertRowId;
    } finally {
      stmt.close();
    }
  }

  @override
  Future<List<FossilRange>> fetchRangesForTaxon(int taxonId) async {
    final result = _db.select(
      'SELECT * FROM fossil_ranges WHERE taxon_id = ? ORDER BY start_ma DESC',
      [taxonId],
    );
    return result.map(_mapRange).toList();
  }

  @override
  Future<List<FossilRange>> fetchRangesOverlapping(
    double startMa,
    double endMa,
  ) async {
    final result = _db.select(
      '''
SELECT * FROM fossil_ranges
WHERE start_ma >= ? AND end_ma <= ?
ORDER BY start_ma DESC
''',
      [endMa, startMa],
    );
    return result.map(_mapRange).toList();
  }

  @override
  Future<void> updateRange(FossilRange range) async {
    final stmt = _db.prepare(
      'UPDATE fossil_ranges SET taxon_id = ?, start_ma = ?, end_ma = ? WHERE id = ?',
    );
    try {
      stmt.execute([range.taxonId, range.startMa, range.endMa, range.id]);
    } finally {
      stmt.close();
    }
  }

  @override
  Future<void> deleteRange(int id) async {
    final stmt = _db.prepare('DELETE FROM fossil_ranges WHERE id = ?');
    try {
      stmt.execute([id]);
    } finally {
      stmt.close();
    }
  }

  PaleontologyTaxon _mapTaxon(Row row) {
    return PaleontologyTaxon(
      id: row['id'] as int,
      name: row['name'] as String,
      summary: row['summary'] as String,
    );
  }

  FossilRange _mapRange(Row row) {
    return FossilRange(
      id: row['id'] as int,
      taxonId: row['taxon_id'] as int,
      startMa: (row['start_ma'] as num).toDouble(),
      endMa: (row['end_ma'] as num).toDouble(),
    );
  }
}

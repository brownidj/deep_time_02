import 'package:deep_time_2/domain/models/geologic_division.dart';
import 'package:deep_time_2/domain/models/geologic_rank.dart';
import 'package:deep_time_2/domain/repositories/geologic_division_repository.dart';
import 'package:deep_time_2/infra/db/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

class SqliteGeologicDivisionRepository implements GeologicDivisionRepository {
  SqliteGeologicDivisionRepository(this._database);

  final AppDatabase _database;

  Database get _db => _database.raw;

  @override
  Future<int> insert(GeologicDivision division) async {
    final stmt = _db.prepare('''
INSERT INTO geologic_divisions (
  name,
  rank,
  start_ma,
  start_ma_uncertainty,
  end_ma,
  explanation,
  parent_id
) VALUES (?, ?, ?, ?, ?, ?, ?)
''');
    try {
      stmt.execute([
        division.name,
        division.rank.name,
        division.startMa,
        division.startMaUncertainty,
        division.endMa,
        division.explanation,
        division.parentId,
      ]);
      return _db.lastInsertRowId;
    } finally {
      stmt.close();
    }
  }

  @override
  Future<GeologicDivision?> fetchById(int id) async {
    final result = _db.select('SELECT * FROM geologic_divisions WHERE id = ?', [
      id,
    ]);
    if (result.isEmpty) {
      return null;
    }
    return _mapRow(result.first);
  }

  @override
  Future<List<GeologicDivision>> fetchAll() async {
    final result = _db.select(
      'SELECT * FROM geologic_divisions ORDER BY start_ma DESC',
    );
    return result.map(_mapRow).toList();
  }

  @override
  Future<void> update(GeologicDivision division) async {
    final stmt = _db.prepare('''
UPDATE geologic_divisions
SET name = ?, rank = ?, start_ma = ?, start_ma_uncertainty = ?, end_ma = ?, explanation = ?, parent_id = ?
WHERE id = ?
''');
    try {
      stmt.execute([
        division.name,
        division.rank.name,
        division.startMa,
        division.startMaUncertainty,
        division.endMa,
        division.explanation,
        division.parentId,
        division.id,
      ]);
    } finally {
      stmt.close();
    }
  }

  @override
  Future<void> delete(int id) async {
    final stmt = _db.prepare('DELETE FROM geologic_divisions WHERE id = ?');
    try {
      stmt.execute([id]);
    } finally {
      stmt.close();
    }
  }

  GeologicDivision _mapRow(Row row) {
    return GeologicDivision(
      id: row['id'] as int,
      name: row['name'] as String,
      rank: _rankFromString(row['rank'] as String),
      startMa: (row['start_ma'] as num).toDouble(),
      startMaUncertainty: (row['start_ma_uncertainty'] as num?)?.toDouble(),
      endMa: (row['end_ma'] as num).toDouble(),
      explanation: row['explanation'] as String?,
      parentId: row['parent_id'] as int?,
    );
  }

  GeologicRank _rankFromString(String value) {
    return GeologicRank.values.firstWhere(
      (rank) => rank.name == value,
      orElse: () => GeologicRank.period,
    );
  }
}

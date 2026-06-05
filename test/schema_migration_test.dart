import 'package:deep_time_2/infra/db/schema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('ensureColumns rebuilds legacy tables with date checks and preserves data', () {
    final db = sqlite3.openInMemory();
    addTearDown(db.close);

    db.execute('PRAGMA foreign_keys = ON');
    db.execute('''
CREATE TABLE geologic_divisions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  rank TEXT NOT NULL,
  start_ma REAL NOT NULL,
  end_ma REAL NOT NULL,
  parent_id INTEGER,
  FOREIGN KEY (parent_id) REFERENCES geologic_divisions(id) ON DELETE SET NULL
);
''');
    db.execute('''
CREATE TABLE paleontology_taxa (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  summary TEXT NOT NULL
);
''');
    db.execute('''
CREATE TABLE fossil_ranges (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  taxon_id INTEGER NOT NULL,
  start_ma REAL NOT NULL,
  end_ma REAL NOT NULL,
  FOREIGN KEY (taxon_id) REFERENCES paleontology_taxa(id) ON DELETE CASCADE
);
''');
    db.execute(
      'CREATE INDEX idx_fossil_ranges_span ON fossil_ranges(start_ma, end_ma)',
    );

    db.execute(
      "INSERT INTO geologic_divisions (id, name, rank, start_ma, end_ma, parent_id) VALUES (1, 'Phanerozoic', 'eon', 541.0, 0.0, NULL)",
    );
    db.execute(
      "INSERT INTO geologic_divisions (id, name, rank, start_ma, end_ma, parent_id) VALUES (2, 'Mesozoic', 'era', 252.0, 66.0, 1)",
    );
    db.execute(
      "INSERT INTO paleontology_taxa (id, name, summary) VALUES (10, 'Test taxon', 'Summary')",
    );
    db.execute(
      'INSERT INTO fossil_ranges (id, taxon_id, start_ma, end_ma) VALUES (20, 10, 120.0, 80.0)',
    );

    AppDatabaseSchema.ensureColumns(db);

    final geoColumns = db.select('PRAGMA table_info(geologic_divisions)');
    final geoNames = geoColumns.map((row) => row['name'] as String).toSet();
    expect(geoNames.contains('start_ma_uncertainty'), isTrue);
    expect(geoNames.contains('explanation'), isTrue);

    final geoSql = _tableSql(db, 'geologic_divisions');
    expect(geoSql.contains('CHECK (start_ma >= 0)'), isTrue);
    expect(geoSql.contains('CHECK (end_ma >= 0)'), isTrue);
    expect(geoSql.contains('CHECK (start_ma >= end_ma)'), isTrue);
    expect(
      geoSql.contains(
        'CHECK (start_ma_uncertainty IS NULL OR start_ma_uncertainty >= 0)',
      ),
      isTrue,
    );

    final rangesSql = _tableSql(db, 'fossil_ranges');
    expect(rangesSql.contains('CHECK (start_ma >= 0)'), isTrue);
    expect(rangesSql.contains('CHECK (end_ma >= 0)'), isTrue);
    expect(rangesSql.contains('CHECK (start_ma >= end_ma)'), isTrue);

    final divisions = db.select(
      'SELECT id, name, rank, start_ma, end_ma, parent_id FROM geologic_divisions ORDER BY id',
    );
    expect(divisions.length, 2);
    expect(divisions[0]['id'], 1);
    expect(divisions[0]['name'], 'Phanerozoic');
    expect(divisions[1]['id'], 2);
    expect(divisions[1]['parent_id'], 1);

    final ranges = db.select(
      'SELECT id, taxon_id, start_ma, end_ma FROM fossil_ranges ORDER BY id',
    );
    expect(ranges.length, 1);
    expect(ranges.first['id'], 20);
    expect(ranges.first['taxon_id'], 10);

    final indexRows = db.select(
      "SELECT name FROM sqlite_master WHERE type = 'index' AND name = 'idx_fossil_ranges_span'",
    );
    expect(indexRows, isNotEmpty);
  });

  test('ensureColumns rolls back when legacy data violates new date checks', () {
    final db = sqlite3.openInMemory();
    addTearDown(db.close);

    db.execute('PRAGMA foreign_keys = ON');
    db.execute('''
CREATE TABLE geologic_divisions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  rank TEXT NOT NULL,
  start_ma REAL NOT NULL,
  end_ma REAL NOT NULL,
  parent_id INTEGER,
  FOREIGN KEY (parent_id) REFERENCES geologic_divisions(id) ON DELETE SET NULL
);
''');
    db.execute('''
CREATE TABLE paleontology_taxa (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  summary TEXT NOT NULL
);
''');
    db.execute('''
CREATE TABLE fossil_ranges (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  taxon_id INTEGER NOT NULL,
  start_ma REAL NOT NULL,
  end_ma REAL NOT NULL,
  FOREIGN KEY (taxon_id) REFERENCES paleontology_taxa(id) ON DELETE CASCADE
);
''');
    db.execute(
      'CREATE INDEX idx_fossil_ranges_span ON fossil_ranges(start_ma, end_ma)',
    );

    // Invalid legacy date range: start_ma < end_ma.
    db.execute(
      "INSERT INTO geologic_divisions (id, name, rank, start_ma, end_ma, parent_id) VALUES (1, 'Invalid', 'era', 10.0, 20.0, NULL)",
    );

    expect(() => AppDatabaseSchema.ensureColumns(db), throwsA(isA<Object>()));

    // Original legacy table and row should remain intact after rollback.
    final rows = db.select(
      'SELECT id, name, start_ma, end_ma FROM geologic_divisions',
    );
    expect(rows.length, 1);
    expect(rows.first['id'], 1);
    expect(rows.first['start_ma'], 10.0);
    expect(rows.first['end_ma'], 20.0);

    final geoSql = _tableSql(db, 'geologic_divisions');
    expect(geoSql.contains('CHECK (start_ma >= end_ma)'), isFalse);

    final tempRows = db.select(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'geologic_divisions_new'",
    );
    expect(tempRows, isEmpty);
  });
}

String _tableSql(Database db, String table) {
  final rows = db.select(
    "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = ? LIMIT 1",
    [table],
  );
  if (rows.isEmpty) {
    return '';
  }
  return (rows.first['sql'] as String? ?? '');
}

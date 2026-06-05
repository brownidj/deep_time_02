import 'package:sqlite3/sqlite3.dart';

class AppDatabaseSchema {
  const AppDatabaseSchema._();

  static void create(Database db) {
    db.execute('''
CREATE TABLE IF NOT EXISTS geologic_divisions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  rank TEXT NOT NULL,
  start_ma REAL NOT NULL,
  start_ma_uncertainty REAL,
  end_ma REAL NOT NULL,
  explanation TEXT,
  parent_id INTEGER,
  CHECK (start_ma >= 0),
  CHECK (end_ma >= 0),
  CHECK (start_ma >= end_ma),
  CHECK (start_ma_uncertainty IS NULL OR start_ma_uncertainty >= 0),
  FOREIGN KEY (parent_id) REFERENCES geologic_divisions(id) ON DELETE SET NULL
);
''');

    db.execute('''
CREATE TABLE IF NOT EXISTS paleontology_taxa (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  summary TEXT NOT NULL
);
''');

    db.execute('''
CREATE TABLE IF NOT EXISTS fossil_ranges (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  taxon_id INTEGER NOT NULL,
  start_ma REAL NOT NULL,
  end_ma REAL NOT NULL,
  CHECK (start_ma >= 0),
  CHECK (end_ma >= 0),
  CHECK (start_ma >= end_ma),
  FOREIGN KEY (taxon_id) REFERENCES paleontology_taxa(id) ON DELETE CASCADE
);
''');

    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_fossil_ranges_span ON fossil_ranges(start_ma, end_ma)',
    );

    db.execute('''
CREATE TABLE IF NOT EXISTS app_meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
''');
  }

  static void ensureColumns(Database db) {
    final columns = db.select('PRAGMA table_info(geologic_divisions)');
    final names = columns.map((row) => row['name'] as String).toSet();
    if (!names.contains('start_ma_uncertainty')) {
      db.execute(
        'ALTER TABLE geologic_divisions ADD COLUMN start_ma_uncertainty REAL',
      );
    }
    if (!names.contains('explanation')) {
      db.execute('ALTER TABLE geologic_divisions ADD COLUMN explanation TEXT');
    }
    _ensureDateConstraints(db);
  }

  static void _ensureDateConstraints(Database db) {
    final divisionsSql = _tableSql(db, 'geologic_divisions');
    final rangesSql = _tableSql(db, 'fossil_ranges');
    final divisionsHasChecks =
        divisionsSql.contains('CHECK (start_ma >= 0)') &&
        divisionsSql.contains('CHECK (end_ma >= 0)') &&
        divisionsSql.contains('CHECK (start_ma >= end_ma)') &&
        divisionsSql.contains(
          'CHECK (start_ma_uncertainty IS NULL OR start_ma_uncertainty >= 0)',
        );
    final rangesHasChecks =
        rangesSql.contains('CHECK (start_ma >= 0)') &&
        rangesSql.contains('CHECK (end_ma >= 0)') &&
        rangesSql.contains('CHECK (start_ma >= end_ma)');

    if (divisionsHasChecks && rangesHasChecks) {
      return;
    }

    // SQLite cannot add CHECK constraints via ALTER TABLE, so rebuild.
    db.execute('PRAGMA foreign_keys = OFF');
    db.execute('BEGIN');
    try {
      if (!divisionsHasChecks) {
        _rebuildGeologicDivisionsWithChecks(db);
      }
      if (!rangesHasChecks) {
        _rebuildFossilRangesWithChecks(db);
      }
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    } finally {
      db.execute('PRAGMA foreign_keys = ON');
    }
  }

  static String _tableSql(Database db, String table) {
    final rows = db.select(
      "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = ? LIMIT 1",
      [table],
    );
    if (rows.isEmpty) {
      return '';
    }
    return (rows.first['sql'] as String? ?? '').replaceAll('\n', ' ');
  }

  static void _rebuildGeologicDivisionsWithChecks(Database db) {
    db.execute('''
CREATE TABLE geologic_divisions_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  rank TEXT NOT NULL,
  start_ma REAL NOT NULL,
  start_ma_uncertainty REAL,
  end_ma REAL NOT NULL,
  explanation TEXT,
  parent_id INTEGER,
  CHECK (start_ma >= 0),
  CHECK (end_ma >= 0),
  CHECK (start_ma >= end_ma),
  CHECK (start_ma_uncertainty IS NULL OR start_ma_uncertainty >= 0),
  FOREIGN KEY (parent_id) REFERENCES geologic_divisions_new(id) ON DELETE SET NULL
);
''');
    db.execute('''
INSERT INTO geologic_divisions_new (
  id,
  name,
  rank,
  start_ma,
  start_ma_uncertainty,
  end_ma,
  explanation,
  parent_id
)
SELECT
  id,
  name,
  rank,
  start_ma,
  start_ma_uncertainty,
  end_ma,
  explanation,
  parent_id
FROM geologic_divisions;
''');
    db.execute('DROP TABLE geologic_divisions');
    db.execute('ALTER TABLE geologic_divisions_new RENAME TO geologic_divisions');
  }

  static void _rebuildFossilRangesWithChecks(Database db) {
    db.execute('''
CREATE TABLE fossil_ranges_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  taxon_id INTEGER NOT NULL,
  start_ma REAL NOT NULL,
  end_ma REAL NOT NULL,
  CHECK (start_ma >= 0),
  CHECK (end_ma >= 0),
  CHECK (start_ma >= end_ma),
  FOREIGN KEY (taxon_id) REFERENCES paleontology_taxa(id) ON DELETE CASCADE
);
''');
    db.execute('''
INSERT INTO fossil_ranges_new (
  id,
  taxon_id,
  start_ma,
  end_ma
)
SELECT
  id,
  taxon_id,
  start_ma,
  end_ma
FROM fossil_ranges;
''');
    db.execute('DROP TABLE fossil_ranges');
    db.execute('ALTER TABLE fossil_ranges_new RENAME TO fossil_ranges');
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_fossil_ranges_span ON fossil_ranges(start_ma, end_ma)',
    );
  }
}

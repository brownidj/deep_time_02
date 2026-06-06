import 'package:sqlite3/sqlite3.dart';

class TaxonomyDatabaseSchema {
  const TaxonomyDatabaseSchema._();

  static void create(Database db) {
    db.execute('''
CREATE TABLE IF NOT EXISTS taxonomy_taxa (
  id TEXT PRIMARY KEY,
  parent_id TEXT,
  name TEXT NOT NULL,
  rank TEXT NOT NULL,
  common_name TEXT,
  summary TEXT,
  ott_id INTEGER,
  ncbi_id INTEGER,
  gbif_id INTEGER,
  pbdb_id INTEGER,
  fossil_first_ma REAL,
  fossil_first_source TEXT,
  fossil_first_confidence TEXT,
  molecular_origin_ma REAL,
  molecular_origin_min_ma REAL,
  molecular_origin_max_ma REAL,
  molecular_source TEXT,
  display_start_ma REAL,
  display_start_basis TEXT NOT NULL DEFAULT 'unknown',
  has_children INTEGER NOT NULL DEFAULT 0,
  source_backbone TEXT,
  last_fetched_at TEXT,
  CHECK (fossil_first_ma IS NULL OR fossil_first_ma >= 0),
  CHECK (molecular_origin_ma IS NULL OR molecular_origin_ma >= 0),
  CHECK (molecular_origin_min_ma IS NULL OR molecular_origin_min_ma >= 0),
  CHECK (molecular_origin_max_ma IS NULL OR molecular_origin_max_ma >= 0),
  CHECK (display_start_ma IS NULL OR display_start_ma >= 0),
  FOREIGN KEY (parent_id) REFERENCES taxonomy_taxa(id) ON DELETE SET NULL
);
''');

    db.execute('''
CREATE TABLE IF NOT EXISTS taxonomy_synonyms (
  taxon_id TEXT NOT NULL,
  synonym TEXT NOT NULL,
  PRIMARY KEY (taxon_id, synonym),
  FOREIGN KEY (taxon_id) REFERENCES taxonomy_taxa(id) ON DELETE CASCADE
);
''');

    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_taxonomy_parent ON taxonomy_taxa(parent_id, name)',
    );
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_taxonomy_name ON taxonomy_taxa(name)',
    );
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_taxonomy_ott ON taxonomy_taxa(ott_id)',
    );
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_taxonomy_synonym ON taxonomy_synonyms(synonym)',
    );
  }
}

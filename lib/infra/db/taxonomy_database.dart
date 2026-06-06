import 'package:deep_time_2/app/app_debug.dart';
import 'package:deep_time_2/infra/db/taxonomy_schema.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class TaxonomyDatabase {
  TaxonomyDatabase._(this._db);

  final Database _db;

  static Future<TaxonomyDatabase> open() async {
    final supportDir = await getApplicationSupportDirectory();
    await supportDir.create(recursive: true);
    final dbPath = path.join(supportDir.path, 'taxonomy.sqlite');
    final db = sqlite3.open(dbPath);
    final taxonomyDb = TaxonomyDatabase._(db);
    taxonomyDb._initialize();
    return taxonomyDb;
  }

  static Future<TaxonomyDatabase> openInMemory() async {
    final db = sqlite3.openInMemory();
    final taxonomyDb = TaxonomyDatabase._(db);
    taxonomyDb._initialize();
    return taxonomyDb;
  }

  void _initialize() {
    _db.execute('PRAGMA foreign_keys = ON');
    TaxonomyDatabaseSchema.create(_db);
  }

  Database get raw => _db;

  void close() {
    try {
      _db.close();
    } catch (error, stackTrace) {
      AppDebug.log(
        'Failed to close taxonomy database',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

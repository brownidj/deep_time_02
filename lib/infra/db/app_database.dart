import 'package:deep_time_2/app/app_debug.dart';
import 'package:deep_time_2/infra/db/schema.dart';
import 'package:deep_time_2/infra/db/timeline_seed.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;

  static Future<AppDatabase> open() async {
    final supportDir = await getApplicationSupportDirectory();
    await supportDir.create(recursive: true);
    final dbPath = path.join(supportDir.path, 'geologic_timeline.db');
    final db = sqlite3.open(dbPath);
    final appDb = AppDatabase._(db);
    await appDb._initialize();
    return appDb;
  }

  static Future<AppDatabase> openInMemory({bool seed = false}) async {
    final db = sqlite3.openInMemory();
    final appDb = AppDatabase._(db);
    await appDb._initialize(seed: seed);
    return appDb;
  }

  Future<void> _initialize({bool seed = true}) async {
    _db.execute('PRAGMA foreign_keys = ON');
    AppDatabaseSchema.create(_db);
    AppDatabaseSchema.ensureColumns(_db);
    if (seed) {
      await TimelineSeeder.seedIfEmpty(_db);
    }
  }

  Database get raw => _db;

  void close() {
    try {
      _db.close();
    } catch (error, stackTrace) {
      AppDebug.log(
        'Failed to close database',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

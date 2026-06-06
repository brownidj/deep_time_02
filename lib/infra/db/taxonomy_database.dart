import 'dart:io';

import 'package:deep_time_2/app/app_debug.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:deep_time_2/infra/db/taxonomy_schema.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class TaxonomyDatabase {
  TaxonomyDatabase._(this._db);

  static const String _assetPath = 'data/taxonomy.sqlite';
  final Database _db;

  static Future<TaxonomyDatabase> open() async {
    final dbFile = await _materializeAssetDatabase();
    final db = sqlite3.open(dbFile.path);
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

  static Future<File> _materializeAssetDatabase() async {
    final supportDir = await getApplicationSupportDirectory();
    await supportDir.create(recursive: true);
    final file = File(path.join(supportDir.path, path.basename(_assetPath)));
    if (file.existsSync()) {
      return file;
    }
    try {
      final bytes = await rootBundle.load(_assetPath);
      await file.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
      return file;
    } on FlutterError {
      // Fall back to an empty on-device database when no bundled asset exists.
      return file;
    }
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

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('progressive clade detail DB has about 40 dinosauria descendants', () {
    final dbFile = File('data/clades_detail_progressive_opentree.sqlite');
    expect(dbFile.existsSync(), isTrue);

    final db = sqlite3.open(dbFile.path);
    try {
      final rows = db.select(
        'SELECT COUNT(*) AS count FROM clade_detail_roots WHERE root_id = ?',
        ['dinosauria'],
      );
      final count = (rows.first['count'] as int?) ?? 0;
      expect(
        count,
        greaterThanOrEqualTo(40),
        reason: 'Expected dinosauria subtree detail to be at least 40 clades.',
      );
    } finally {
      db.close();
    }
  });

  test('app dependencies use progressive clade detail DB asset', () {
    final source = File('lib/app/app_dependencies.dart').readAsStringSync();
    expect(
      source.contains('data/clades_detail_progressive_opentree.sqlite'),
      isTrue,
      reason: 'Timeline should load clade detail from the progressive OpenTree DB.',
    );
  });
}

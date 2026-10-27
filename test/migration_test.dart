import 'dart:io';

import 'package:couture/data/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('une base v1 est migrée avec patron et date de livraison', () async {
    sqfliteFfiInit();
    final tempDir = await Directory.systemTemp.createTemp('couture_migration_');
    final path = p.join(tempDir.path, 'v1.db');

    final legacy = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE clients (
              id TEXT PRIMARY KEY,
              full_name TEXT NOT NULL,
              phone TEXT NOT NULL DEFAULT '',
              notes TEXT NOT NULL DEFAULT '',
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE sheets (
              id TEXT PRIMARY KEY,
              client_id TEXT NOT NULL,
              title TEXT NOT NULL,
              garment_type TEXT NOT NULL,
              measurements TEXT NOT NULL DEFAULT '{}',
              custom_measurements TEXT NOT NULL DEFAULT '[]',
              fabric_photos TEXT NOT NULL DEFAULT '[]',
              model_photos TEXT NOT NULL DEFAULT '[]',
              notes TEXT NOT NULL DEFAULT '',
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              FOREIGN KEY (client_id) REFERENCES clients (id) ON DELETE CASCADE
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_sheets_client ON sheets (client_id, updated_at)',
          );
        },
      ),
    );

    final now = DateTime(2026, 3, 12).millisecondsSinceEpoch;
    await legacy.insert('clients', {
      'id': 'client_1',
      'full_name': 'Awa Diop',
      'created_at': now,
      'updated_at': now,
    });
    await legacy.insert('sheets', {
      'id': 'sheet_1',
      'client_id': 'client_1',
      'title': 'Robe',
      'garment_type': 'Robe',
      'created_at': now,
      'updated_at': now,
    });
    await legacy.close();

    AppDatabase.instance.configureForTests(
      path: path,
      factory: databaseFactoryFfi,
    );
    final db = await AppDatabase.instance.database;

    final columns = await db.rawQuery('PRAGMA table_info(sheets)');
    final names = columns.map((row) => row['name']).toSet();
    expect(names, containsAll(['pattern_id', 'delivery_date']));

    final rows = await db.query('sheets', where: 'id = ?', whereArgs: ['sheet_1']);
    expect(rows.single['pattern_id'], isNull);
    expect(rows.single['delivery_date'], isNull);

    await AppDatabase.instance.close();
    await tempDir.delete(recursive: true);
  });
}

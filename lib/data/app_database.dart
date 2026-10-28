import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Accès à la base SQLite locale de l'application.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static const int _version = 3;

  Database? _database;
  Future<Database>? _opening;
  DatabaseFactory? _factoryOverride;
  String? _pathOverride;

  Future<Database> get database => _ensureOpen();

  Future<Database> _ensureOpen() async {
    final existing = _database;
    if (existing != null && existing.isOpen) return existing;

    final pending = _opening;
    if (pending != null) return pending;

    final opening = _open();
    _opening = opening;
    try {
      final db = await opening;
      _database = db;
      return db;
    } finally {
      _opening = null;
    }
  }

  /// Permet aux tests d'utiliser une base en mémoire.
  void configureForTests({String? path, DatabaseFactory? factory}) {
    _pathOverride = path;
    _factoryOverride = factory;
    _database = null;
    _opening = null;
  }

  Future<Database> _open() async {
    final factory = _factoryOverride ?? databaseFactory;
    final path = _pathOverride ?? p.join(await factory.getDatabasesPath(), 'couture.db');

    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute('''\
            CREATE TABLE clients (
              id TEXT PRIMARY KEY,
              full_name TEXT NOT NULL,
              phone TEXT NOT NULL DEFAULT '',
              notes TEXT NOT NULL DEFAULT '',
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''\
            CREATE TABLE sheets (
              id TEXT PRIMARY KEY,
              client_id TEXT NOT NULL,
              title TEXT NOT NULL,
              garment_type TEXT NOT NULL,
              pattern_id TEXT,
              delivery_date INTEGER,
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
          await db.execute('''\
            CREATE TABLE patterns (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              tagline TEXT,
              description TEXT,
              garment_type TEXT NOT NULL,
              silhouette TEXT,
              key_measurements TEXT NOT NULL DEFAULT '[]',
              fabric TEXT,
              tip TEXT,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_sheets_client ON sheets (client_id, updated_at)',
          );
          await db.execute(
            'CREATE INDEX idx_sheets_delivery ON sheets (delivery_date)',
          );
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('ALTER TABLE sheets ADD COLUMN pattern_id TEXT');
            await db.execute(
              'ALTER TABLE sheets ADD COLUMN delivery_date INTEGER',
            );
            await db.execute(
              'CREATE INDEX idx_sheets_delivery ON sheets (delivery_date)',
            );
          }
          // oldVersion < 3: la table patterns est déjà créée dans onCreate
        },
      ),
    );
    return db;
  }

  /// Permet aux tests d'utiliser une base en mémoire.
  Future<void> close() async {
    await _database?.close();
    _database = null;
    _opening = null;
  }
}
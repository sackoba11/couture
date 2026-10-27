import 'package:sqflite/sqflite.dart';

import '../models/client.dart';
import '../models/measurement_sheet.dart';
import 'app_database.dart';
import 'media_storage.dart';

/// Point d'entrée unique pour lire et enregistrer les données de l'atelier.
class CoutureRepository {
  CoutureRepository._();

  static final CoutureRepository instance = CoutureRepository._();

  Future<Database> get _db => AppDatabase.instance.database;

  // ---------------------------------------------------------------- Clients

  Future<List<ClientOverview>> clients({String query = ''}) async {
    final db = await _db;
    final search = query.trim();
    final rows = await db.rawQuery(
      '''
      SELECT c.*, COUNT(s.id) AS sheet_count, MAX(s.updated_at) AS last_sheet_at
      FROM clients c
      LEFT JOIN sheets s ON s.client_id = c.id
      WHERE (? = '' OR c.full_name LIKE ? OR c.phone LIKE ?)
      GROUP BY c.id
      ORDER BY COALESCE(MAX(s.updated_at), c.updated_at) DESC
      ''',
      [search, '%$search%', '%$search%'],
    );
    return rows.map(ClientOverview.fromMap).toList();
  }

  Future<Client?> client(String id) async {
    final db = await _db;
    final rows = await db.query('clients', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Client.fromMap(rows.first);
  }

  Future<void> saveClient(Client client) async {
    final db = await _db;
    await _upsert(db, 'clients', client.toMap());
  }

  Future<int> countClients() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM clients');
    return (result.first['total'] as int?) ?? 0;
  }

  Future<void> deleteClient(String clientId) async {
    final db = await _db;
    final sheets = await db.query(
      'sheets',
      columns: ['id'],
      where: 'client_id = ?',
      whereArgs: [clientId],
    );
    await db.delete('clients', where: 'id = ?', whereArgs: [clientId]);
    for (final row in sheets) {
      await _deleteMediaFolder(row['id']! as String);
    }
  }

  // ----------------------------------------------------------------- Fiches

  Future<List<MeasurementSheet>> sheetsForClient(String clientId) async {
    final db = await _db;
    final rows = await db.query(
      'sheets',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'updated_at DESC',
    );
    return rows.map(MeasurementSheet.fromMap).toList();
  }

  Future<MeasurementSheet?> sheet(String id) async {
    final db = await _db;
    final rows = await db.query('sheets', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return MeasurementSheet.fromMap(rows.first);
  }

  Future<void> saveSheet(MeasurementSheet sheet) async {
    final db = await _db;
    await _upsert(db, 'sheets', sheet.toMap());
  }

  /// Insertion ou mise à jour sans `REPLACE` : un `REPLACE` supprimerait
  /// la ligne puis la recréerait, ce qui effacerait les fiches du client
  /// via la clé étrangère en cascade.
  Future<void> _upsert(
    Database db,
    String table,
    Map<String, Object?> values,
  ) async {
    await db.transaction((txn) async {
      final updated = await txn.update(
        table,
        values,
        where: 'id = ?',
        whereArgs: [values['id']],
      );
      if (updated == 0) {
        await txn.insert(table, values);
      }
    });
  }

  Future<void> deleteSheet(MeasurementSheet sheet) async {
    final db = await _db;
    await db.delete('sheets', where: 'id = ?', whereArgs: [sheet.id]);
    await _deleteMediaFolder(sheet.id);
  }

  /// Le nettoyage des photos ne doit jamais empêcher la suppression des
  /// données : en cas d'échec, les fichiers restent simplement orphelins.
  Future<void> _deleteMediaFolder(String sheetId) async {
    try {
      await MediaStorage.deleteSheetFolder(sheetId);
    } on Exception {
      // Dossier inaccessible ou déjà supprimé.
    }
  }
}

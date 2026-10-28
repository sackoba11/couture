import 'package:sqflite/sqflite.dart';

import '../models/client.dart';
import '../models/measurement_sheet.dart';
import '../models/pattern.dart';
import '../utils/formatters.dart';
import 'app_database.dart';
import 'media_storage.dart';

/// Une fiche dont la livraison approche, avec son client.
class DeliveryOverview {
  const DeliveryOverview({required this.sheet, required this.client});

  final MeasurementSheet sheet;
  final Client client;

  DateTime get deliveryDate => sheet.deliveryDate!;

  int daysLeft({DateTime? now}) => daysUntil(deliveryDate, now: now);

  DeliveryStatus status({DateTime? now}) =>
      deliveryStatus(deliveryDate, now: now);
}

/// Point d'entrée unique pour lire et enregistrer les données de l'atelier.
class CoutureRepository {
  CoutureRepository._();

  static final CoutureRepository instance = CoutureRepository._();

  Future<Database> get _db => AppDatabase.instance.database;

  // Cache des patrons chargés depuis la DB (initialisé par ensurePatternsLoaded).
  Map<String, SewingPattern>? _patternsById;

  /// Futur qui charge les patrons depuis la DB au premier besoin.
  Future<Map<String, SewingPattern>> ensurePatternsLoaded() async {
    if (_patternsById != null) return _patternsById!;
    final db = await _db;
    final loaded = await _loadPatternsFromDb(db);
    _patternsById = loaded;
    setCurrentPatterns(loaded);
    return loaded;
  }

  Future<Map<String, SewingPattern>> _loadPatternsFromDb(Database db) async {
    final rows = await db.query(AppDatabase.tablePatterns);
    final Map<String, SewingPattern> patterns = {};
    for (final row in rows) {
      final pattern = SewingPattern.fromMap(row);
      patterns[pattern.id] = pattern;
    }
    // Fusionner avec les patrons par défaut (DB l'emporte si conflit d'ID)
    for (final defaultPattern in kDefaultMalianPatterns) {
      if (!patterns.containsKey(defaultPattern.id)) {
        patterns[defaultPattern.id] = defaultPattern;
      }
    }
    return patterns;
  }

  /// Enregistrer un nouveau patron dans la base de données.
  Future<void> savePattern(SewingPattern pattern) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert(AppDatabase.tablePatterns, pattern.toMap());
    });
    // Invalider le cache
    _patternsById = null;
  }

  /// Mettre à jour un patron existant dans la base de données.
  Future<void> updatePattern(SewingPattern pattern) async {
    final db = await _db;
    await db.update(
      AppDatabase.tablePatterns,
      pattern.toMap(),
      where: 'id = ?',
      whereArgs: [pattern.id],
    );
    // Invalider le cache
    _patternsById = null;
  }

  /// Supprimer un patron de la base de données (seulement les patrons personnalisés).
  Future<void> deletePattern(String patternId) async {
    // Ne pas supprimer les patrons par défaut
    final defaultIds = kDefaultMalianPatterns.map((p) => p.id).toList();
    if (defaultIds.contains(patternId)) return;

    final db = await _db;
    await db.delete(
      AppDatabase.tablePatterns,
      where: 'id = ?',
      whereArgs: [patternId],
    );
    // Invalider le cache
    _patternsById = null;
  }

  /// Obtenir tous les patrons (patrons par défaut + utilisateur créé).
  Future<Map<String, SewingPattern>> getAllPatterns() async {
    return await ensurePatternsLoaded();
  }

  /// Vérifier si un identifiant de patron existe.
  Future<bool> patternExists(String patternId) async {
    final patterns = await ensurePatternsLoaded();
    return patterns.containsKey(patternId);
  }

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

  // ------------------------------------------------------------ Livraisons

  /// Fiches dont la date de livraison est proche : les retards récents
  /// (7 derniers jours) puis les [withinDays] prochains jours, de la plus
  /// ancienne à la plus lointaine.
  Future<List<DeliveryOverview>> upcomingDeliveries({
    int withinDays = 21,
    int limit = 8,
  }) async {
    final db = await _db;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 7));
    final end = today.add(Duration(days: withinDays + 1));

    final rows = await db.rawQuery(
      '''
      SELECT s.*,
             c.full_name AS client_name,
             c.phone AS client_phone,
             c.notes AS client_notes,
             c.created_at AS client_created_at,
             c.updated_at AS client_updated_at
      FROM sheets s
      INNER JOIN clients c ON c.id = s.client_id
      WHERE s.delivery_date IS NOT NULL
        AND s.delivery_date >= ?
        AND s.delivery_date < ?
      ORDER BY s.delivery_date ASC
      LIMIT ?
      ''',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch, limit],
    );

    return rows.map((row) {
      final client = Client(
        id: row['client_id']! as String,
        fullName: row['client_name']! as String,
        phone: (row['client_phone'] as String?) ?? '',
        notes: (row['client_notes'] as String?) ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          row['client_created_at']! as int,
        ),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          row['client_updated_at']! as int,
        ),
      );
      return DeliveryOverview(
        sheet: MeasurementSheet.fromMap(row),
        client: client,
      );
    }).toList();
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

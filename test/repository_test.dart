import 'dart:io';

import 'package:couture/data/app_database.dart';
import 'package:couture/data/couture_repository.dart';
import 'package:couture/models/client.dart';
import 'package:couture/models/measurement_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repository = CoutureRepository.instance;
  late Directory tempDir;

  Client buildClient({String name = 'Awa Diop'}) {
    final now = DateTime(2026, 3, 12, 9, 30);
    return Client(
      id: 'client_1',
      fullName: name,
      phone: '77 123 45 67',
      createdAt: now,
      updatedAt: now,
    );
  }

  MeasurementSheet buildSheet({String id = 'sheet_1', String title = 'Robe'}) {
    final now = DateTime(2026, 3, 12, 10);
    return MeasurementSheet(
      id: id,
      clientId: 'client_1',
      title: title,
      garmentType: 'Robe',
      measurements: const {'tour_poitrine': 92, 'tour_taille': 74.5},
      fabricPhotos: const ['sheet_1/tissu.jpg'],
      createdAt: now,
      updatedAt: now,
    );
  }

  setUpAll(() async {
    sqfliteFfiInit();
    tempDir = await Directory.systemTemp.createTemp('couture_test_');
    AppDatabase.instance.configureForTests(
      path: p.join(tempDir.path, 'test.db'),
      factory: databaseFactoryFfi,
    );
    await AppDatabase.instance.database;
  });

  tearDownAll(() async {
    await AppDatabase.instance.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    final db = await AppDatabase.instance.database;
    await db.delete('sheets');
    await db.delete('clients');
  });

  test('modifier un client ne supprime pas ses fiches', () async {
    await repository.saveClient(buildClient());
    await repository.saveSheet(buildSheet());

    await repository.saveClient(buildClient(name: 'Awa Ndiaye'));

    final client = await repository.client('client_1');
    expect(client?.fullName, 'Awa Ndiaye');
    expect(await repository.sheetsForClient('client_1'), hasLength(1));
  });

  test('les mesures font l\'aller-retour en base', () async {
    await repository.saveClient(buildClient());
    await repository.saveSheet(buildSheet());

    final stored = await repository.sheet('sheet_1');
    expect(stored, isNotNull);
    expect(stored!.measurements['tour_taille'], 74.5);
    expect(stored.fabricPhotos, ['sheet_1/tissu.jpg']);
    expect(stored.measuredCount, 2);
  });

  test('la recherche trouve un client par nom ou téléphone', () async {
    await repository.saveClient(buildClient());
    await repository.saveClient(
      Client(
        id: 'client_2',
        fullName: 'Moussa Fall',
        phone: '76 000 00 00',
        createdAt: DateTime(2026, 3, 12),
        updatedAt: DateTime(2026, 3, 12),
      ),
    );

    expect(await repository.clients(query: 'awa'), hasLength(1));
    expect(await repository.clients(query: '76 000'), hasLength(1));
    expect(await repository.clients(query: 'inconnu'), isEmpty);
    expect(await repository.countClients(), 2);
  });

  test('supprimer une fiche ne touche pas les autres', () async {
    await repository.saveClient(buildClient());
    await repository.saveSheet(buildSheet());
    await repository.saveSheet(buildSheet(id: 'sheet_2', title: 'Jupe'));

    await repository.deleteSheet((await repository.sheet('sheet_1'))!);

    final remaining = await repository.sheetsForClient('client_1');
    expect(remaining, hasLength(1));
    expect(remaining.first.id, 'sheet_2');
  });

  test('supprimer un client supprime ses fiches', () async {
    await repository.saveClient(buildClient());
    await repository.saveSheet(buildSheet());

    await repository.deleteClient('client_1');

    expect(await repository.client('client_1'), isNull);
    expect(await repository.sheetsForClient('client_1'), isEmpty);
  });

  test(
    'les fiches sont triées de la plus récente à la plus ancienne',
    () async {
      await repository.saveClient(buildClient());
      final older = buildSheet();
      final newer = MeasurementSheet(
        id: 'sheet_2',
        clientId: 'client_1',
        title: 'Jupe',
        garmentType: 'Jupe',
        createdAt: DateTime(2026, 3, 13),
        updatedAt: DateTime(2026, 3, 13),
      );
      await repository.saveSheet(older);
      await repository.saveSheet(newer);

      final sheets = await repository.sheetsForClient('client_1');
      expect(sheets.map((s) => s.id), ['sheet_2', 'sheet_1']);
    },
  );
}

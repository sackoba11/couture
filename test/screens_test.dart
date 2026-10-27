import 'dart:io';
import 'dart:ui' as ui;

import 'package:couture/data/app_database.dart';
import 'package:couture/data/couture_repository.dart';
import 'package:couture/models/client.dart';
import 'package:couture/models/measurement_sheet.dart';
import 'package:couture/models/pattern.dart';
import 'package:couture/screens/home_screen.dart';
import 'package:couture/screens/sheet_form_screen.dart';
import 'package:couture/screens/sheet_summary_screen.dart';
import 'package:couture/widgets/pattern_sketch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repository = CoutureRepository.instance;
  late Directory tempDir;
  late Client client;
  late MeasurementSheet fullSheet;

  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
    sqfliteFfiInit();
    tempDir = await Directory.systemTemp.createTemp('couture_screens_');
    AppDatabase.instance.configureForTests(
      path: p.join(tempDir.path, 'screens.db'),
      factory: databaseFactoryFfi,
    );

    final now = DateTime.now();
    client = Client(
      id: 'client_1',
      fullName: 'Awa Diop Ndiaye',
      phone: '77 123 45 67',
      createdAt: now,
      updatedAt: now,
    );
    fullSheet = MeasurementSheet(
      id: 'sheet_1',
      clientId: client.id,
      title: 'Grand boubou pour le Tabaski',
      garmentType: 'Boubou',
      patternId: 'grand_boubou',
      deliveryDate: DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 5)),
      measurements: kPatternDemoMeasurements,
      notes: 'Broderie dorée au col.',
      createdAt: now,
      updatedAt: now,
    );
    await repository.saveClient(client);
    await repository.saveSheet(fullSheet);
  });

  tearDownAll(() async {
    await AppDatabase.instance.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  /// Laisse les requêtes SQLite (asynchrones réelles) aboutir avant de
  /// reconstruire l'arbre.
  Future<void> settle(WidgetTester tester, {int rounds = 6}) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpApp(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: screen,
      ),
    );
    await settle(tester);
  }

  testWidgets('l\'accueil affiche la livraison proche', (tester) async {
    await pumpApp(tester, const HomeScreen());

    expect(find.text('Livraisons proches'), findsOneWidget);
    expect(find.text('Awa Diop Ndiaye'), findsWidgets);
    expect(find.textContaining('dans 5 jours'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le résumé affiche la livraison et le patron dynamique', (
    tester,
  ) async {
    await pumpApp(tester, const SheetSummaryScreen(sheetId: 'sheet_1'));

    expect(find.text('Livraison prévue'), findsOneWidget);
    expect(find.textContaining('Patron Grand boubou'), findsOneWidget);
    expect(find.byType(PatternSketch), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le formulaire filtre les mesures selon le patron', (
    tester,
  ) async {
    final partial = MeasurementSheet(
      id: 'sheet_2',
      clientId: client.id,
      title: 'Robe sirène',
      garmentType: 'Robe',
      patternId: 'robe_sirene',
      measurements: const {'tour_poitrine': 92},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await tester.runAsync(() => repository.saveSheet(partial));

    await pumpApp(tester, SheetFormScreen(client: client, sheet: partial));

    expect(find.text('Patron'), findsOneWidget);
    expect(find.text('Robe sirène'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Tour de poitrine'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('Tour de poitrine'), findsOneWidget);
    expect(find.text('Tour de tête'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Toutes'),
      -120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Toutes'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Tour de tête'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Tour de tête'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chaque silhouette de patron produit un vrai dessin', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final pattern in kMalianPatterns) {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: 340,
                height: 300,
                child: PatternSketch(
                  pattern: pattern,
                  measurements: kPatternDemoMeasurements,
                  height: 300,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final boundary = key.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await tester.runAsync(
        () => boundary.toImage(pixelRatio: 1),
      );
      final bytes = await tester.runAsync(
        () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
      );
      image!.dispose();

      var darkPixels = 0;
      final data = bytes!.buffer.asUint8List();
      for (var i = 0; i < data.length; i += 4) {
        final alpha = data[i + 3];
        if (alpha < 200) continue;
        final luminance =
            0.299 * data[i] + 0.587 * data[i + 1] + 0.114 * data[i + 2];
        if (luminance < 215) darkPixels++;
      }

      expect(
        darkPixels,
        greaterThan(400),
        reason: 'le dessin de ${pattern.id} est vide',
      );
    }
  });
}

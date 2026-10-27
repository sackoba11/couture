import 'package:couture/models/measurement.dart';
import 'package:couture/models/measurement_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatMeasure', () {
    test('affiche les valeurs entières sans décimale', () {
      expect(formatMeasure(98), '98');
      expect(formatMeasure(98.0), '98');
    });

    test('utilise la virgule pour les décimales', () {
      expect(formatMeasure(98.5), '98,5');
      expect(formatMeasure(102.25), '102,3');
    });
  });

  group('parseMeasure', () {
    test('accepte la virgule et le point', () {
      expect(parseMeasure('98,5'), 98.5);
      expect(parseMeasure('98.5'), 98.5);
      expect(parseMeasure('  98 '), 98);
    });

    test('renvoie null pour une saisie invalide ou vide', () {
      expect(parseMeasure(''), isNull);
      expect(parseMeasure('abc'), isNull);
    });
  });

  group('MeasurementSheet', () {
    final createdAt = DateTime(2026, 3, 12, 9, 30);
    final sheet = MeasurementSheet(
      id: 'sheet_1',
      clientId: 'client_1',
      title: 'Robe longue',
      garmentType: 'Robe',
      measurements: const {'tour_poitrine': 92, 'tour_taille': 74.5},
      customMeasurements: const [
        CustomMeasurement(label: 'Tour de tête', value: 56),
      ],
      fabricPhotos: const ['sheet_1/tissu.jpg'],
      modelPhotos: const ['sheet_1/modele.jpg'],
      notes: 'Livraison le 20 mars',
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    test('compte les mesures et les photos', () {
      expect(sheet.measuredCount, 3);
      expect(sheet.photoCount, 2);
      expect(sheet.hasContent, isTrue);
    });

    test('survit à un aller-retour en base', () {
      final copy = MeasurementSheet.fromMap(sheet.toMap());
      expect(copy.measurements, sheet.measurements);
      expect(copy.customMeasurements.first.label, 'Tour de tête');
      expect(copy.fabricPhotos, sheet.fabricPhotos);
      expect(copy.modelPhotos, sheet.modelPhotos);
      expect(copy.notes, sheet.notes);
      expect(copy.createdAt, createdAt);
    });

    test('détecte les groupes de mesures renseignés', () {
      final buste = kMeasurementGroups.firstWhere((g) => g.id == 'buste');
      final bras = kMeasurementGroups.firstWhere((g) => g.id == 'bras');
      expect(sheet.hasMeasurementsIn(buste), isTrue);
      expect(sheet.hasMeasurementsIn(bras), isFalse);
    });

    test('génère un résumé texte lisible', () {
      final text = sheet.toShareText('Awa Diop');
      expect(text, contains('FICHE DE MESURE — Awa Diop'));
      expect(text, contains('Tour de poitrine : 92 cm'));
      expect(text, contains('Tour de taille : 74,5 cm'));
      expect(text, contains('Tour de tête : 56 cm'));
      expect(text, contains('Livraison le 20 mars'));
      expect(text, contains('1 modèle(s), 1 tissu(s)'));
      expect(text, isNot(contains('Tour de cou')));
    });
  });

  test('les identifiants de mesure sont uniques', () {
    final ids = [
      for (final group in kMeasurementGroups)
        for (final field in group.fields) field.id,
    ];
    expect(ids.toSet().length, ids.length);
    expect(kMeasurementLabels.length, ids.length);
  });
}

import 'package:couture/models/measurement.dart';
import 'package:couture/models/pattern.dart';
import 'package:couture/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  group('catalogue des patrons maliens', () {
    test('les identifiants sont uniques', () {
      final ids = kMalianPatterns.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(kMalianPatterns, hasLength(9));
    });

    test('chaque patron ne référence que des mesures connues', () {
      for (final pattern in kMalianPatterns) {
        expect(pattern.keyMeasurements, isNotEmpty, reason: pattern.id);
        for (final id in pattern.keyMeasurements) {
          expect(
            kFormMeasurementIds,
            contains(id),
            reason: '${pattern.id} → $id',
          );
        }
      }
    });

    test('le patron enregistré prime sur le type de vêtement', () {
      final pattern = resolvePattern(
        patternId: 'kaftan',
        garmentType: 'Jupe',
      );
      expect(pattern.name, 'Kaftan');
      expect(pattern.garmentType, 'Robe');
    });

    test('repli sur le patron habituel du type de vêtement', () {
      expect(patternForGarment('Boubou').name, 'Grand boubou');
      expect(patternForGarment('Jupe').name, 'Jupe longue');
      expect(patternForGarment('Inconnu').name, 'Grand boubou');
      expect(resolvePattern(garmentType: 'Pantalon').name, 'Pantalon / Sarouel');
    });

    test('liste les mesures manquantes', () {
      final missing = missingMeasurements(kPatternsById['jupe_longue']!, {
        'tour_taille': 76,
        'tour_hanches': 98,
      });
      expect(missing, contains('longueur_jupe'));
      expect(missing, isNot(contains('tour_taille')));
    });

    test('les mesures d\'exemple couvrent le catalogue', () {
      for (final pattern in kMalianPatterns) {
        for (final id in pattern.keyMeasurements) {
          expect(
            kPatternDemoMeasurements,
            contains(id),
            reason: 'exemple manquant pour ${pattern.id} → $id',
          );
        }
      }
    });
  });

  group('échéances de livraison', () {
    final now = DateTime(2026, 3, 10, 18, 30);

    test('compte les jours calendaires', () {
      expect(daysUntil(DateTime(2026, 3, 12), now: now), 2);
      expect(daysUntil(DateTime(2026, 3, 10), now: now), 0);
      expect(daysUntil(DateTime(2026, 3, 8), now: now), -2);
    });

    test('formate le compte à rebours', () {
      expect(
        formatDeliveryCountdown(DateTime(2026, 3, 10), now: now),
        'aujourd\'hui',
      );
      expect(
        formatDeliveryCountdown(DateTime(2026, 3, 11), now: now),
        'demain',
      );
      expect(
        formatDeliveryCountdown(DateTime(2026, 3, 15), now: now),
        'dans 5 jours',
      );
      expect(
        formatDeliveryCountdown(DateTime(2026, 3, 25), now: now),
        'dans 2 semaines',
      );
      expect(
        formatDeliveryCountdown(DateTime(2026, 3, 8), now: now),
        'en retard de 2 jours',
      );
    });

    test('classe l\'urgence', () {
      expect(
        deliveryStatus(DateTime(2026, 3, 8), now: now),
        DeliveryStatus.late,
      );
      expect(
        deliveryStatus(DateTime(2026, 3, 10), now: now),
        DeliveryStatus.today,
      );
      expect(
        deliveryStatus(DateTime(2026, 3, 15), now: now),
        DeliveryStatus.soon,
      );
      expect(
        deliveryStatus(DateTime(2026, 4, 15), now: now),
        DeliveryStatus.upcoming,
      );
    });
  });
}

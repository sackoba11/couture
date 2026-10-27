import 'package:couture/models/pattern.dart';
import 'package:couture/screens/patterns_screen.dart';
import 'package:couture/widgets/client_avatar.dart';
import 'package:couture/widgets/empty_state.dart';
import 'package:couture/widgets/pattern_sketch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('l\'avatar affiche les initiales du client', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ClientAvatar(initials: 'AD', seed: 'Awa Diop'),
        ),
      ),
    );

    expect(find.text('AD'), findsOneWidget);
  });

  testWidgets('l\'état vide propose une action', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.content_cut,
            title: 'Votre atelier est prêt',
            message: 'Ajoutez votre premier client.',
            action: FilledButton(
              onPressed: () => pressed = true,
              child: const Text('Ajouter un client'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Votre atelier est prêt'), findsOneWidget);
    await tester.tap(find.text('Ajouter un client'));
    expect(pressed, isTrue);
  });

  testWidgets('le patron dynamique se dessine pour chaque silhouette', (
    tester,
  ) async {
    for (final pattern in kMalianPatterns) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 340,
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
      expect(find.byType(PatternSketch), findsOneWidget);
      expect(tester.takeException(), isNull, reason: pattern.id);
    }
  });

  testWidgets('le catalogue liste les patrons maliens', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PatternsScreen()));

    expect(find.text('Patrons du Mali'), findsOneWidget);
    expect(find.text('Grand boubou'), findsOneWidget);
    expect(find.text('Taille basse'), findsOneWidget);
    expect(find.textContaining('patrons de référence'), findsOneWidget);
  });
}

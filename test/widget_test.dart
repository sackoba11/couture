import 'package:couture/widgets/client_avatar.dart';
import 'package:couture/widgets/empty_state.dart';
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
}

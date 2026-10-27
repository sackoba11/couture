# Couture — carnet de mesures pour tailleurs

Application mobile Flutter qui remplace le carnet papier du tailleur :

1. **Clients** : fiches clients avec nom, téléphone et notes.
2. **Fiche de mesure** : type de vêtement, titre libre, notes.
3. **Photos** : prise de vue ou import depuis la galerie pour le **tissu** et le **modèle** (plusieurs photos par catégorie).
4. **Patrons maliens** : catalogue des coupes les plus demandées (grand boubou, taille basse, kaftan, ensemble pagne, robe sirène, chemise bazin, jupe longue, pantalon/sarouel, costume) avec les mesures utiles à chacune.
5. **Mesures recentrées sur le Mali** : buste/taille, épaules, longueurs, manches, bas et jambes, tête et finitions. Le formulaire n'affiche que les mesures du patron choisi (option « Toutes » pour tout voir).
6. **Date de livraison** : champ dédié, avec compte à rebours, bannière des livraisons proches sur l'accueil et base prête pour des notifications locales.
7. **Résumé** : galerie photo, patron dessiné dynamiquement à partir des mesures, toutes les mesures et une copie du résumé en texte prêt à envoyer par WhatsApp/SMS.

## Choix techniques

- 100 % **hors ligne** : les données sont stockées sur le téléphone.
  - SQLite via `sqflite` (clients + fiches), migration automatique v1 → v2 (`pattern_id`, `delivery_date`).
  - Photos copiées dans le dossier privé de l'application (`path_provider`).
- Interface en français (localisation Material + `intl`), Material 3, thème « atelier » (bordeaux / crème).
- Patrons dessinés avec un `CustomPainter` : les largeurs et la longueur du tracé suivent les mesures de la fiche, avec annotations des mesures disponibles.
- Aucune donnée n'est envoyée sur Internet pour l'instant.

## Lancer le projet

```bash
flutter pub get
flutter run
```

Tests et analyse :

```bash
flutter analyze
flutter test
```

## Organisation du code

```text
lib/
├── main.dart                 # point d'entrée + localisation + thème
├── data/
│   ├── app_database.dart     # schéma SQLite et migrations
│   ├── couture_repository.dart
│   └── media_storage.dart    # import / suppression des photos
├── models/
│   ├── client.dart
│   ├── measurement.dart      # mesures standard et formatage
│   ├── measurement_sheet.dart
│   └── pattern.dart          # catalogue des patrons maliens
├── screens/
│   ├── app_shell.dart        # onglets Clients / Patrons
│   ├── home_screen.dart      # clients + livraisons proches
│   ├── client_form_screen.dart
│   ├── client_detail_screen.dart
│   ├── sheet_form_screen.dart
│   ├── sheet_summary_screen.dart
│   ├── patterns_screen.dart
│   ├── pattern_detail_screen.dart
│   └── photo_viewer_screen.dart
├── theme/app_theme.dart
├── utils/                    # dates, échéances, identifiants, photos
└── widgets/                  # composants partagés, dont le dessin de patron
```

## Parcours utilisateur

`Accueil (clients + livraisons proches)` → `Nouvelle fiche` (ou fiche d'un client) →
**patron** → **date de livraison** → **photos tissu/modèle** → **mesures filtrées** →
**Enregistrer** → `Résumé` (patron dessiné, photos, mesures, copie du texte).

L'onglet **Patrons** présente le catalogue : aperçu dessiné, mesures clés, tissus conseillés
et un bouton pour créer directement une fiche avec le patron choisi.

## Pistes pour la suite

- Notifications locales avant la date de livraison (`flutter_local_notifications`).
- Historique des retouches et statut de commande (en cours / prêt / livré).
- Export PDF de la fiche et du patron.
- Sauvegarde / synchronisation cloud et partage multi-appareils.
- Tarifs, acomptes et suivi des paiements.
- Mode sombre.

# Couture — carnet de mesures pour tailleurs

Application mobile Flutter qui remplace le carnet papier du tailleur :

1. **Clients** : fiches clients avec nom, téléphone et notes.
2. **Fiche de mesure** : type de vêtement, titre libre, notes.
3. **Photos** : prise de vue ou import depuis la galerie pour le **tissu** et le **modèle** (plusieurs photos par catégorie).
4. **Mesures** : groupes de mesures standard en centimètres, plus des mesures personnalisées.
5. **Résumé** : galerie photo, toutes les mesures et une copie du résumé en texte prêt à envoyer par WhatsApp/SMS.

## Choix techniques

- 100 % **hors ligne** : les données sont stockées sur le téléphone.
  - SQLite via `sqflite` (clients + fiches).
  - Photos copiées dans le dossier privé de l'application (`path_provider`).
- Interface en français, Material 3, thème « atelier » (bordeaux / crème).
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
├── main.dart                 # point d'entrée + thème
├── data/
│   ├── app_database.dart     # schéma SQLite
│   ├── couture_repository.dart
│   └── media_storage.dart    # import / suppression des photos
├── models/
│   ├── client.dart
│   ├── measurement.dart      # mesures standard et formatage
│   └── measurement_sheet.dart
├── screens/
│   ├── home_screen.dart      # liste des clients
│   ├── client_form_screen.dart
│   ├── client_detail_screen.dart
│   ├── sheet_form_screen.dart
│   ├── sheet_summary_screen.dart
│   └── photo_viewer_screen.dart
├── theme/app_theme.dart
├── utils/                    # dates, identifiants, sélection photo
└── widgets/                  # composants partagés
```

## Parcours utilisateur

`Accueil (clients)` → `Nouvelle fiche` (ou fiche d'un client) → **photos tissu/modèle** →
**mesures** → **Enregistrer** → `Résumé` (photos + mesures + copie du texte).

## Pistes pour la suite

- Historique des retouches et statut de commande (en cours / prêt / livré).
- Export PDF de la fiche.
- Sauvegarde / synchronisation cloud et partage multi-appareils.
- Tarifs, acomptes et suivi des paiements.
- Mode sombre.

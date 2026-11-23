import 'dart:convert';

import 'package:flutter/material.dart';

/// Silhouette utilisée par le dessin de patron.
enum PatternSilhouette {
  grandBoubou,
  tailleBasse,
  kaftan,
  ensemble,
  robe,
  jupe,
  chemise,
  pantalon,
  costume,
}

/// Un patron de couture, tel qu'enregistré dans la base de données ou créé par le tailleur.
class SewingPattern {
  const SewingPattern({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.garmentType,
    required this.silhouette,
    required this.keyMeasurements,
    required this.fabric,
    required this.tip,
    this.isDefault = false,
  });

  /// Identifiant unique du patron (UUID ou 'grand_boubou', etc.).
  final String id;

  /// Nom affiché dans les listes.
  final String name;

  /// Phrase courte affichée dans les listes.
  final String tagline;

  /// Description détaillée de la coupe.
  final String description;

  /// Type de vêtement enregistré dans la fiche.
  final String garmentType;

  final PatternSilhouette silhouette;

  /// Mesures affichées en priorité quand ce patron est choisi.
  final List<String> keyMeasurements;

  /// Tissus conseillés.
  final String fabric;

  /// Conseil de coupe ou de prise de mesure.
  final String tip;

  /// Vrai si c'est l'un des patrons par défaut du Mali (pour distinguer des patrons personnalisés).
  final bool isDefault;

  IconData get icon {
    switch (silhouette) {
      case PatternSilhouette.grandBoubou:
        return Icons.dry_cleaning;
      case PatternSilhouette.tailleBasse:
        return Icons.style;
      case PatternSilhouette.kaftan:
        return Icons.woman;
      case PatternSilhouette.ensemble:
        return Icons.checkroom;
      case PatternSilhouette.robe:
        return Icons.woman_2_outlined;
      case PatternSilhouette.jupe:
        return Icons.filter_vintage;
      case PatternSilhouette.chemise:
        return Icons.dry_cleaning_outlined;
      case PatternSilhouette.pantalon:
        return Icons.directions_walk;
      case PatternSilhouette.costume:
        return Icons.business_center_outlined;
    }
  }

  /// Convertir de Map vers SewingPattern (depuis la base de données).
  factory SewingPattern.fromMap(Map<String, dynamic> map) {
    final keyMeasurementsRaw = map['key_measurements'];
    final keyMeasurements = <String>[];
    if (keyMeasurementsRaw is String) {
      final decoded = jsonDecode(keyMeasurementsRaw) as List<dynamic>;
      keyMeasurements.addAll(decoded.cast<String>());
    } else if (keyMeasurementsRaw is List) {
      keyMeasurements.addAll(keyMeasurementsRaw.cast<String>());
    }

    return SewingPattern(
      id: (map['id'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      tagline: (map['tagline'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      garmentType: (map['garment_type'] as String?) ?? '',
      silhouette: _silhouetteFromString(map['silhouette'] as String?),
      keyMeasurements: keyMeasurements,
      fabric: (map['fabric'] as String?) ?? '',
      tip: (map['tip'] as String?) ?? '',
      isDefault: (map['is_default'] as int?) == 1,
    );
  }

  /// Convertir de SewingPattern vers Map (pour la base de données).
  Map<String, dynamic> toMap() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      'id': id,
      'name': name,
      'tagline': tagline,
      'description': description,
      'garment_type': garmentType,
      'silhouette': _silhouetteToString(),
      'key_measurements': jsonEncode(keyMeasurements),
      'fabric': fabric,
      'tip': tip,
      'is_default': isDefault ? 1 : 0,
      'created_at': now,
      'updated_at': now,
    };
  }

  static PatternSilhouette _silhouetteFromString(String? s) {
    if (s == null) return PatternSilhouette.grandBoubou;
    return PatternSilhouette.values.firstWhere(
      (e) => e.toString().split('.').last == s,
      orElse: () => PatternSilhouette.grandBoubou,
    );
  }

  String _silhouetteToString() {
    return silhouette.toString().split('.').last;
  }
}

/// Les patrons par défaut du Mali (toujours disponibles en lecture seule).
const List<SewingPattern> kDefaultMalianPatterns = [
  SewingPattern(
    id: 'grand_boubou',
    name: 'Grand boubou',
    tagline: 'La pièce d\'apparat, homme ou femme',
    description:
        'Le grand boubou se coupe large pour tomber avec élégance. '
        'On mesure l\'épaule au sol, l\'emmanchure et la manche pour '
        'garder de l\'aisance sans étouffer le porteur.',
    garmentType: 'Boubou',
    silhouette: PatternSilhouette.grandBoubou,
    keyMeasurements: [
      'tour_poitrine',
      'tour_taille',
      'tour_hanches',
      'largeur_epaules',
      'carrure_dos',
      'tour_cou',
      'tour_emmanchure',
      'longueur_totale',
      'longueur_manche',
      'tour_bras',
      'ouverture_manche',
      'tour_tete',
    ],
    fabric: 'Bazin riche, getzner, wax épais',
    tip:
        'Prévoyez 8 à 12 cm d\'aisance sur le tour de poitrine : le boubou '
        'doit flotter, pas coller.',
    isDefault: true,
  ),
  SewingPattern(
    id: 'taille_basse',
    name: 'Taille basse',
    tagline: 'Haut ajusté et jupe portée sur les hanches',
    description:
        'L\'ensemble taille basse descend sous la taille naturelle. '
        'La longueur se prend de la hanche au sol, pas de la taille : '
        'c\'est ce qui donne la ligne tombante caractéristique.',
    garmentType: 'Ensemble',
    silhouette: PatternSilhouette.tailleBasse,
    keyMeasurements: [
      'tour_poitrine',
      'tour_taille',
      'tour_hanches',
      'hauteur_poitrine',
      'longueur_haut',
      'longueur_taille_basse',
      'longueur_manche',
      'tour_bras',
      'tour_cou',
    ],
    fabric: 'Wax, bazin léger, broderie anglaise',
    tip:
        'Mesurez la taille basse 4 à 6 cm sous l\'os du bassin, là où la '
        'jupe reposera réellement.',
    isDefault: true,
  ),
  SewingPattern(
    id: 'kaftan',
    name: 'Kaftan',
    tagline: 'Longue tunique fluide à manches',
    description:
        'Le kaftan se porte long, droit ou légèrement évasé. '
        'Les mesures de buste, de manche et la longueur totale suffisent '
        'pour une coupe propre, avec une fente si besoin.',
    garmentType: 'Robe',
    silhouette: PatternSilhouette.kaftan,
    keyMeasurements: [
      'tour_poitrine',
      'tour_taille',
      'tour_hanches',
      'hauteur_poitrine',
      'ecart_poitrine',
      'largeur_epaules',
      'tour_cou',
      'longueur_totale',
      'longueur_manche',
      'tour_bras',
      'tour_poignet',
    ],
    fabric: 'Bazin, crêpe, soie sauvage',
    tip:
        'Pour un kaftan brodé, ajoutez 2 cm à l\'emmanchure afin que la '
        'broderie ne tire pas à l\'enfilage.',
    isDefault: true,
  ),
  SewingPattern(
    id: 'ensemble_pagne',
    name: 'Ensemble pagne',
    tagline: 'Haut et jupe assortis du quotidien',
    description:
        'L\'ensemble pagne combine un petit haut et une jupe longue. '
        'On prend la longueur du haut séparément de celle de la jupe pour '
        'équilibrer les deux pièces.',
    garmentType: 'Ensemble',
    silhouette: PatternSilhouette.ensemble,
    keyMeasurements: [
      'tour_poitrine',
      'tour_taille',
      'tour_hanches',
      'hauteur_poitrine',
      'largeur_epaules',
      'tour_cou',
      'longueur_haut',
      'longueur_jupe',
      'longueur_manche',
      'tour_bras',
    ],
    fabric: 'Wax, pagne tissé, basin',
    tip:
        'Laissez 3 cm de marge en bas de la jupe : l\'ourlet se règle '
        'mieux une fois la pièce montée.',
    isDefault: true,
  ),
  SewingPattern(
    id: 'robe_sirene',
    name: 'Robe sirène',
    tagline: 'Cintrée jusqu\'aux genoux puis évasée',
    description:
        'La robe sirène épouse le buste, la taille et les hanches avant '
        'de s\'ouvrir sous le genou. La hauteur et l\'écart de poitrine '
        'sont indispensables pour placer les pinces.',
    garmentType: 'Robe',
    silhouette: PatternSilhouette.robe,
    keyMeasurements: [
      'tour_poitrine',
      'tour_taille',
      'tour_hanches',
      'hauteur_poitrine',
      'ecart_poitrine',
      'largeur_epaules',
      'tour_emmanchure',
      'longueur_totale',
      'longueur_devant',
      'longueur_dos',
      'tour_cuisse',
      'tour_genou',
    ],
    fabric: 'Satin, crêpe, dentelle doublée',
    tip:
        'Prenez la mesure de genou debout, jambes jointes : c\'est le point '
        'où la jupe commence à s\'évaser.',
    isDefault: true,
  ),
  SewingPattern(
    id: 'chemise_bazin',
    name: 'Chemise bazin',
    tagline: 'Chemise brodée, coupe droite',
    description:
        'La chemise bazin se porte près du corps avec un col net. '
        'Longueur devant et dos, tour de cou et tour de poignet font '
        'toute la différence au rendu final.',
    garmentType: 'Chemise',
    silhouette: PatternSilhouette.chemise,
    keyMeasurements: [
      'tour_poitrine',
      'tour_taille',
      'largeur_epaules',
      'carrure_dos',
      'tour_cou',
      'longueur_devant',
      'longueur_dos',
      'longueur_manche',
      'tour_bras',
      'tour_poignet',
    ],
    fabric: 'Bazin riche, coton, lin',
    tip:
        'Ajoutez 1,5 cm au tour de cou pour que le col reste confortable '
        'fermé, surtout sur le bazin amidonné.',
    isDefault: true,
  ),
  SewingPattern(
    id: 'jupe_longue',
    name: 'Jupe longue',
    tagline: 'Jupe portefeuille ou évasée',
    description:
        'La jupe longue demande surtout le tour de taille, le tour de '
        'hanches et la hauteur taille pour placer pinces et ceinture.',
    garmentType: 'Jupe',
    silhouette: PatternSilhouette.jupe,
    keyMeasurements: [
      'tour_taille',
      'tour_hanches',
      'hauteur_taille',
      'longueur_jupe',
      'tour_cuisse',
      'ouverture_bas',
    ],
    fabric: 'Wax, bazin, pagne tissé',
    tip:
        'Pour une jupe portefeuille, prévoyez 15 cm de recouvrement et '
        'mesurez l\'ouverture bas pour garder de la marche.',
    isDefault: true,
  ),
  SewingPattern(
    id: 'pantalon_sarouel',
    name: 'Pantalon / Sarouel',
    tagline: 'Pantalon droit ou sarouel ample',
    description:
        'Le sarouel est large à l\'entrejambe et resserré à la cheville. '
        'L\'enfourchure et le tour de cuisse doivent être pris sans serrer.',
    garmentType: 'Pantalon',
    silhouette: PatternSilhouette.pantalon,
    keyMeasurements: [
      'tour_taille',
      'tour_hanches',
      'longueur_pantalon',
      'enfourchure',
      'tour_cuisse',
      'tour_genou',
      'tour_cheville',
    ],
    fabric: 'Bazin, coton, lin, wax',
    tip:
        'Mesurez l\'enfourchure assis, dos droit : c\'est la valeur qui '
        'évite un pantalon qui tire à l\'entrejambe.',
    isDefault: true,
  ),
  SewingPattern(
    id: 'costume',
    name: 'Costume',
    tagline: 'Veste et pantalon assortis',
    description:
        'Le costume demande une prise de mesure complète du haut et du '
        'bas. La carrure et la longueur de manche donnent l\'allure de '
        'la veste, l\'enfourchure celle du pantalon.',
    garmentType: 'Costume',
    silhouette: PatternSilhouette.costume,
    keyMeasurements: [
      'tour_poitrine',
      'tour_taille',
      'tour_hanches',
      'largeur_epaules',
      'carrure_dos',
      'tour_cou',
      'longueur_devant',
      'longueur_dos',
      'longueur_manche',
      'tour_bras',
      'tour_poignet',
      'longueur_pantalon',
      'enfourchure',
      'tour_cuisse',
      'tour_genou',
      'tour_cheville',
    ],
    fabric: 'Laine froide, lin, coton mélangé',
    tip:
        'Prenez les mesures sur une chemise fine : une veste coupée sur '
        'un gros pull finit toujours trop large aux épaules.',
    isDefault: true,
  ),
];

/// Accès rapide par identifiant, chargé depuis la DB + patrons par défaut.
final Map<String, SewingPattern> kPatternsById = {};

/// Alias pour compatibilité avec l'ancien code — identique à kDefaultMalianPatterns.
const List<SewingPattern> kMalianPatterns = kDefaultMalianPatterns;

/// Patrons actuellement chargés (défauts + personnalisés depuis la DB).
/// Défini par le repository après chargement depuis la base de données.
Map<String, SewingPattern> _currentPatterns = {};

/// Définir les patrons actuels (appelé par le repository après chargement).
void setCurrentPatterns(Map<String, SewingPattern> patterns) {
  _currentPatterns = patterns;
}

/// Obtenir les patrons actuellement chargés.
Map<String, SewingPattern> get currentPatterns => _currentPatterns;

/// Charger les patrons depuis la base de données et fusionner avec les par défauts.
/// Cette méthode sera appelée depuis le repository au démarrage.
Future<Map<String, SewingPattern>> loadPatternsFromDatabase() async {
  // Retourne une map vide - le repository chargera depuis la DB
  return {};
}

/// Patron correspondant à un identifiant (utilise la map fournie, puis les défauts).
SewingPattern? patternByIdIn(String? id, Map<String, SewingPattern> patterns) {
  if (id == null) return null;
  final fromPatterns = patterns[id];
  if (fromPatterns != null) return fromPatterns;
  try {
    return kDefaultMalianPatterns.firstWhere((p) => p.id == id);
  } on StateError {
    return null;
  }
}

/// Patron par défaut pour un type de vêtement (utilise la map fournie, puis les défauts).
SewingPattern patternForGarmentIn(String garmentType, Map<String, SewingPattern> patterns) {
  // D'abord un patron personnalisé (non par défaut) de ce type
  final custom = patterns.values.firstWhere(
    (p) => p.garmentType == garmentType && !p.isDefault,
    orElse: () => patterns.values.firstWhere(
      (p) => p.garmentType == garmentType && p.isDefault,
      orElse: () => kDefaultMalianPatterns.firstWhere(
        (p) => p.garmentType == garmentType,
        orElse: () => kDefaultMalianPatterns.first,
      ),
    ),
  );
  return custom;
}

/// Patron enregistré sur la fiche, avec repli sur le type de vêtement.
/// Utilise une map de patrons (ex. chargée depuis la DB).
SewingPattern resolvePatternIn({String? patternId, required String garmentType, required Map<String, SewingPattern> patterns}) {
  return patternByIdIn(patternId, patterns) ?? patternForGarmentIn(garmentType, patterns);
}

/// Patron correspondant à un identifiant, en cherchant dans la map fournie.
SewingPattern? patternById(String? id, Map<String, SewingPattern> patterns) {
  if (id == null) return null;
  return patterns[id];
}

/// Patron par défaut pour un type de vêtement (utilise d'abord les patrons stockés,
/// puis les patrons par défaut du Mali).
SewingPattern patternForGarment(String garmentType, Map<String, SewingPattern> patterns) {
  // Essayer d'abord dans les patrons chargés depuis la DB
  final defaultPattern = patterns.values.firstWhere(
    (p) => p.garmentType == garmentType && !p.isDefault,
    orElse: () => kDefaultMalianPatterns.firstWhere(
      (p) => p.garmentType == garmentType,
      orElse: () => kDefaultMalianPatterns.first,
    ),
  );
  
  // Si ce n'est pas un patron par défaut, le retourner
  if (!defaultPattern.isDefault) return defaultPattern;
  
  // Sinon, retourner le patron par défaut du Mali
  return kDefaultMalianPatterns.firstWhere(
    (p) => p.garmentType == garmentType,
    orElse: () => kDefaultMalianPatterns.first,
  );
}

/// Toutes les silhouettes possibles.
String silhouetteToString(PatternSilhouette silhouette) {
  return silhouette.toString().split('.').last;
}

/// Convertir une chaîne de caractères en silhouette.
PatternSilhouette stringToSilhouette(String s) {
  return PatternSilhouette.values.firstWhere(
    (e) => e.toString().split('.').last == s,
    orElse: () => PatternSilhouette.grandBoubou,
  );
}

/// Patron enregistré sur la fiche, avec repli sur le type de vêtement.
/// Les patterns stockés en base l'emporte sur les patrons par défaut.
SewingPattern resolvePattern({String? patternId, required String garmentType, required Map<String, SewingPattern> patterns}) {
  // Si un patternId est fourni, l'utiliser s'il existe dans la map
  if (patternId != null && patterns.containsKey(patternId)) {
    return patterns[patternId]!;
  }
  // Sinon, utiliser le patron par défaut du type de vêtement
  return patternForGarment(garmentType, patterns);
}

/// Mesures du patron qui manquent sur une fiche.
List<String> missingMeasurements(
  SewingPattern pattern,
  Map<String, double> measurements,
) {
  return pattern.keyMeasurements
      .where((id) => !measurements.containsKey(id))
      .toList();
}

/// Valeurs d'exemple pour dessiner un patron dans le catalogue.
const Map<String, double> kPatternDemoMeasurements = {
  'tour_poitrine': 92,
  'tour_taille': 76,
  'tour_hanches': 98,
  'hauteur_poitrine': 28,
  'ecart_poitrine': 18,
  'largeur_epaules': 39,
  'carrure_dos': 36,
  'tour_cou': 37,
  'tour_emmanchure': 44,
  'longueur_totale': 138,
  'longueur_devant': 42,
  'longueur_dos': 40,
  'hauteur_taille': 104,
  'longueur_haut': 62,
  'longueur_manche': 56,
  'tour_bras': 30,
  'tour_coude': 28,
  'tour_poignet': 18,
  'ouverture_manche': 24,
  'longueur_jupe': 80,
  'longueur_pantalon': 98,
  'longueur_taille_basse': 96,
  'enfourchure': 68,
  'tour_cuisse': 58,
  'tour_genou': 38,
  'tour_cheville': 26,
  'tour_tete': 56,
  'longueur_voile': 180,
  'ouverture_bas': 60,
};
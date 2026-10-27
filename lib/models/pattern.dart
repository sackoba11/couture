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

/// Un patron de couture courant au Mali, avec les mesures qui lui sont
/// réellement nécessaires.
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
  });

  final String id;
  final String name;

  /// Phrase courte affichée dans les listes.
  final String tagline;
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
}

/// Catalogue des patrons les plus demandés dans les ateliers maliens.
const List<SewingPattern> kMalianPatterns = [
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
  ),
];

/// Accès rapide par identifiant.
final Map<String, SewingPattern> kPatternsById = {
  for (final pattern in kMalianPatterns) pattern.id: pattern,
};

/// Patron correspondant à un identifiant, ou null s\'il n\'existe plus.
SewingPattern? patternById(String? id) {
  if (id == null) return null;
  return kPatternsById[id];
}

/// Patron par défaut pour un type de vêtement.
SewingPattern patternForGarment(String garmentType) {
  switch (garmentType) {
    case 'Boubou':
      return kPatternsById['grand_boubou']!;
    case 'Robe':
      return kPatternsById['robe_sirene']!;
    case 'Ensemble':
      return kPatternsById['ensemble_pagne']!;
    case 'Chemise':
      return kPatternsById['chemise_bazin']!;
    case 'Pantalon':
      return kPatternsById['pantalon_sarouel']!;
    case 'Jupe':
      return kPatternsById['jupe_longue']!;
    case 'Costume':
      return kPatternsById['costume']!;
    default:
      return kMalianPatterns.first;
  }
}

/// Patron enregistré sur la fiche, avec repli sur le type de vêtement.
SewingPattern resolvePattern({String? patternId, required String garmentType}) {
  return patternById(patternId) ?? patternForGarment(garmentType);
}

/// Valeurs d\'exemple pour dessiner un patron dans le catalogue.
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

/// Mesures du patron qui manquent sur une fiche.
List<String> missingMeasurements(
  SewingPattern pattern,
  Map<String, double> measurements,
) {
  return pattern.keyMeasurements
      .where((id) => !measurements.containsKey(id))
      .toList();
}

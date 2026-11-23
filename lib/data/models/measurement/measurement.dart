import 'package:flutter/material.dart';

/// Une mesure standard proposée dans le formulaire.
class MeasurementField {
  const MeasurementField(this.id, this.label);

  final String id;
  final String label;
}

/// Un groupe de mesures (affiché dans une section du formulaire).
class MeasurementGroup {
  const MeasurementGroup({
    required this.id,
    required this.title,
    required this.icon,
    required this.fields,
  });

  final String id;
  final String title;
  final IconData icon;
  final List<MeasurementField> fields;
}

/// Mesures proposées par défaut, choisies pour les vêtements les plus
/// cousus au Mali : boubou, taille basse, kaftan, ensemble pagne, robe,
/// chemise bazin, jupe, pantalon et costume.
///
/// Le tailleur ne remplit que les mesures utiles au patron choisi :
/// les autres restent vides.
const List<MeasurementGroup> kMeasurementGroups = [
  MeasurementGroup(
    id: 'buste',
    title: 'Buste et taille',
    icon: Icons.person_outline,
    fields: [
      MeasurementField('tour_poitrine', 'Tour de poitrine'),
      MeasurementField('tour_taille', 'Tour de taille'),
      MeasurementField('tour_hanches', 'Tour de hanches'),
      MeasurementField('hauteur_poitrine', 'Hauteur de poitrine'),
      MeasurementField('ecart_poitrine', 'Écart de poitrine'),
    ],
  ),
  MeasurementGroup(
    id: 'epaules',
    title: 'Épaules et cou',
    icon: Icons.accessibility_new,
    fields: [
      MeasurementField('largeur_epaules', 'Largeur d\'épaules'),
      MeasurementField('tour_sous_poitrine', 'Tour sous-poitrine'),
      MeasurementField('carrure_dos', 'Carrure dos'),
      MeasurementField('tour_cou', 'Tour de cou'),
      MeasurementField('tour_emmanchure', 'Tour d\'emmanchure'),
    ],
  ),
  MeasurementGroup(
    id: 'longueurs',
    title: 'Longueurs',
    icon: Icons.straighten,
    fields: [
      MeasurementField('longueur_totale', 'Longueur totale (épaule–sol)'),
      MeasurementField('longueur_devant', 'Longueur devant'),
      MeasurementField('longueur_dos', 'Longueur dos'),
      MeasurementField('hauteur_taille', 'Hauteur taille (taille–sol)'),
      MeasurementField('longueur_haut', 'Longueur du haut'),
    ],
  ),
  MeasurementGroup(
    id: 'manches',
    title: 'Manches',
    icon: Icons.back_hand_outlined,
    fields: [
      MeasurementField('longueur_manche', 'Longueur de manche'),
      MeasurementField('tour_bras', 'Tour de bras'),
      MeasurementField('tour_coude', 'Tour de coude'),
      MeasurementField('tour_poignet', 'Tour de poignet'),
      MeasurementField('ouverture_manche', 'Ouverture de manche'),
    ],
  ),
  MeasurementGroup(
    id: 'bas',
    title: 'Bas et jambes',
    icon: Icons.directions_walk,
    fields: [
      MeasurementField('longueur_jupe', 'Longueur jupe'),
      MeasurementField('longueur_pantalon', 'Longueur pantalon'),
      MeasurementField(
        'longueur_taille_basse',
        'Longueur taille basse (hanche–sol)',
      ),
      MeasurementField('enfourchure', 'Enfourchure'),
      MeasurementField('tour_cuisse', 'Tour de cuisse'),
      MeasurementField('tour_genou', 'Tour de genou'),
      MeasurementField('tour_cheville', 'Tour de cheville'),
    ],
  ),
  MeasurementGroup(
    id: 'finitions',
    title: 'Tête et finitions',
    icon: Icons.auto_awesome_outlined,
    fields: [
      MeasurementField('tour_tete', 'Tour de tête'),
      MeasurementField('longueur_voile', 'Longueur du voile'),
      MeasurementField('ouverture_bas', 'Ouverture bas'),
    ],
  ),
];

/// Anciennes mesures conservées : elles restent lisibles et ne sont jamais
/// perdues, même si elles ne font plus partie du formulaire principal.
const Map<String, String> kLegacyMeasurementLabels = {
  'tour_sous_poitrine': 'Tour sous-poitrine',
  'carrure_devant': 'Carrure devant',
};

/// Index pratique : identifiant de mesure → libellé.
final Map<String, String> kMeasurementLabels = {
  for (final group in kMeasurementGroups)
    for (final field in group.fields) field.id: field.label,
  ...kLegacyMeasurementLabels,
};

/// Identifiants de toutes les mesures connues (hors mesures libres).
final Set<String> kKnownMeasurementIds = kMeasurementLabels.keys.toSet();

/// Identifiants des mesures affichées dans le formulaire actuel.
final Set<String> kFormMeasurementIds = {
  for (final group in kMeasurementGroups)
    for (final field in group.fields) field.id,
};

const List<String> kGarmentTypes = [
  'Boubou',
  'Robe',
  'Ensemble',
  'Chemise',
  'Pantalon',
  'Jupe',
  'Costume',
  'Autre',
];

/// Libellé lisible pour une mesure inconnue (« longueur_epingle » →
/// « Longueur epingle »).
String measurementLabel(String id) {
  final known = kMeasurementLabels[id];
  if (known != null) return known;
  final words = id.split('_').where((word) => word.isNotEmpty);
  if (words.isEmpty) return id;
  final text = words.join(' ');
  return text[0].toUpperCase() + text.substring(1);
}

/// Formate une mesure en centimètres : 98.0 → « 98 », 98.50 → « 98,5 ».
String formatMeasure(double value) {
  final text = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1).replaceAll('.', ',');
  return text;
}

/// Convertit une saisie utilisateur (« 98,5 ») en nombre, ou null si invalide.
double? parseMeasure(String input) {
  final normalized = input.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

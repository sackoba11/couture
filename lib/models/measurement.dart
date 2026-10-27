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

/// Mesures proposées par défaut. Le tailleur ne remplit que celles
/// qui concernent le vêtement : les autres restent vides.
const List<MeasurementGroup> kMeasurementGroups = [
  MeasurementGroup(
    id: 'haut',
    title: 'Cou et épaules',
    icon: Icons.accessibility_new,
    fields: [
      MeasurementField('tour_cou', 'Tour de cou'),
      MeasurementField('largeur_epaules', 'Largeur d\'épaules'),
      MeasurementField('carrure_dos', 'Carrure dos'),
      MeasurementField('carrure_devant', 'Carrure devant'),
    ],
  ),
  MeasurementGroup(
    id: 'buste',
    title: 'Buste et taille',
    icon: Icons.person_outline,
    fields: [
      MeasurementField('tour_poitrine', 'Tour de poitrine'),
      MeasurementField('tour_sous_poitrine', 'Tour sous-poitrine'),
      MeasurementField('tour_taille', 'Tour de taille'),
      MeasurementField('tour_hanches', 'Tour de hanches'),
      MeasurementField('longueur_devant', 'Longueur devant'),
      MeasurementField('longueur_dos', 'Longueur dos'),
    ],
  ),
  MeasurementGroup(
    id: 'bras',
    title: 'Bras',
    icon: Icons.back_hand_outlined,
    fields: [
      MeasurementField('longueur_manche', 'Longueur de manche'),
      MeasurementField('tour_bras', 'Tour de bras'),
      MeasurementField('tour_coude', 'Tour de coude'),
      MeasurementField('tour_poignet', 'Tour de poignet'),
    ],
  ),
  MeasurementGroup(
    id: 'bas',
    title: 'Bas',
    icon: Icons.directions_walk,
    fields: [
      MeasurementField('longueur_jupe', 'Longueur jupe'),
      MeasurementField('longueur_pantalon', 'Longueur pantalon'),
      MeasurementField('enfourchure', 'Enfourchure'),
      MeasurementField('tour_cuisse', 'Tour de cuisse'),
      MeasurementField('tour_genou', 'Tour de genou'),
      MeasurementField('tour_cheville', 'Tour de cheville'),
      MeasurementField('ouverture_bas', 'Ouverture bas'),
    ],
  ),
  MeasurementGroup(
    id: 'divers',
    title: 'Longueurs et divers',
    icon: Icons.straighten,
    fields: [
      MeasurementField('longueur_totale', 'Longueur totale'),
      MeasurementField('hauteur_taille', 'Hauteur taille'),
      MeasurementField('tour_emmanchure', 'Tour d\'emmanchure'),
    ],
  ),
];

/// Index pratique : identifiant de mesure → libellé.
final Map<String, String> kMeasurementLabels = {
  for (final group in kMeasurementGroups)
    for (final field in group.fields) field.id: field.label,
};

const List<String> kGarmentTypes = [
  'Robe',
  'Chemise',
  'Pantalon',
  'Jupe',
  'Ensemble',
  'Costume',
  'Autre',
];

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

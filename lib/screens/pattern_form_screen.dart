import 'dart:math';

import 'package:flutter/material.dart';

import '../data/couture_repository.dart';
import '../models/measurement.dart';
import '../models/pattern.dart';
import '../widgets/section_card.dart';

/// Écran de création ou d'édition d'un patron de couture.
/// Permet au tailleur de créer un patron personnalisé avec ses propres
/// mesures clés, tissus conseillés et conseils de coupe.
class PatternFormScreen extends StatefulWidget {
  const PatternFormScreen({super.key, this.pattern});

  /// Patron à modifier, ou null pour créer un nouveau patron.
  final SewingPattern? pattern;

  @override
  State<PatternFormScreen> createState() => _PatternFormScreenState();
}

class _PatternFormScreenState extends State<PatternFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final CoutureRepository _repository = CoutureRepository.instance;

  late TextEditingController _nameController;
  late TextEditingController _taglineController;
  late TextEditingController _descriptionController;
  late TextEditingController _fabricController;
  late TextEditingController _tipController;
  late String _garmentType;
  late PatternSilhouette _silhouette;
  final Set<String> _selectedMeasurements = {};

  bool get _isEditing => widget.pattern != null;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.pattern;
    _nameController = TextEditingController(text: p?.name);
    _taglineController = TextEditingController(text: p?.tagline);
    _descriptionController = TextEditingController(text: p?.description);
    _fabricController = TextEditingController(text: p?.fabric);
    _tipController = TextEditingController(text: p?.tip);
    _garmentType = p?.garmentType ?? kGarmentTypes.first;
    _silhouette = p?.silhouette ?? PatternSilhouette.grandBoubou;
    _selectedMeasurements.addAll(p?.keyMeasurements ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _descriptionController.dispose();
    _fabricController.dispose();
    _tipController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    if (_selectedMeasurements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez au moins une mesure clé'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    SewingPattern? pattern;
    try {
      pattern = SewingPattern(
        id:
            widget.pattern?.id ??
            'patron_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(100000)}',
        name: _nameController.text.trim(),
        tagline: _taglineController.text.trim(),
        description: _descriptionController.text.trim(),
        garmentType: _garmentType,
        silhouette: _silhouette,
        keyMeasurements: _selectedMeasurements.toList(),
        fabric: _fabricController.text.trim(),
        tip: _tipController.text.trim(),
        isDefault: widget.pattern?.isDefault ?? false,
      );

      if (_isEditing) {
        await _repository.updatePattern(pattern);
      } else {
        await _repository.savePattern(pattern);
      }

      if (!mounted) return;
      Navigator.of(context).pop(pattern);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      // Si le patron existe déjà (conflit d'ID), considérer comme succès
      if (e.toString().contains('UNIQUE constraint failed')) {
        if (!mounted) return;
        Navigator.of(context).pop(pattern);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _toggleMeasurement(String id) {
    setState(() {
      if (_selectedMeasurements.contains(id)) {
        _selectedMeasurements.remove(id);
      } else {
        _selectedMeasurements.add(id);
      }
    });
  }

  PatternSilhouette _silhouetteForGarment(String garmentType) {
    switch (garmentType) {
      case 'Boubou':
        return PatternSilhouette.grandBoubou;
      case 'Taille basse':
        return PatternSilhouette.tailleBasse;
      case 'Kaftan':
        return PatternSilhouette.kaftan;
      case 'Ensemble':
        return PatternSilhouette.ensemble;
      case 'Robe':
        return PatternSilhouette.robe;
      case 'Jupe':
        return PatternSilhouette.jupe;
      case 'Chemise':
        return PatternSilhouette.chemise;
      case 'Pantalon':
        return PatternSilhouette.pantalon;
      case 'Costume':
        return PatternSilhouette.costume;
      default:
        return PatternSilhouette.grandBoubou;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le patron' : 'Nouveau patron'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SectionCard(
              title: 'Informations du patron',
              icon: Icons.content_cut,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nom du patron *',
                      hintText: 'Ex. Robe sirène ajustée',
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Entrez le nom du patron';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _taglineController,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Slogan',
                      hintText:
                          'Ex. La pièce d\'apparat pour les grandes occasions',
                      prefixIcon: Icon(Icons.tag_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _garmentType,
                    decoration: const InputDecoration(
                      labelText: 'Type de vêtement *',
                      prefixIcon: Icon(Icons.category_outlined, size: 20),
                    ),
                    items: kGarmentTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _garmentType = value;
                          _silhouette = _silhouetteForGarment(value);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<PatternSilhouette>(
                    initialValue: _silhouette,
                    decoration: const InputDecoration(
                      labelText: 'Silhouette pour le dessin *',
                      prefixIcon: Icon(Icons.style_outlined, size: 20),
                    ),
                    items: PatternSilhouette.values.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(
                          s.toString().split('.').last,
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _silhouette = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              title: 'Mesures clés',
              icon: Icons.straighten,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sélectionnez les mesures à afficher pour ce patron.',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF9A8A8F)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final group in kMeasurementGroups) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            group.title,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF7B2D42),
                            ),
                          ),
                        ),
                        ...group.fields.map(
                          (field) => FilterChip(
                            label: Text(
                              field.label,
                              style: TextStyle(
                                fontSize: 12,
                                color: _selectedMeasurements.contains(field.id)
                                    ? Colors.white
                                    : const Color(0xFF6E5C62),
                              ),
                            ),
                            selected: _selectedMeasurements.contains(field.id),
                            onSelected: (_) => _toggleMeasurement(field.id),
                            backgroundColor: const Color(0xFFFBF7F4),
                            selectedColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            checkmarkColor: Colors.white,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_selectedMeasurements.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Sélectionnez au moins une mesure',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              title: 'Tissus conseillés',
              icon: Icons.texture,
              child: TextFormField(
                controller: _fabricController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Ex. Bazin riche, getzner, wax épais',
                  prefixIcon: Icon(Icons.inventory_2_outlined, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              title: 'Conseil du tailleur',
              icon: Icons.lightbulb_outline,
              child: TextFormField(
                controller: _tipController,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText:
                      'Ex. Prévoyez 8 à 12 cm d\'aisance sur le tour de poitrine.',
                  prefixIcon: Icon(Icons.tips_and_updates_outlined, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              title: 'Description',
              icon: Icons.description_outlined,
              child: TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText:
                      'Décrivez la coupe, le tombé et les particularités du patron.',
                  prefixIcon: Icon(Icons.note_outlined, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save),
          label: Text(_saving ? 'Enregistrement…' : 'Enregistrer le patron'),
        ),
      ),
    );
  }
}

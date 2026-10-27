import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/couture_repository.dart';
import '../data/media_storage.dart';
import '../models/client.dart';
import '../models/measurement.dart';
import '../models/measurement_sheet.dart';
import '../utils/formatters.dart';
import '../utils/garment_style.dart';
import '../utils/photo_picker.dart';
import '../widgets/client_avatar.dart';
import '../widgets/photo_thumb.dart';
import '../widgets/section_card.dart';
import 'photo_viewer_screen.dart';

/// Saisie d'une fiche : vêtement, photos (tissu et modèle) et mesures.
class SheetFormScreen extends StatefulWidget {
  const SheetFormScreen({super.key, required this.client, this.sheet});

  final Client client;
  final MeasurementSheet? sheet;

  @override
  State<SheetFormScreen> createState() => _SheetFormScreenState();
}

class _SheetFormScreenState extends State<SheetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final CoutureRepository _repository = CoutureRepository.instance;

  late final String _sheetId;
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  final Map<String, TextEditingController> _measureControllers = {};
  final List<_CustomMeasureRow> _customRows = [];

  /// Lignes retirées : leurs contrôleurs sont libérés à la fermeture de
  /// l'écran, jamais pendant que les champs sont encore affichés.
  final List<_CustomMeasureRow> _retiredRows = [];

  late String _garmentType;
  late List<String> _fabricPhotos;
  late List<String> _modelPhotos;

  /// Photos importées pendant cette session (supprimées si on abandonne).
  final List<String> _addedPhotos = [];

  /// Photos déjà enregistrées retirées de la fiche : effacées seulement
  /// si la fiche est enregistrée, pour pouvoir abandonner sans perte.
  final List<String> _photosToDelete = [];

  bool _saving = false;
  bool _saved = false;

  bool get _isEditing => widget.sheet != null;

  @override
  void initState() {
    super.initState();
    final sheet = widget.sheet;
    _sheetId = sheet?.id ?? 'sheet_${DateTime.now().microsecondsSinceEpoch}';
    _titleController = TextEditingController(
      text: sheet?.title ?? 'Fiche du ${formatShortDate(DateTime.now())}',
    );
    _notesController = TextEditingController(text: sheet?.notes ?? '');
    _garmentType = sheet?.garmentType ?? kGarmentTypes.first;
    _fabricPhotos = [...?sheet?.fabricPhotos];
    _modelPhotos = [...?sheet?.modelPhotos];

    for (final group in kMeasurementGroups) {
      for (final field in group.fields) {
        final value = sheet?.measurements[field.id];
        _measureControllers[field.id] = TextEditingController(
          text: value == null ? '' : formatMeasure(value),
        );
      }
    }

    for (final custom in sheet?.customMeasurements ?? const []) {
      _customRows.add(
        _CustomMeasureRow(
          label: custom.label,
          value: formatMeasure(custom.value),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    for (final controller in _measureControllers.values) {
      controller.dispose();
    }
    for (final row in _customRows) {
      row.dispose();
    }
    for (final row in _retiredRows) {
      row.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------- Photos

  Future<void> _addPhoto(bool fabric) async {
    final image = await pickImageFrom(context);
    if (image == null) return;

    try {
      final path = await MediaStorage.importImage(image, _sheetId);
      if (!mounted) {
        await MediaStorage.deletePhoto(path);
        return;
      }
      setState(() {
        if (fabric) {
          _fabricPhotos.add(path);
        } else {
          _modelPhotos.add(path);
        }
        _addedPhotos.add(path);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Photo non enregistrée : $error')));
    }
  }

  Future<void> _removePhoto(bool fabric, String path) async {
    final isNew = _addedPhotos.contains(path);
    if (!isNew) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Supprimer cette photo ?'),
          content: const Text('Cette action est définitive.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() {
      if (fabric) {
        _fabricPhotos.remove(path);
      } else {
        _modelPhotos.remove(path);
      }
      _addedPhotos.remove(path);
    });

    if (isNew) {
      await MediaStorage.deletePhoto(path);
    } else {
      _photosToDelete.add(path);
    }
  }

  void _openPhotos(List<String> photos, String path) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoViewerScreen(
          paths: photos,
          initialIndex: photos.indexOf(path),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- Enregistrer

  String? _validateMeasure(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = parseMeasure(value);
    if (parsed == null) return 'Invalide';
    if (parsed <= 0 || parsed > 300) return '0 à 300 cm';
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Corrigez les mesures en rouge avant d\'enregistrer.'),
        ),
      );
      return;
    }

    final measurements = <String, double>{};
    for (final entry in _measureControllers.entries) {
      final text = entry.value.text.trim();
      if (text.isEmpty) continue;
      final parsed = parseMeasure(text);
      if (parsed != null) measurements[entry.key] = parsed;
    }

    final custom = <CustomMeasurement>[];
    for (var i = 0; i < _customRows.length; i++) {
      final row = _customRows[i];
      final label = row.label.text.trim();
      final valueText = row.value.text.trim();
      if (label.isEmpty && valueText.isEmpty) continue;
      final parsed = parseMeasure(valueText);
      if (parsed == null) continue;
      custom.add(
        CustomMeasurement(
          label: label.isEmpty ? 'Mesure ${i + 1}' : label,
          value: parsed,
        ),
      );
    }

    if (measurements.isEmpty &&
        custom.isEmpty &&
        _fabricPhotos.isEmpty &&
        _modelPhotos.isEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Fiche vide'),
          content: const Text(
            'Aucune mesure ni photo n\'a été ajoutée. '
            'Voulez-vous vraiment enregistrer cette fiche ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _saving = true);

    final now = DateTime.now();
    final sheet = MeasurementSheet(
      id: _sheetId,
      clientId: widget.client.id,
      title: _titleController.text.trim().isEmpty
          ? 'Fiche du ${formatShortDate(now)}'
          : _titleController.text.trim(),
      garmentType: normalizeGarmentType(_garmentType),
      measurements: measurements,
      customMeasurements: custom,
      fabricPhotos: List.unmodifiable(_fabricPhotos),
      modelPhotos: List.unmodifiable(_modelPhotos),
      notes: _notesController.text.trim(),
      createdAt: widget.sheet?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await _repository.saveSheet(sheet);
      for (final path in _photosToDelete) {
        await MediaStorage.deletePhoto(path);
      }
      if (!mounted) return;
      _saved = true;
      Navigator.of(context).pop(sheet.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enregistrement impossible : $error')),
      );
    }
  }

  // ---------------------------------------------------------------- Fermer

  bool get _hasContent {
    if (_fabricPhotos.isNotEmpty || _modelPhotos.isNotEmpty) return true;
    if (_notesController.text.trim().isNotEmpty) return true;
    if (_measureControllers.values.any((c) => c.text.trim().isNotEmpty)) {
      return true;
    }
    return _customRows.any(
      (row) => row.label.text.trim().isNotEmpty || row.value.text.isNotEmpty,
    );
  }

  Future<void> _close() async {
    if (_saving) return;
    if (_hasContent) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Abandonner cette fiche ?'),
          content: Text(
            _isEditing
                ? 'Les modifications non enregistrées seront perdues.'
                : 'Les mesures et photos ajoutées seront perdues.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continuer'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Abandonner'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    for (final path in _addedPhotos) {
      await MediaStorage.deletePhoto(path);
    }
    if (mounted) Navigator.of(context).pop();
  }

  // ------------------------------------------------------------------ Vue

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_saved) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Fermer',
            icon: const Icon(Icons.close),
            onPressed: _close,
          ),
          title: Text(_isEditing ? 'Modifier la fiche' : 'Nouvelle fiche'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Row(
                children: [
                  ClientAvatar(
                    initials: widget.client.initials,
                    seed: widget.client.fullName,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.client.fullName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          formatFullDate(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF9A8A8F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Vêtement',
                icon: Icons.checkroom,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Titre de la fiche',
                        hintText: 'Ex. Robe longue pour mariage',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final type in kGarmentTypes)
                          ChoiceChip(
                            label: Text(type),
                            selected: _garmentType == type,
                            onSelected: (_) =>
                                setState(() => _garmentType = type),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                title: 'Photos',
                icon: Icons.photo_camera_outlined,
                trailing: Text(
                  '${_fabricPhotos.length + _modelPhotos.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB7A39B),
                  ),
                ),
                child: Column(
                  children: [
                    _PhotoRow(
                      label: 'Tissu',
                      hint: 'Photo du tissu choisi',
                      photos: _fabricPhotos,
                      onAdd: () => _addPhoto(true),
                      onRemove: (path) => _removePhoto(true, path),
                      onOpen: (path) => _openPhotos(_fabricPhotos, path),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(),
                    ),
                    _PhotoRow(
                      label: 'Modèle',
                      hint: 'Photo du modèle ou du croquis',
                      photos: _modelPhotos,
                      onAdd: () => _addPhoto(false),
                      onRemove: (path) => _removePhoto(false, path),
                      onOpen: (path) => _openPhotos(_modelPhotos, path),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mesures',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    'en cm',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF9A8A8F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Remplissez seulement les mesures utiles au vêtement.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF9A8A8F)),
                ),
              ),
              for (final group in kMeasurementGroups) ...[
                _MeasurementGroupCard(
                  group: group,
                  controllers: _measureControllers,
                  validator: _validateMeasure,
                ),
                const SizedBox(height: 12),
              ],
              SectionCard(
                title: 'Mesures personnalisées',
                icon: Icons.add_circle_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_customRows.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Ajoutez une mesure spécifique si besoin.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF9A8A8F),
                          ),
                        ),
                      ),
                    for (var i = 0; i < _customRows.length; i++)
                      _CustomMeasureTile(
                        row: _customRows[i],
                        onRemove: () {
                          setState(() {
                            _retiredRows.add(_customRows.removeAt(i));
                          });
                        },
                      ),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _customRows.add(_CustomMeasureRow()));
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Ajouter une mesure'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                title: 'Notes',
                icon: Icons.notes,
                child: TextFormField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText:
                        'Détails du modèle, retouches, date de livraison…',
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
                : const Icon(Icons.check),
            label: Text(_saving ? 'Enregistrement…' : 'Enregistrer la fiche'),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Widgets

class _PhotoRow extends StatelessWidget {
  const _PhotoRow({
    required this.label,
    required this.hint,
    required this.photos,
    required this.onAdd,
    required this.onRemove,
    required this.onOpen,
  });

  final String label;
  final String hint;
  final List<String> photos;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6E5C62),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                photos.isEmpty
                    ? hint
                    : '${photos.length} ${plural(photos.length, 'photo')}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFFB7A39B)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 88,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final path in photos)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: PhotoThumb(
                    path: path,
                    width: 74,
                    height: 88,
                    borderRadius: 12,
                    onTap: () => onOpen(path),
                    onRemove: () => onRemove(path),
                  ),
                ),
              _AddPhotoButton(onTap: onAdd),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFBF3EE),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 74,
          height: 88,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEBDACB)),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                size: 20,
                color: Color(0xFFB4643F),
              ),
              SizedBox(height: 6),
              Text(
                'Ajouter',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB4643F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeasurementGroupCard extends StatelessWidget {
  const _MeasurementGroupCard({
    required this.group,
    required this.controllers,
    required this.validator,
  });

  final MeasurementGroup group;
  final Map<String, TextEditingController> controllers;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: group.title,
      icon: group.icon,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 10.0;
          final half = (constraints.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < group.fields.length; i++)
                SizedBox(
                  width:
                      i == group.fields.length - 1 && group.fields.length.isOdd
                      ? constraints.maxWidth
                      : half,
                  child: _MeasureField(
                    field: group.fields[i],
                    controller: controllers[group.fields[i].id]!,
                    validator: validator,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MeasureField extends StatelessWidget {
  const _MeasureField({
    required this.field,
    required this.controller,
    required this.validator,
  });

  final MeasurementField field;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: field.label,
        suffixText: 'cm',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        labelStyle: const TextStyle(fontSize: 12.5),
        floatingLabelStyle: const TextStyle(fontSize: 12.5),
      ),
    );
  }
}

class _CustomMeasureRow {
  _CustomMeasureRow({String label = '', String value = ''})
    : label = TextEditingController(text: label),
      value = TextEditingController(text: value);

  final TextEditingController label;
  final TextEditingController value;

  void dispose() {
    label.dispose();
    value.dispose();
  }
}

class _CustomMeasureTile extends StatelessWidget {
  const _CustomMeasureTile({required this.row, required this.onRemove});

  final _CustomMeasureRow row;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: row.label,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Nom de la mesure',
                isDense: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return row.value.text.trim().isEmpty ? null : 'Nom requis';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: row.value,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
              ],
              decoration: const InputDecoration(
                hintText: 'Valeur',
                suffixText: 'cm',
                isDense: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final parsed = parseMeasure(value);
                if (parsed == null) return 'Invalide';
                if (parsed <= 0 || parsed > 300) return '0 à 300 cm';
                return null;
              },
            ),
          ),
          IconButton(
            tooltip: 'Retirer',
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline, size: 20),
          ),
        ],
      ),
    );
  }
}

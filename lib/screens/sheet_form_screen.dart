import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/couture_repository.dart';
import '../data/media_storage.dart';
import '../models/client.dart';
import '../models/measurement.dart';
import '../models/measurement_sheet.dart';
import '../models/pattern.dart';
import '../utils/formatters.dart';
import '../utils/garment_style.dart';
import '../utils/photo_picker.dart';
import '../widgets/client_avatar.dart';
import '../widgets/photo_thumb.dart';
import '../widgets/section_card.dart';
import 'photo_viewer_screen.dart';

/// Saisie d'une fiche : vêtement, patron, livraison, photos et mesures.
class SheetFormScreen extends StatefulWidget {
  const SheetFormScreen({
    super.key,
    required this.client,
    this.sheet,
    this.initialPattern,
  });

  final Client client;
  final MeasurementSheet? sheet;

  /// Patron présélectionné depuis le catalogue.
  final SewingPattern? initialPattern;

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
  late String _patternId;
  DateTime? _deliveryDate;
  bool _showAllMeasurements = false;
  late List<String> _fabricPhotos;
  late List<String> _modelPhotos;

  /// Mesures conservées telles quelles : elles ne figurent plus dans le
  /// formulaire (ancienne version) mais ne doivent jamais être perdues.
  late final Map<String, double> _extraMeasurements;

  /// Photos importées pendant cette session (supprimées si on abandonne).
  final List<String> _addedPhotos = [];

  /// Photos déjà enregistrées retirées de la fiche : effacées seulement
  /// si la fiche est enregistrée, pour pouvoir abandonner sans perte.
  final List<String> _photosToDelete = [];

  bool _saving = false;
  bool _saved = false;

  bool get _isEditing => widget.sheet != null;

  SewingPattern get _pattern =>
      patternByIdSimple(_patternId) ?? patternForGarmentSimple(_garmentType);

  /// Mesures visibles : celles du patron, plus toute mesure déjà saisie
  /// (pour ne jamais masquer une valeur existante).
  Set<String> get _visibleMeasurementIds {
    if (_showAllMeasurements) return kFormMeasurementIds;
    return {
      ..._pattern.keyMeasurements,
      for (final entry in _measureControllers.entries)
        if (entry.value.text.trim().isNotEmpty) entry.key,
    };
  }

  Future<void> _pickPattern() async {
    final selected = await showModalBottomSheet<SewingPattern>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choisir un patron',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Les mesures affichées s\'adapteront à la coupe.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF9A8A8F),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: kMalianPatterns.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final pattern = kMalianPatterns[index];
                      final selected = pattern.id == _patternId;
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.pop(context, pattern),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : const Color(0xFFEFE3DC),
                                width: selected ? 1.6 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFBF1EB),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    pattern.icon,
                                    color: const Color(0xFF9A6A52),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pattern.name,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        pattern.tagline,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          height: 1.3,
                                          color: Color(0xFF8A767D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selected)
                                  Icon(
                                    Icons.check_circle,
                                    size: 20,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() {
      _patternId = selected.id;
      _garmentType = selected.garmentType;
    });
  }

  Future<void> _pickDeliveryDate() async {
    final now = DateTime.now();
    final initial = _deliveryDate ?? now.add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 6),
      helpText: 'Date de livraison',
      cancelText: 'Annuler',
      confirmText: 'Choisir',
    );
    if (picked == null || !mounted) return;
    setState(() => _deliveryDate = DateUtils.dateOnly(picked));
  }

  void _quickDelivery(int days) {
    setState(() {
      _deliveryDate = DateUtils.dateOnly(
        DateTime.now().add(Duration(days: days)),
      );
    });
  }

  void _selectGarment(String type) {
    setState(() {
      _garmentType = type;
      _patternId = patternForGarmentSimple(type).id;
    });
  }

  @override
  void initState() {
    super.initState();
    final sheet = widget.sheet;
    _sheetId = sheet?.id ?? 'sheet_${DateTime.now().microsecondsSinceEpoch}';
    _titleController = TextEditingController(
      text: sheet?.title ?? 'Fiche du ${formatShortDate(DateTime.now())}',
    );
    _notesController = TextEditingController(text: sheet?.notes ?? '');
    _garmentType =
        sheet?.garmentType ??
        widget.initialPattern?.garmentType ??
        kGarmentTypes.first;
    _patternId =
        sheet?.patternId ??
        widget.initialPattern?.id ??
        patternForGarmentSimple(_garmentType).id;
    _deliveryDate = sheet?.deliveryDate;
    _fabricPhotos = [...?sheet?.fabricPhotos];
    _modelPhotos = [...?sheet?.modelPhotos];
    _extraMeasurements = {
      for (final entry in (sheet?.measurements ?? const {}).entries)
        if (!kFormMeasurementIds.contains(entry.key)) entry.key: entry.value,
    };

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

    final measurements = <String, double>{..._extraMeasurements};
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
      patternId: _patternId,
      deliveryDate: _deliveryDate,
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
    if (_deliveryDate != null) return true;
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
    final visibleIds = _visibleMeasurementIds;
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
                            onSelected: (_) => _selectGarment(type),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                title: 'Patron',
                icon: Icons.architecture,
                trailing: TextButton(
                  onPressed: _pickPattern,
                  child: const Text('Changer'),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: _pickPattern,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF3EE),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF1E6DF)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _pattern.icon,
                                color: const Color(0xFF9A6A52),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _pattern.name,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _pattern.tagline,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.3,
                                      color: Color(0xFF8A767D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.unfold_more,
                              size: 18,
                              color: Color(0xFFB7A39B),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_pattern.keyMeasurements.length} mesures utiles '
                      'affichées pour ce patron. Les autres restent '
                      'accessibles avec « Toutes ».',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0xFF9A8A8F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                title: 'Livraison',
                icon: Icons.event_available_outlined,
                trailing: _deliveryDate == null
                    ? null
                    : TextButton(
                        onPressed: () =>
                            setState(() => _deliveryDate = null),
                        child: const Text('Retirer'),
                      ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickDeliveryDate,
                      icon: const Icon(
                        Icons.calendar_month_outlined,
                        size: 18,
                      ),
                      label: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _deliveryDate == null
                              ? 'Choisir une date de livraison'
                              : formatFullDate(_deliveryDate!),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        minimumSize: const Size(0, 50),
                      ),
                    ),
                    if (_deliveryDate != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: Color(0xFF9A6A52),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Livraison ${formatDeliveryCountdown(_deliveryDate!)}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8C6239),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        ActionChip(
                          label: const Text('Dans 7 jours'),
                          onPressed: () => _quickDelivery(7),
                        ),
                        ActionChip(
                          label: const Text('Dans 15 jours'),
                          onPressed: () => _quickDelivery(15),
                        ),
                        ActionChip(
                          label: const Text('Dans 30 jours'),
                          onPressed: () => _quickDelivery(30),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cette date servira aux rappels des commandes proches.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0xFF9A8A8F),
                      ),
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
                  TextButton.icon(
                    onPressed: () => setState(
                      () => _showAllMeasurements = !_showAllMeasurements,
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                    ),
                    icon: Icon(
                      _showAllMeasurements
                          ? Icons.filter_alt_off_outlined
                          : Icons.filter_alt_outlined,
                      size: 16,
                    ),
                    label: Text(
                      _showAllMeasurements ? 'Patron' : 'Toutes',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _showAllMeasurements
                      ? 'Toutes les mesures sont affichées.'
                      : 'Mesures du patron ${_pattern.name}, plus celles déjà '
                            'remplies.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF9A8A8F),
                  ),
                ),
              ),
              for (final group in kMeasurementGroups) ...[
                if (group.fields.any((field) => visibleIds.contains(field.id)))
                  _MeasurementGroupCard(
                    title: group.title,
                    icon: group.icon,
                    fields: [
                      for (final field in group.fields)
                        if (visibleIds.contains(field.id)) field,
                    ],
                    controllers: _measureControllers,
                    validator: _validateMeasure,
                  ),
                if (group.fields.any((field) => visibleIds.contains(field.id)))
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
                    hintText: 'Détails du modèle, retouches, préférences…',
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
    required this.title,
    required this.icon,
    required this.fields,
    required this.controllers,
    required this.validator,
  });

  final String title;
  final IconData icon;
  final List<MeasurementField> fields;
  final Map<String, TextEditingController> controllers;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      icon: icon,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 10.0;
          final half = (constraints.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < fields.length; i++)
                SizedBox(
                  width: i == fields.length - 1 && fields.length.isOdd
                      ? constraints.maxWidth
                      : half,
                  child: _MeasureField(
                    field: fields[i],
                    controller: controllers[fields[i].id]!,
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

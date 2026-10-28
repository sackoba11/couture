import 'dart:io';

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
import '../widgets/client_avatar.dart';
import '../widgets/empty_state.dart';
import '../widgets/pattern_sketch.dart';
import '../widgets/section_card.dart';
import 'photo_viewer_screen.dart';
import 'sheet_form_screen.dart';

class _SummaryData {
  const _SummaryData({required this.sheet, required this.client});

  final MeasurementSheet sheet;
  final Client? client;
}

/// Résumé d'une fiche : photos, mesures et notes, prêts à relire ou partager.
class SheetSummaryScreen extends StatefulWidget {
  const SheetSummaryScreen({super.key, required this.sheetId});

  final String sheetId;

  @override
  State<SheetSummaryScreen> createState() => _SheetSummaryScreenState();
}

class _SheetSummaryScreenState extends State<SheetSummaryScreen> {
  final CoutureRepository _repository = CoutureRepository.instance;
  _SummaryData? _data;

  Future<_SummaryData?> _load() async {
    final sheet = await _repository.sheet(widget.sheetId);
    if (sheet == null) return null;
    final client = await _repository.client(sheet.clientId);
    return _SummaryData(sheet: sheet, client: client);
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final data = await _load();
    if (mounted) setState(() => _data = data);
  }

  Future<void> _edit(MeasurementSheet sheet, Client client) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SheetFormScreen(client: client, sheet: sheet),
      ),
    );
    if (!mounted || saved != true) return;
    _reload();
  }

  Future<void> _delete(MeasurementSheet sheet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette fiche ?'),
        content: const Text(
          'Les mesures et les photos de cette fiche seront définitivement '
          'supprimées.',
        ),
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
    if (confirmed != true) return;

    await _repository.deleteSheet(sheet);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _copy(MeasurementSheet sheet, String clientName) async {
    await Clipboard.setData(ClipboardData(text: sheet.toShareText(clientName)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Résumé copié — vous pouvez le coller dans WhatsApp.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final data = _data!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résumé de la fiche'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Options',
            onSelected: (value) {
              switch (value) {
                case 'copy':
                  _copy(data.sheet, data.client?.fullName ?? 'Client');
                case 'edit':
                  if (data.client != null) {
                    _edit(data.sheet, data.client!);
                  }
                case 'delete':
                  _delete(data.sheet);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy_all_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Copier le résumé'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Modifier la fiche'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Supprimer la fiche'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(data),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            OutlinedButton(
              onPressed: () => _copy(
                data.sheet,
                data.client?.fullName ?? 'Client',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(56, 52),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Icon(Icons.copy_all_outlined, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: data.client == null
                    ? null
                    : () => _edit(data.sheet, data.client!),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Modifier la fiche'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(_SummaryData? data) {
    if (data == null) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'Fiche introuvable',
        message: 'Cette fiche a peut-être été supprimée.',
        action: OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Retour'),
        ),
      );
    }

    final sheet = data.sheet;
    final pattern = sheet.pattern;
    final missing = missingMeasurements(pattern, sheet.measurements);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (sheet.allPhotos.isNotEmpty)
          _PhotoGallery(
            photos: sheet.allPhotos,
            modelCount: sheet.modelPhotos.length,
          )
        else
          Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF7EDE7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEFE3DC)),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_outlined, color: Color(0xFFB99B87), size: 28),
                SizedBox(height: 8),
                Text(
                  'Aucune photo pour cette fiche',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9A8A8F)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        SectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClientAvatar(
                    initials: data.client?.initials ?? '?',
                    seed: data.client?.fullName ?? sheet.clientId,
                    size: 46,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.client?.fullName ?? 'Client supprimé',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if ((data.client?.phone ?? '').isNotEmpty)
                          Text(
                            data.client!.phone,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF8A767D),
                            ),
                          ),
                      ],
                    ),
                  ),
                  GarmentChip(type: sheet.garmentType),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                sheet.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Mise à jour le ${formatFullDate(sheet.updatedAt)}',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF9A8A8F),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _InfoPill(
                    icon: Icons.straighten,
                    label:
                        '${sheet.measuredCount} '
                        '${plural(sheet.measuredCount, 'mesure')}',
                  ),
                  const SizedBox(width: 8),
                  _InfoPill(
                    icon: Icons.photo_outlined,
                    label:
                        '${sheet.photoCount} '
                        '${plural(sheet.photoCount, 'photo')}',
                  ),
                ],
              ),
            ],
          ),
        ),
        if (sheet.deliveryDate != null) ...[
          const SizedBox(height: 12),
          _DeliveryInfo(date: sheet.deliveryDate!),
        ],
        const SizedBox(height: 14),
        SectionCard(
          title: 'Patron ${pattern.name}',
          icon: Icons.architecture,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF1EB),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'dynamique',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9A6A52),
              ),
            ),
          ),
          child: Column(
            children: [
              PatternSketch(
                pattern: pattern,
                measurements: sheet.measurements,
                height: 300,
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: Color(0xFFB4643F),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      missing.isEmpty
                          ? 'Dessin généré à partir des '
                                '${sheet.measurements.length} mesures de la '
                                'fiche.'
                          : 'Dessin basé sur les mesures saisies. Complétez '
                                '${missing.take(3).map(measurementLabel).join(', ')}'
                                '${missing.length > 3 ? '…' : ''} pour '
                                'l\'affiner.',
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: Color(0xFF9A8A8F),
                      ),
                    ),
                  ),
                ],
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
              'en centimètres',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF9A8A8F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (sheet.measuredCount == 0)
          SectionCard(
            child: Column(
              children: [
                const Icon(
                  Icons.straighten,
                  color: Color(0xFFB99B87),
                  size: 28,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aucune mesure enregistrée',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9A8A8F)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: data.client == null
                      ? null
                      : () => _edit(sheet, data.client!),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter des mesures'),
                ),
              ],
            ),
          )
        else ...[
          for (final group in kMeasurementGroups)
            if (sheet.hasMeasurementsIn(group)) ...[
              _MeasureGroupCard(
                title: group.title,
                icon: group.icon,
                entries: [
                  for (final field in group.fields)
                    if (sheet.measurements[field.id] != null)
                      MapEntry(field.label, sheet.measurements[field.id]!),
                ],
              ),
              const SizedBox(height: 10),
            ],
          if (sheet.legacyMeasurements.isNotEmpty)
            _MeasureGroupCard(
              title: 'Mesures complémentaires',
              icon: Icons.history,
              entries: [
                for (final entry in sheet.legacyMeasurements.entries)
                  MapEntry(measurementLabel(entry.key), entry.value),
              ],
            ),
          if (sheet.customMeasurements.isNotEmpty)
            _MeasureGroupCard(
              title: 'Mesures personnalisées',
              icon: Icons.add_circle_outline,
              entries: [
                for (final custom in sheet.customMeasurements)
                  MapEntry(custom.label, custom.value),
              ],
            ),
        ],
        if (sheet.notes.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          SectionCard(
            title: 'Notes',
            icon: Icons.notes,
            child: Text(
              sheet.notes,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: Color(0xFF6E5C62),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF3EE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF9A7F6C)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7A5C4C),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryInfo extends StatelessWidget {
  const _DeliveryInfo({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final status = deliveryStatus(date);
    final background = switch (status) {
      DeliveryStatus.late => const Color(0xFFFBE7E5),
      DeliveryStatus.today => const Color(0xFFFBEBDD),
      DeliveryStatus.soon => const Color(0xFFFBF1E4),
      DeliveryStatus.upcoming => const Color(0xFFF6F0EA),
    };
    final foreground = switch (status) {
      DeliveryStatus.late => const Color(0xFFB3261E),
      DeliveryStatus.today => const Color(0xFF9C5227),
      DeliveryStatus.soon => const Color(0xFF8C6239),
      DeliveryStatus.upcoming => const Color(0xFF7A5C4C),
    };

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: foreground.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.event_available_outlined,
              color: foreground,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Livraison prévue',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: foreground.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatFullDate(date),
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule, size: 12, color: foreground),
                const SizedBox(width: 4),
                Text(
                  formatDeliveryCountdown(date),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoGallery extends StatefulWidget {
  const _PhotoGallery({required this.photos, required this.modelCount});

  final List<String> photos;
  final int modelCount;

  @override
  State<_PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<_PhotoGallery> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE9DCD5)),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: widget.photos.length,
                    onPageChanged: (index) => setState(() => _index = index),
                    itemBuilder: (context, index) {
                      final path = widget.photos[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PhotoViewerScreen(
                                paths: widget.photos,
                                initialIndex: index,
                              ),
                            ),
                          );
                        },
                        child: _GalleryImage(path: path),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _index < widget.modelCount
                              ? Icons.photo_camera_outlined
                              : Icons.texture,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _index < widget.modelCount ? 'Modèle' : 'Tissu',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_index + 1} / ${widget.photos.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.photos.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.photos.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _index
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFFE0CFC6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MeasureGroupCard extends StatelessWidget {
  const _MeasureGroupCard({
    required this.title,
    required this.icon,
    required this.entries,
  });

  final String title;
  final IconData icon;
  final List<MapEntry<String, double>> entries;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      icon: icon,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFBF3EE),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '${entries.length}',
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9A7F6C),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 8.0;
          final half = (constraints.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < entries.length; i++)
                SizedBox(
                  width: i == entries.length - 1 && entries.length.isOdd
                      ? constraints.maxWidth
                      : half,
                  child: _MeasureValue(
                    label: entries[i].key,
                    value: entries[i].value,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MeasureValue extends StatelessWidget {
  const _MeasureValue({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF7F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1E6DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF9A8A8F)),
          ),
          const SizedBox(height: 3),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: formatMeasure(value),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2B2024),
                    letterSpacing: -0.4,
                  ),
                ),
                const TextSpan(
                  text: ' cm',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9A8A8F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryImage extends StatefulWidget {
  const _GalleryImage({required this.path});

  final String path;

  @override
  State<_GalleryImage> createState() => _GalleryImageState();
}

class _GalleryImageState extends State<_GalleryImage> {
  late final Future<File> _file = MediaStorage.file(widget.path);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File>(
      future: _file,
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) {
          return Container(
            color: const Color(0xFFF4EAE5),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stack) => Container(
            color: const Color(0xFFF4EAE5),
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: Color(0xFFB7A39B),
                size: 40,
              ),
            ),
          ),
        );
      },
    );
  }
}

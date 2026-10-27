import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/couture_repository.dart';
import '../models/client.dart';
import '../models/measurement_sheet.dart';
import '../utils/formatters.dart';
import '../utils/garment_style.dart';
import '../widgets/client_avatar.dart';
import '../widgets/empty_state.dart';
import '../widgets/photo_thumb.dart';
import '../widgets/section_card.dart';
import 'client_form_screen.dart';
import 'sheet_form_screen.dart';
import 'sheet_summary_screen.dart';

/// Fiche d'un client : ses coordonnées et toutes ses fiches de mesure.
class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({super.key, required this.client});

  final Client client;

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  final CoutureRepository _repository = CoutureRepository.instance;

  late Client _client;
  late Future<List<MeasurementSheet>> _sheets;

  @override
  void initState() {
    super.initState();
    _client = widget.client;
    _sheets = _repository.sheetsForClient(_client.id);
  }

  void _reload() {
    setState(() {
      _sheets = _repository.sheetsForClient(_client.id);
    });
  }

  Future<void> _refreshClient() async {
    final updated = await _repository.client(_client.id);
    if (!mounted) return;
    if (updated == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _client = updated;
      _sheets = _repository.sheetsForClient(_client.id);
    });
  }

  Future<void> _editClient() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ClientFormScreen(client: _client)),
    );
    if (saved == true) await _refreshClient();
  }

  Future<void> _deleteClient() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce client ?'),
        content: Text(
          'Toutes les fiches et photos de ${_client.fullName} seront '
          'définitivement supprimées.',
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

    await _repository.deleteClient(_client.id);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _createSheet() async {
    final sheetId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => SheetFormScreen(client: _client)),
    );
    if (!mounted) return;
    if (sheetId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SheetSummaryScreen(sheetId: sheetId)),
      );
    }
    if (mounted) _reload();
  }

  Future<void> _openSheet(MeasurementSheet sheet) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SheetSummaryScreen(sheetId: sheet.id)),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _client.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Options',
            onSelected: (value) {
              if (value == 'edit') _editClient();
              if (value == 'delete') _deleteClient();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Modifier le client'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Supprimer le client'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshClient,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 104),
          children: [
            SectionCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClientAvatar(
                        initials: _client.initials,
                        seed: _client.fullName,
                        size: 62,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _client.fullName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                            ),
                            if (_client.phone.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: _client.phone),
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Téléphone copié'),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_outlined,
                                      size: 15,
                                      color: Color(0xFF8A767D),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _client.phone,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: Color(0xFF8A767D),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.copy,
                                      size: 13,
                                      color: Color(0xFFB7A39B),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_client.notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF3EE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _client.notes,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: Color(0xFF6E5C62),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FutureBuilder<List<MeasurementSheet>>(
                    future: _sheets,
                    builder: (context, snapshot) {
                      final sheets = snapshot.data ?? const [];
                      final photos = sheets.fold<int>(
                        0,
                        (sum, sheet) => sum + sheet.photoCount,
                      );
                      return Row(
                        children: [
                          _Stat(
                            value: '${sheets.length}',
                            label: plural(sheets.length, 'fiche'),
                          ),
                          const SizedBox(width: 10),
                          _Stat(
                            value: '$photos',
                            label: plural(photos, 'photo'),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Fiches de mesure',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _createSheet,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouvelle'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<MeasurementSheet>>(
              future: _sheets,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return EmptyState(
                    icon: Icons.error_outline,
                    title: 'Chargement impossible',
                    message: '${snapshot.error}',
                    action: OutlinedButton(
                      onPressed: _reload,
                      child: const Text('Réessayer'),
                    ),
                  );
                }

                final sheets = snapshot.data ?? const [];
                if (sheets.isEmpty) {
                  return SizedBox(
                    height: 300,
                    child: EmptyState(
                      icon: Icons.straighten,
                      title: 'Aucune fiche pour ce client',
                      message:
                          'Commencez une fiche pour prendre les mesures et '
                          'ajouter les photos du tissu et du modèle.',
                      action: FilledButton.icon(
                        onPressed: _createSheet,
                        icon: const Icon(Icons.add),
                        label: const Text('Créer une fiche'),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    for (final sheet in sheets) ...[
                      _SheetCard(sheet: sheet, onTap: () => _openSheet(sheet)),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSheet,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle fiche'),
      ),
    );
  }
}

class _PatternPill extends StatelessWidget {
  const _PatternPill({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1FA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE9DDF0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.architecture,
            size: 11,
            color: Color(0xFF7A5C8C),
          ),
          const SizedBox(width: 4),
          Text(
            name,
            style: const TextStyle(
              color: Color(0xFF7A5C8C),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

Color _deliveryColor(DateTime date) {
  switch (deliveryStatus(date)) {
    case DeliveryStatus.late:
      return const Color(0xFFB3261E);
    case DeliveryStatus.today:
      return const Color(0xFF9C5227);
    case DeliveryStatus.soon:
      return const Color(0xFF8C6239);
    case DeliveryStatus.upcoming:
      return const Color(0xFF9A8A8F);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF3EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF7A5C4C),
            fontFamily: 'Roboto',
          ),
          children: [
            TextSpan(
              text: '$value ',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            TextSpan(text: label),
          ],
        ),
      ),
    );
  }
}

class _SheetCard extends StatelessWidget {
  const _SheetCard({required this.sheet, required this.onTap});

  final MeasurementSheet sheet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photos = sheet.allPhotos;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEFE3DC)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (photos.isNotEmpty)
                PhotoThumb(
                  path: photos.first,
                  width: 64,
                  height: 80,
                  borderRadius: 12,
                )
              else
                Container(
                  width: 64,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF3EE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    garmentIcon(sheet.garmentType),
                    color: const Color(0xFFB99B87),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sheet.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        GarmentChip(type: sheet.garmentType, compact: true),
                        _PatternPill(name: sheet.pattern.name),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${sheet.measuredCount} '
                      '${plural(sheet.measuredCount, 'mesure')} · '
                      '${sheet.photoCount} '
                      '${plural(sheet.photoCount, 'photo')}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF8A767D),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formatRelativeDate(sheet.updatedAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB7A39B),
                      ),
                    ),
                    if (sheet.deliveryDate != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.event_available_outlined,
                            size: 12.5,
                            color: _deliveryColor(sheet.deliveryDate!),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Livraison '
                              '${formatShortDate(sheet.deliveryDate!)} · '
                              '${formatDeliveryCountdown(sheet.deliveryDate!)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: _deliveryColor(sheet.deliveryDate!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFC3AFA6)),
            ],
          ),
        ),
      ),
    );
  }
}

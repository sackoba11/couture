import 'dart:async';

import 'package:flutter/material.dart';

import '../data/couture_repository.dart';
import '../models/client.dart';
import '../utils/formatters.dart';
import '../widgets/client_avatar.dart';
import '../widgets/client_picker.dart';
import '../widgets/empty_state.dart';
import 'client_detail_screen.dart';
import 'client_form_screen.dart';
import 'sheet_form_screen.dart';
import 'sheet_summary_screen.dart';

/// Écran d'accueil : la liste des clients de l'atelier.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CoutureRepository _repository = CoutureRepository.instance;

  late Future<List<ClientOverview>> _clients;
  late Future<List<DeliveryOverview>> _deliveries;
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _clients = _repository.clients();
    _deliveries = _repository.upcomingDeliveries();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _reload({String? query}) {
    setState(() {
      if (query != null) _query = query;
      _clients = _repository.clients(query: _query);
      _deliveries = _repository.upcomingDeliveries();
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _reload(query: value);
    });
  }

  Future<void> _createClient() async {
    final created = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ClientFormScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
    if (created == true) _reload();
  }

  Future<void> _openClient(Client client) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ClientDetailScreen(client: client),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _createSheet() async {
    final client = await showClientPicker(context);
    if (client == null || !mounted) return;
    final sheetId = await Navigator.of(context).push<String>(
      PageRouteBuilder<String>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SheetFormScreen(client: client),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
    if (!mounted) return;
    if (sheetId != null) {
      await Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              SheetSummaryScreen(sheetId: sheetId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    }
    if (mounted) _reload();
  }

  Future<void> _openDelivery(DeliveryOverview delivery) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SheetSummaryScreen(sheetId: delivery.sheet.id),
      ),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 78,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ATELIER',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            const Text('Mes clients'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Nouveau client',
            onPressed: _createClient,
            icon: const Icon(Icons.person_add_alt_1),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Rechercher un client…',
                prefixIcon: const Icon(Icons.search, size: 22),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Effacer',
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _reload(query: '');
                        },
                      ),
                isDense: true,
              ),
            ),
          ),
          FutureBuilder<List<DeliveryOverview>>(
            future: _deliveries,
            builder: (context, snapshot) {
              final deliveries = snapshot.data ?? const <DeliveryOverview>[];
              if (deliveries.isEmpty) return const SizedBox.shrink();
              return _DeliveryBanner(
                deliveries: deliveries,
                onTap: _openDelivery,
              );
            },
          ),
          Expanded(
            child: FutureBuilder<List<ClientOverview>>(
              future: _clients,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return EmptyState(
                    icon: Icons.error_outline,
                    title: 'Impossible de charger les clients',
                    message: '${snapshot.error}',
                    action: OutlinedButton(
                      onPressed: _reload,
                      child: const Text('Réessayer'),
                    ),
                  );
                }

                final clients = snapshot.data ?? const [];
                if (clients.isEmpty) {
                  if (_query.isNotEmpty) {
                    return EmptyState(
                      icon: Icons.search_off,
                      title: 'Aucun résultat',
                      message: 'Aucun client ne correspond à « $_query ».',
                      action: OutlinedButton(
                        onPressed: () {
                          _searchController.clear();
                          _reload(query: '');
                        },
                        child: const Text('Effacer la recherche'),
                      ),
                    );
                  }
                  return EmptyState(
                    icon: Icons.content_cut,
                    title: 'Votre atelier est prêt',
                    message:
                        'Ajoutez votre premier client, prenez ses mesures et '
                        'gardez les photos du tissu et du modèle au même endroit.',
                    action: FilledButton.icon(
                      onPressed: _createClient,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Ajouter un client'),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final clients = _repository.clients(query: _query);
                    final deliveries = _repository.upcomingDeliveries();
                    setState(() {
                      _clients = clients;
                      _deliveries = deliveries;
                    });
                    await Future.wait([clients, deliveries]);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                    itemCount: clients.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final overview = clients[index];
                      return _ClientCard(
                        overview: overview,
                        onTap: () => _openClient(overview.client),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSheet,
        icon: const Icon(Icons.straighten),
        label: const Text('Nouvelle fiche'),
      ),
    );
  }
}

/// Bandeau des livraisons à venir (préfiguration des notifications locales).
class _DeliveryBanner extends StatelessWidget {
  const _DeliveryBanner({required this.deliveries, required this.onTap});

  final List<DeliveryOverview> deliveries;
  final ValueChanged<DeliveryOverview> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  size: 17,
                  color: Color(0xFF7B2D42),
                ),
                const SizedBox(width: 7),
                const Flexible(
                  child: Text(
                    'Livraisons proches',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B2D42),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${deliveries.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  '21 jours',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFFB7A39B)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: deliveries.length,
              separatorBuilder: (_, _) => const SizedBox(width: 9),
              itemBuilder: (context, index) {
                final delivery = deliveries[index];
                return _DeliveryCard(
                  delivery: delivery,
                  onTap: () => onTap(delivery),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.delivery, required this.onTap});

  final DeliveryOverview delivery;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = delivery.status();
    final palette = _deliveryPalette(status);
    final date = delivery.deliveryDate;

    return SizedBox(
      width: 236,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFE3DC)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 64,
                  decoration: BoxDecoration(
                    color: palette.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 20,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: palette.foreground,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        formatMonthShort(date),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: palette.foreground.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery.client.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${delivery.sheet.title} · '
                        '${delivery.sheet.pattern.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF8A767D),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 11.5,
                            color: palette.foreground,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              formatDeliveryCountdown(date),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: palette.foreground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

({Color background, Color foreground}) _deliveryPalette(DeliveryStatus status) {
  switch (status) {
    case DeliveryStatus.late:
      return (
        background: const Color(0xFFFBE7E5),
        foreground: const Color(0xFFB3261E),
      );
    case DeliveryStatus.today:
      return (
        background: const Color(0xFFFBEBDD),
        foreground: const Color(0xFF9C5227),
      );
    case DeliveryStatus.soon:
      return (
        background: const Color(0xFFFBF1E4),
        foreground: const Color(0xFF8C6239),
      );
    case DeliveryStatus.upcoming:
      return (
        background: const Color(0xFFF2EEE9),
        foreground: const Color(0xFF7A5C4C),
      );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.overview, required this.onTap});

  final ClientOverview overview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final client = overview.client;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEFE3DC)),
          ),
          child: Row(
            children: [
              ClientAvatar(
                initials: client.initials,
                seed: client.fullName,
                size: 52,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      client.phone.isEmpty ? 'Sans téléphone' : client.phone,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8A767D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.content_cut,
                          size: 14,
                          color: Color(0xFF9A7F6C),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          overview.sheetCount == 0
                              ? 'Aucune fiche'
                              : '${overview.sheetCount} '
                                    '${plural(overview.sheetCount, 'fiche')}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7A5C4C),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: Color(0xFFC3AFA6),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            formatRelativeDate(overview.lastActivity),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF9A8A8F),
                            ),
                          ),
                        ),
                      ],
                    ),
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

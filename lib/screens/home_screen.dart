import 'dart:async';

import 'package:flutter/material.dart';

import '../data/couture_repository.dart';
import '../models/client.dart';
import '../utils/formatters.dart';
import '../widgets/client_avatar.dart';
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
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _clients = _repository.clients();
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
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _reload(query: value);
    });
  }

  Future<void> _createClient() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const ClientFormScreen()));
    if (created == true) _reload();
  }

  Future<void> _openClient(Client client) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ClientDetailScreen(client: client)),
    );
    if (mounted) _reload();
  }

  Future<void> _createSheet() async {
    final client = await _pickClient();
    if (client == null || !mounted) return;
    final sheetId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => SheetFormScreen(client: client)),
    );
    if (!mounted) return;
    if (sheetId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SheetSummaryScreen(sheetId: sheetId)),
      );
    }
    if (mounted) _reload();
  }

  Future<Client?> _pickClient() async {
    final overviews = await _repository.clients();
    if (!mounted) return null;
    if (overviews.isEmpty) {
      final created = await Navigator.of(
        context,
      ).push<bool>(MaterialPageRoute(builder: (_) => const ClientFormScreen()));
      if (created != true) return null;
      final refreshed = await _repository.clients();
      return refreshed.isEmpty ? null : refreshed.first.client;
    }

    return showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pour quel client ?',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
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
                    itemCount: overviews.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final overview = overviews[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFEFE3DC)),
                        ),
                        tileColor: Colors.white,
                        leading: ClientAvatar(
                          initials: overview.client.initials,
                          seed: overview.client.fullName,
                          size: 42,
                        ),
                        title: Text(
                          overview.client.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          overview.sheetCount == 0
                              ? 'Aucune fiche'
                              : '${overview.sheetCount} '
                                    '${plural(overview.sheetCount, 'fiche')}',
                        ),
                        onTap: () => Navigator.pop(context, overview.client),
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
                    final future = _repository.clients(query: _query);
                    setState(() => _clients = future);
                    await future;
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
                        Text(
                          formatRelativeDate(overview.lastActivity),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF9A8A8F),
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

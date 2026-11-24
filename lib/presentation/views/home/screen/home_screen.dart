import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/services/navigation_service.dart';
import '../../../../data/models/client/client.dart';
import '../../../../data/repositories/couture_repository/couture_repository.dart';
import '../../../../routes/app_routes.dart';
import '../../../widgets/client_picker.dart';
import '../../../widgets/empty_state.dart';
import '../../client/screens/client_detail_screen.dart';
import '../../client/screens/client_form_screen.dart';
import '../../sheet/screens/sheet_form_screen.dart';
import '../../sheet/screens/sheet_summary_screen.dart';
import '../widgets/client_card.dart';
import '../widgets/delivery_banner.dart';
import '../widgets/search_section.dart';

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
            SheetFormScreen(),
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
              SheetSummaryScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    }
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
        actionsPadding: EdgeInsets.only(right: 4),
        actions: [
          IconButton(
            tooltip: 'Nouveau client',
            onPressed: () => NavigationService.push(AppRoutes.clientForm),
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          SearchSection(
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
          ),
          FutureBuilder<List<DeliveryOverview>>(
            future: _deliveries,
            builder: (context, snapshot) {
              final deliveries = snapshot.data ?? const <DeliveryOverview>[];
              if (deliveries.isEmpty) return const SizedBox.shrink();
              return DeliveryBanner(
                deliveries: deliveries,
                onTap: () => NavigationService.push(AppRoutes.sheetSummary),
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
                      return ClientCard(
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
        heroTag: null,
        onPressed: _createSheet,
        icon: const Icon(Icons.straighten),
        label: const Text('Nouvelle fiche'),
      ),
    );
  }
}

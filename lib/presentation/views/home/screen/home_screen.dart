import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/navigation_service.dart';
import '../../../../routes/app_routes.dart';
import '../../../widgets/empty_state.dart';
import '../controller/home_controller.dart';
import '../widgets/client_card.dart';
import '../widgets/delivery_banner.dart';
import '../widgets/search_section.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

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
            searchController: controller.searchController,
            onSearchChanged: controller.onSearchChanged,
          ),
          Obx(() {
            if (controller.deliveries.isEmpty) return const SizedBox.shrink();
            return DeliveryBanner(
              deliveries: controller.deliveries,
              onTap: () => NavigationService.push(AppRoutes.sheetSummary),
            );
          }),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.clients.isEmpty) {
                if (controller.query.isNotEmpty) {
                  return EmptyState(
                    icon: Icons.search_off,
                    title: 'Aucun résultat',
                    message:
                        'Aucun client ne correspond à « ${controller.query} ».',
                    action: OutlinedButton(
                      onPressed: () {
                        controller.searchController.clear();
                        controller.refreshData(queryText: '');
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
                    onPressed: () =>
                        NavigationService.push(AppRoutes.clientForm),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Ajouter un client'),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await controller.refreshData();
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                  itemCount: controller.clients.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final overview = controller.clients[index];
                    return ClientCard(
                      overview: overview,
                      onTap: () =>
                          NavigationService.push(AppRoutes.clientDetails),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => controller.createSheet(context: context),
        icon: const Icon(Icons.straighten),
        label: const Text('Nouvelle fiche'),
      ),
    );
  }
}

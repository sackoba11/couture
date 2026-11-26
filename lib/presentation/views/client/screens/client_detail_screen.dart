import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/navigation_service.dart';
import '../../../../routes/app_routes.dart';
import '../../../widgets/empty_state.dart';
import '../controller/client_controller.dart';
import '../widgets/infos_card.dart';
import '../widgets/sheet_card.dart';

class ClientDetailScreen extends GetView<ClientController> {
  const ClientDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = controller.currentClient.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          client?.fullName ?? "",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Options',
            onSelected: (value) {
              if (value == 'edit') {
                controller.editClient();
              }
              if (value == 'delete') {
                controller.deleteClient(context: context);
              }
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
        onRefresh: () => controller.refreshClient(clientId: client!.id),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 104),
          children: [
            InfosCard(),
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
                  onPressed: () => NavigationService.push(AppRoutes.sheetForm),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouvelle'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Obx(() {
              if (controller.isLoading.value) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final sheets = controller.sheets;
              if (sheets.isEmpty) {
                return EmptyState(
                  icon: Icons.straighten,
                  title: 'Aucune fiche pour ce client',
                  message:
                      'Commencez une fiche pour prendre les mesures et '
                      'ajouter les photos du tissu et du modèle.',
                  action: FilledButton.icon(
                    onPressed: () =>
                        NavigationService.push(AppRoutes.sheetForm),
                    icon: const Icon(Icons.add),
                    label: const Text('Créer une fiche'),
                  ),
                );
              }
              return Column(
                children: [
                  for (final sheet in sheets) ...[
                    SheetCard(
                      sheet: sheet,
                      onTap: () {
                        controller.currentSheet.value = sheet;
                        NavigationService.push(AppRoutes.sheetSummary);
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => NavigationService.push(AppRoutes.sheetForm),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle fiche'),
      ),
    );
  }
}

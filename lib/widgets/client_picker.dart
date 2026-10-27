import 'package:flutter/material.dart';

import '../data/couture_repository.dart';
import '../models/client.dart';
import '../screens/client_form_screen.dart';
import '../utils/formatters.dart';
import 'client_avatar.dart';

/// Ouvre le sélecteur de client, en proposant d'en créer un si l'atelier
/// est encore vide.
Future<Client?> showClientPicker(BuildContext context) async {
  final repository = CoutureRepository.instance;
  final overviews = await repository.clients();
  if (!context.mounted) return null;

  if (overviews.isEmpty) {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const ClientFormScreen()));
    if (created != true) return null;
    final refreshed = await repository.clients();
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
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

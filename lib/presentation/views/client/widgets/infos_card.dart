import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/utils/formatters.dart';
import '../../../widgets/client_avatar.dart';
import '../../../widgets/section_card.dart';
import '../controller/client_controller.dart';
import 'stat.dart';

class InfosCard extends GetView<ClientController> {
  const InfosCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = controller.currentClient.value;
    return SectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClientAvatar(
                initials: client?.initials ?? "",
                seed: client?.fullName ?? "",
                size: 62,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client?.fullName ?? "",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (client != null && client.phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () async {
                          await Clipboard.setData(
                            ClipboardData(text: client.phone),
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
                              client.phone,
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
          if (client != null && client.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF3EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                client.notes,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: Color(0xFF6E5C62),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Obx(() {
            final sheets = controller.sheets;
            final photos = sheets.fold<int>(
              0,
              (sum, sheet) => sum + sheet.photoCount,
            );
            return Row(
              children: [
                Stat(
                  value: '${sheets.length}',
                  label: plural(sheets.length, 'fiche'),
                ),
                const SizedBox(width: 10),
                Stat(value: '$photos', label: plural(photos, 'photo')),
              ],
            );
          }),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../data/models/client/client.dart';
import '../../../widgets/client_avatar.dart';

class ClientCard extends StatelessWidget {
  const ClientCard({super.key, required this.overview, required this.onTap});

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

import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../data/repositories/couture_repository/couture_repository.dart';

class DeliveryCard extends StatelessWidget {
  const DeliveryCard({super.key, required this.delivery, required this.onTap});

  final DeliveryOverview delivery;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    ({Color background, Color foreground}) deliveryPalette(
      DeliveryStatus status,
    ) {
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

    final status = delivery.status();
    final palette = deliveryPalette(status);
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

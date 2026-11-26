import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../data/models/measurement_sheet/measurement_sheet.dart';
import '../../../widgets/garmen_chip.dart';
import '../../../widgets/photo_thumb.dart';
import 'pattern_pill.dart';

class SheetCard extends StatelessWidget {
  const SheetCard({super.key, required this.sheet, required this.onTap});

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
                        PatternPill(name: sheet.pattern.name),
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
}

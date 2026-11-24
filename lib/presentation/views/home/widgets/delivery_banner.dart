import 'package:flutter/material.dart';

import '../../../../data/repositories/couture_repository/couture_repository.dart';
import 'delivery_card.dart';

class DeliveryBanner extends StatelessWidget {
  const DeliveryBanner({
    super.key,
    required this.deliveries,
    required this.onTap,
  });

  final List<DeliveryOverview> deliveries;
  final VoidCallback? onTap;

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
                return DeliveryCard(
                  delivery: delivery,
                  onTap: onTap,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

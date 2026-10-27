import 'package:flutter/material.dart';

import '../models/measurement.dart';

/// Icône associée au type de vêtement.
IconData garmentIcon(String type) {
  switch (type) {
    case 'Boubou':
      return Icons.dry_cleaning;
    case 'Robe':
      return Icons.woman;
    case 'Chemise':
      return Icons.checkroom;
    case 'Pantalon':
      return Icons.directions_walk;
    case 'Jupe':
      return Icons.filter_vintage;
    case 'Ensemble':
      return Icons.style;
    case 'Costume':
      return Icons.business_center_outlined;
    default:
      return Icons.content_cut;
  }
}

/// Petite pastille colorée avec le type de vêtement.
class GarmentChip extends StatelessWidget {
  const GarmentChip({super.key, required this.type, this.compact = false});

  final String type;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF7B5B45);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF6EDE6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFEBDACB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(garmentIcon(type), size: compact ? 12 : 14, color: color),
          const SizedBox(width: 5),
          Text(
            type,
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Vérifie qu'un type fait partie de la liste connue.
String normalizeGarmentType(String? value) {
  if (value != null && kGarmentTypes.contains(value)) return value;
  return kGarmentTypes.last;
}

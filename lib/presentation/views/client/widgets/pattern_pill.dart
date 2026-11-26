import 'package:flutter/material.dart';

class PatternPill extends StatelessWidget {
  const PatternPill({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1FA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE9DDF0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.architecture, size: 11, color: Color(0xFF7A5C8C)),
          const SizedBox(width: 4),
          Text(
            name,
            style: const TextStyle(
              color: Color(0xFF7A5C8C),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

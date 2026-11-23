import 'package:flutter/material.dart';

/// Avatar rond avec les initiales du client.
class ClientAvatar extends StatelessWidget {
  const ClientAvatar({
    super.key,
    required this.initials,
    this.size = 52,
    this.seed = '',
  });

  final String initials;
  final double size;

  /// Sert à choisir une couleur stable pour un même client.
  final String seed;

  static const List<Color> _palette = [
    Color(0xFF7B2D42),
    Color(0xFFB4643F),
    Color(0xFF4E6E5D),
    Color(0xFF5B5A8C),
    Color(0xFFA3762F),
    Color(0xFF2F6C79),
  ];

  Color get _color {
    final source = seed.isEmpty ? initials : seed;
    final hash = source.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return _palette[hash % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: _color.withValues(alpha: 0.22)),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: _color,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

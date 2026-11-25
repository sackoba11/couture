import 'dart:math';

import 'package:flutter/material.dart';

class Utils {
  /// Identifiant local unique (horodatage + aléa).
  static String newId(String prefix) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final suffix = Random().nextInt(1 << 32).toRadixString(36);
    return '${prefix}_${timestamp.toRadixString(36)}_$suffix';
  }

  static Future<void> getSnackBar({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    BorderRadius? borderRadius,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: margin ?? EdgeInsets.symmetric(horizontal: 16, vertical: 50),
        shape: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(50),
        ),
        backgroundColor: backgroundColor,
        content: child,
      ),
    );
  }
}

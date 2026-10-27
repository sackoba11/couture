import 'dart:math';

/// Identifiant local unique (horodatage + aléa).
String newId(String prefix) {
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final suffix = Random().nextInt(1 << 32).toRadixString(36);
  return '${prefix}_${timestamp.toRadixString(36)}_$suffix';
}

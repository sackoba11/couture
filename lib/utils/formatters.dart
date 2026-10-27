import 'package:intl/intl.dart';

final DateFormat _dayMonth = DateFormat('d MMMM', 'fr_FR');
final DateFormat _fullDate = DateFormat('d MMMM yyyy', 'fr_FR');
final DateFormat _shortDate = DateFormat('d MMM yyyy', 'fr_FR');

/// « 12 mars 2026 »
String formatFullDate(DateTime date) => _fullDate.format(date);

/// « 12 mars »
String formatDayMonth(DateTime date) => _dayMonth.format(date);

/// « 12 mars 2026 » en version courte.
String formatShortDate(DateTime date) => _shortDate.format(date);

/// « Aujourd'hui », « Hier », « il y a 3 j » ou la date.
String formatRelativeDate(DateTime date, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final day = DateTime(date.year, date.month, date.day);
  final difference = today.difference(day).inDays;

  if (difference <= 0) return 'Aujourd\'hui';
  if (difference == 1) return 'Hier';
  if (difference < 7) return 'Il y a $difference jours';
  if (date.year == reference.year) return formatDayMonth(date);
  return formatFullDate(date);
}

/// Accorde un mot au pluriel.
String plural(int count, String singular, {String? pluralForm}) {
  if (count <= 1) return singular;
  return pluralForm ?? '${singular}s';
}

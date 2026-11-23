import 'package:intl/intl.dart';

final DateFormat _dayMonth = DateFormat('d MMMM', 'fr_FR');
final DateFormat _fullDate = DateFormat('d MMMM yyyy', 'fr_FR');
final DateFormat _shortDate = DateFormat('d MMM yyyy', 'fr_FR');
final DateFormat _monthShort = DateFormat('MMM', 'fr_FR');

/// « 12 mars 2026 »
String formatFullDate(DateTime date) => _fullDate.format(date);

/// « 12 mars »
String formatDayMonth(DateTime date) => _dayMonth.format(date);

/// « mars »
String formatMonthShort(DateTime date) =>
    _monthShort.format(date).replaceAll('.', '');

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

/// Nombre de jours calendaires entre aujourd'hui et [date]
/// (0 = aujourd'hui, négatif = date passée).
int daysUntil(DateTime date, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final day = DateTime(date.year, date.month, date.day);
  return day.difference(today).inDays;
}

/// « en retard de 2 jours », « aujourd'hui », « demain », « dans 5 jours »…
String formatDeliveryCountdown(DateTime date, {DateTime? now}) {
  final days = daysUntil(date, now: now);
  if (days < -1) return 'en retard de ${-days} jours';
  if (days == -1) return 'en retard d\'un jour';
  if (days == 0) return 'aujourd\'hui';
  if (days == 1) return 'demain';
  if (days < 14) return 'dans $days jours';
  final weeks = (days / 7).round();
  return 'dans $weeks semaines';
}

/// Urgence d'une livraison, utilisée pour colorer les cartes.
enum DeliveryStatus { late, today, soon, upcoming }

DeliveryStatus deliveryStatus(DateTime date, {DateTime? now}) {
  final days = daysUntil(date, now: now);
  if (days < 0) return DeliveryStatus.late;
  if (days == 0) return DeliveryStatus.today;
  if (days <= 7) return DeliveryStatus.soon;
  return DeliveryStatus.upcoming;
}

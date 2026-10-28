import 'dart:convert';

import '../utils/formatters.dart';
import 'measurement.dart';
import 'pattern.dart';

/// Une mesure libre ajoutée par le tailleur (« Tour de tête », etc.).
class CustomMeasurement {
  const CustomMeasurement({required this.label, required this.value});

  final String label;
  final double value;

  Map<String, Object?> toJson() => {'label': label, 'value': value};

  factory CustomMeasurement.fromJson(Map<String, Object?> json) {
    return CustomMeasurement(
      label: (json['label'] as String?) ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Une fiche de mesure : le vêtement demandé, le patron, les mesures,
/// la date de livraison et les photos.
class MeasurementSheet {
  const MeasurementSheet({
    required this.id,
    required this.clientId,
    required this.title,
    required this.garmentType,
    this.patternId,
    this.deliveryDate,
    this.measurements = const {},
    this.customMeasurements = const [],
    this.fabricPhotos = const [],
    this.modelPhotos = const [],
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String clientId;
  final String title;
  final String garmentType;

  /// Patron choisi dans le catalogue (null pour les anciennes fiches).
  final String? patternId;

  /// Date de livraison promise au client, sans heure (null si non définie).
  final DateTime? deliveryDate;

  /// Mesures standard : identifiant du champ → valeur en centimètres.
  final Map<String, double> measurements;
  final List<CustomMeasurement> customMeasurements;

  /// Chemins relatifs des photos, dans le dossier de l'application.
  final List<String> fabricPhotos;
  final List<String> modelPhotos;

  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get measuredCount => measurements.length + customMeasurements.length;

  int get photoCount => fabricPhotos.length + modelPhotos.length;

  /// Toutes les photos, le modèle en premier.
  List<String> get allPhotos => [...modelPhotos, ...fabricPhotos];

  /// Vrai si la fiche contient déjà quelque chose d'utile.
  bool get hasContent => measuredCount > 0 || photoCount > 0;

  /// Patron de la fiche, avec repli sur le type de vêtement.
  SewingPattern get pattern =>
      resolvePatternSimple(patternId: patternId, garmentType: garmentType);

  bool get hasDeliveryDate => deliveryDate != null;

  /// Nombre de jours avant la livraison (0 = aujourd'hui, négatif = retard).
  int? daysUntilDelivery({DateTime? now}) {
    final date = deliveryDate;
    if (date == null) return null;
    return daysUntil(date, now: now);
  }

  MeasurementSheet copyWith({
    String? title,
    String? garmentType,
    String? patternId,
    DateTime? deliveryDate,
    bool clearDeliveryDate = false,
    Map<String, double>? measurements,
    List<CustomMeasurement>? customMeasurements,
    List<String>? fabricPhotos,
    List<String>? modelPhotos,
    String? notes,
    DateTime? updatedAt,
  }) {
    return MeasurementSheet(
      id: id,
      clientId: clientId,
      title: title ?? this.title,
      garmentType: garmentType ?? this.garmentType,
      patternId: patternId ?? this.patternId,
      deliveryDate: clearDeliveryDate
          ? null
          : (deliveryDate ?? this.deliveryDate),
      measurements: measurements ?? this.measurements,
      customMeasurements: customMeasurements ?? this.customMeasurements,
      fabricPhotos: fabricPhotos ?? this.fabricPhotos,
      modelPhotos: modelPhotos ?? this.modelPhotos,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MeasurementSheet.fromMap(Map<String, Object?> map) {
    final rawMeasurements =
        jsonDecode((map['measurements'] as String?) ?? '{}') as Map;
    final measurements = <String, double>{
      for (final entry in rawMeasurements.entries)
        if (entry.value is num)
          entry.key as String: (entry.value as num).toDouble(),
    };

    final rawCustom =
        jsonDecode((map['custom_measurements'] as String?) ?? '[]') as List;
    final custom = rawCustom
        .whereType<Map>()
        .map((item) => CustomMeasurement.fromJson(item.cast<String, Object?>()))
        .toList();

    final fabric =
        (jsonDecode((map['fabric_photos'] as String?) ?? '[]') as List)
            .whereType<String>()
            .toList();
    final model = (jsonDecode((map['model_photos'] as String?) ?? '[]') as List)
        .whereType<String>()
        .toList();

    final delivery = map['delivery_date'] as int?;

    return MeasurementSheet(
      id: map['id']! as String,
      clientId: map['client_id']! as String,
      title: map['title']! as String,
      garmentType: (map['garment_type'] as String?) ?? kGarmentTypes.last,
      patternId: map['pattern_id'] as String?,
      deliveryDate: delivery == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(delivery),
      measurements: measurements,
      customMeasurements: custom,
      fabricPhotos: fabric,
      modelPhotos: model,
      notes: (map['notes'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'title': title,
      'garment_type': garmentType,
      'pattern_id': patternId,
      'delivery_date': deliveryDate?.millisecondsSinceEpoch,
      'measurements': jsonEncode(measurements),
      'custom_measurements': jsonEncode(
        customMeasurements.map((m) => m.toJson()).toList(),
      ),
      'fabric_photos': jsonEncode(fabricPhotos),
      'model_photos': jsonEncode(modelPhotos),
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Mesures enregistrées qui ne font plus partie du formulaire principal.
  Map<String, double> get legacyMeasurements => {
    for (final entry in measurements.entries)
      if (!kFormMeasurementIds.contains(entry.key)) entry.key: entry.value,
  };

  /// Vrai si au moins une mesure de ce groupe a été renseignée.
  bool hasMeasurementsIn(MeasurementGroup group) =>
      group.fields.any((field) => measurements.containsKey(field.id));

  /// Résumé texte prêt à envoyer au client (WhatsApp, SMS…).
  String toShareText(String clientName) {
    final buffer = StringBuffer()
      ..writeln('FICHE DE MESURE — $clientName')
      ..writeln(title)
      ..writeln()
      ..writeln('PATRON — ${pattern.name}');

    final date = deliveryDate;
    if (date != null) {
      buffer.writeln(
        'LIVRAISON — ${formatFullDate(date)} '
        '(${formatDeliveryCountdown(date)})',
      );
    }
    buffer.writeln();

    for (final group in kMeasurementGroups) {
      final lines = <String>[];
      for (final field in group.fields) {
        final value = measurements[field.id];
        if (value != null) {
          lines.add('• ${field.label} : ${formatMeasure(value)} cm');
        }
      }
      if (lines.isNotEmpty) {
        buffer
          ..writeln(group.title.toUpperCase())
          ..writeln(lines.join('\n'))
          ..writeln();
      }
    }

    final legacy = legacyMeasurements;
    if (legacy.isNotEmpty) {
      buffer
        ..writeln('AUTRES MESURES')
        ..writeln(
          legacy.entries
              .map(
                (entry) =>
                    '• ${measurementLabel(entry.key)} : '
                    '${formatMeasure(entry.value)} cm',
              )
              .join('\n'),
        )
        ..writeln();
    }

    if (customMeasurements.isNotEmpty) {
      buffer
        ..writeln('MESURES LIBRES')
        ..writeln(
          customMeasurements
              .map((m) => '• ${m.label} : ${formatMeasure(m.value)} cm')
              .join('\n'),
        )
        ..writeln();
    }

    if (notes.trim().isNotEmpty) {
      buffer
        ..writeln('NOTES')
        ..writeln(notes.trim())
        ..writeln();
    }

    if (photoCount > 0) {
      buffer.writeln(
        'Photos : ${modelPhotos.length} modèle(s), '
        '${fabricPhotos.length} tissu(s)',
      );
    }

    return buffer.toString().trimRight();
  }
}

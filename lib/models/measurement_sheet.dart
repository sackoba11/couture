import 'dart:convert';

import 'measurement.dart';

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

/// Une fiche de mesure : le vêtement demandé, les mesures et les photos.
class MeasurementSheet {
  const MeasurementSheet({
    required this.id,
    required this.clientId,
    required this.title,
    required this.garmentType,
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

  MeasurementSheet copyWith({
    String? title,
    String? garmentType,
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

    return MeasurementSheet(
      id: map['id']! as String,
      clientId: map['client_id']! as String,
      title: map['title']! as String,
      garmentType: (map['garment_type'] as String?) ?? kGarmentTypes.last,
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

  /// Vrai si au moins une mesure de ce groupe a été renseignée.
  bool hasMeasurementsIn(MeasurementGroup group) =>
      group.fields.any((field) => measurements.containsKey(field.id));

  /// Résumé texte prêt à envoyer au client (WhatsApp, SMS…).
  String toShareText(String clientName) {
    final buffer = StringBuffer()
      ..writeln('FICHE DE MESURE — $clientName')
      ..writeln(title)
      ..writeln();

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

    if (customMeasurements.isNotEmpty) {
      buffer
        ..writeln('AUTRES MESURES')
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

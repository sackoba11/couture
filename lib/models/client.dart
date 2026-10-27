/// Un client de l'atelier.
class Client {
  const Client({
    required this.id,
    required this.fullName,
    this.phone = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String fullName;
  final String phone;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Initiales affichées dans l'avatar (ex. « Awa Diop » → « AD »).
  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Client copyWith({
    String? fullName,
    String? phone,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Client.fromMap(Map<String, Object?> map) {
    return Client(
      id: map['id']! as String,
      fullName: map['full_name']! as String,
      phone: (map['phone'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }
}

/// Client accompagné du nombre de fiches et de la dernière activité.
class ClientOverview {
  const ClientOverview({
    required this.client,
    required this.sheetCount,
    required this.lastActivity,
  });

  final Client client;
  final int sheetCount;
  final DateTime lastActivity;

  factory ClientOverview.fromMap(Map<String, Object?> map) {
    final client = Client.fromMap(map);
    final lastSheetAt = map['last_sheet_at'] as int?;
    return ClientOverview(
      client: client,
      sheetCount: (map['sheet_count'] as int?) ?? 0,
      lastActivity: lastSheetAt == null
          ? client.updatedAt
          : DateTime.fromMillisecondsSinceEpoch(lastSheetAt),
    );
  }
}

import 'json_values.dart';

/// Читательский билет. Сервер создаёт его сам и отдаёт вместе с читателем.
class LibraryCard {
  const LibraryCard({
    this.id,
    required this.number,
    required this.issuedAt,
    required this.expiresAt,
  });

  final int? id;
  final String number;
  final DateTime issuedAt;
  final DateTime expiresAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'issuedAt': issuedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
  };

  factory LibraryCard.fromJson(Object? json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : const {};
    return LibraryCard(
      id: map['id'] == null ? null : jsonInt(map['id']),
      number: jsonString(map['number']),
      issuedAt: jsonDate(map['issuedAt']) ?? DateTime.utc(1970),
      expiresAt: jsonDate(map['expiresAt']) ?? DateTime.utc(1970),
    );
  }
}

class Reader {
  const Reader({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.card,
    this.deletedAt,
  });

  final int id;
  final String fullName;
  final String email;
  final String phone;
  final LibraryCard? card;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Reader copyWith({
    String? fullName,
    String? email,
    String? phone,
    LibraryCard? card,
    bool clearCard = false,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Reader(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      card: clearCard ? null : (card ?? this.card),
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'card': card?.toJson(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Reader.fromJson(Map<String, dynamic> json) {
    return Reader(
      id: jsonInt(json['id']),
      fullName: jsonString(json['fullName']),
      email: jsonString(json['email']),
      phone: jsonString(json['phone']),
      card: json['card'] == null ? null : LibraryCard.fromJson(json['card']),
      deletedAt: jsonDate(json['deletedAt']),
    );
  }
}

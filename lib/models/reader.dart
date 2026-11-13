import 'json_values.dart';

/// Читательский билет. Отдельного экрана нет: он редактируется внутри читателя.
class LibraryCard {
  const LibraryCard({
    required this.number,
    required this.issuedAt,
    required this.expiresAt,
  });

  final String number;
  final DateTime issuedAt;
  final DateTime expiresAt;

  Map<String, dynamic> toJson() => {
    'number': number,
    'issuedAt': issuedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
  };

  factory LibraryCard.fromJson(Object? json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : const {};
    return LibraryCard(
      number: jsonString(map['number']),
      issuedAt: jsonDate(map['issuedAt']) ?? DateTime.utc(1970),
      expiresAt: jsonDate(map['expiresAt']) ?? DateTime.utc(1970),
    );
  }
}

class Reader {
  const Reader({
    required this.id,
    required this.lastName,
    required this.firstName,
    this.middleName = '',
    required this.email,
    required this.phone,
    required this.card,
    this.deletedAt,
  });

  final int id;
  final String lastName;
  final String firstName;
  final String middleName;
  final String email;
  final String phone;
  final LibraryCard card;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  String get fullName {
    final parts = <String>[
      lastName,
      firstName,
      if (middleName.isNotEmpty) middleName,
    ];
    return parts.join(' ');
  }

  Reader copyWith({
    String? lastName,
    String? firstName,
    String? middleName,
    String? email,
    String? phone,
    LibraryCard? card,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Reader(
      id: id,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      card: card ?? this.card,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'lastName': lastName,
    'firstName': firstName,
    'middleName': middleName,
    'email': email,
    'phone': phone,
    'card': card.toJson(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Reader.fromJson(Map<String, dynamic> json) {
    return Reader(
      id: jsonInt(json['id']),
      lastName: jsonString(json['lastName']),
      firstName: jsonString(json['firstName']),
      middleName: jsonString(json['middleName']),
      email: jsonString(json['email']),
      phone: jsonString(json['phone']),
      card: LibraryCard.fromJson(json['card']),
      deletedAt: jsonDate(json['deletedAt']),
    );
  }
}

import 'json_values.dart';

class Genre {
  const Genre({required this.id, required this.name, this.deletedAt});

  final int id;
  final String name;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Genre copyWith({
    String? name,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Genre(
      id: id,
      name: name ?? this.name,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: jsonInt(json['id']),
      name: jsonString(json['name']),
      deletedAt: jsonDate(json['deletedAt']),
    );
  }
}

class Publisher {
  const Publisher({
    required this.id,
    required this.name,
    required this.city,
    this.deletedAt,
  });

  final int id;
  final String name;
  final String city;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Publisher copyWith({
    String? name,
    String? city,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Publisher(
      id: id,
      name: name ?? this.name,
      city: city ?? this.city,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'city': city,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Publisher.fromJson(Map<String, dynamic> json) {
    return Publisher(
      id: jsonInt(json['id']),
      name: jsonString(json['name']),
      city: jsonString(json['city']),
      deletedAt: jsonDate(json['deletedAt']),
    );
  }
}

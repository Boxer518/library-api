import 'json_values.dart';

class Genre {
  const Genre({
    required this.id,
    required this.name,
    this.description = '',
    this.deletedAt,
  });

  final int id;
  final String name;
  final String description;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Genre copyWith({
    String? name,
    String? description,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Genre(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: jsonInt(json['id']),
      name: jsonString(json['name']),
      description: jsonString(json['description']),
      deletedAt: jsonDate(json['deletedAt']),
    );
  }
}

class Publisher {
  const Publisher({
    required this.id,
    required this.name,
    required this.city,
    this.foundedYear,
    this.deletedAt,
  });

  final int id;
  final String name;
  final String city;
  final int? foundedYear;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Publisher copyWith({
    String? name,
    String? city,
    int? foundedYear,
    bool clearFoundedYear = false,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Publisher(
      id: id,
      name: name ?? this.name,
      city: city ?? this.city,
      foundedYear: clearFoundedYear ? null : (foundedYear ?? this.foundedYear),
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'city': city,
    'foundedYear': foundedYear,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Publisher.fromJson(Map<String, dynamic> json) {
    return Publisher(
      id: jsonInt(json['id']),
      name: jsonString(json['name']),
      city: jsonString(json['city']),
      foundedYear: json['foundedYear'] == null
          ? null
          : jsonInt(json['foundedYear']),
      deletedAt: jsonDate(json['deletedAt']),
    );
  }
}

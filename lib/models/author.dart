import 'json_values.dart';

/// Автор. В учебном API одно поле `fullName`, а не фамилия и имя по отдельности.
class Author {
  const Author({
    required this.id,
    required this.fullName,
    required this.country,
    required this.birthYear,
    this.deletedAt,
  });

  final int id;
  final String fullName;
  final String country;
  final int birthYear;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Author copyWith({
    String? fullName,
    String? country,
    int? birthYear,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Author(
      id: id,
      fullName: fullName ?? this.fullName,
      country: country ?? this.country,
      birthYear: birthYear ?? this.birthYear,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'country': country,
    'birthYear': birthYear,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: jsonInt(json['id']),
      fullName: jsonString(json['fullName']),
      country: jsonString(json['country']),
      birthYear: jsonInt(json['birthYear']),
      deletedAt: jsonDate(json['deletedAt']),
    );
  }
}

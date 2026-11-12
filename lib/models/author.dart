/// Автор. Поиск в задании идёт по фамилии и стране.
class Author {
  const Author({
    required this.id,
    required this.lastName,
    required this.firstName,
    this.middleName = '',
    required this.country,
    required this.birthYear,
    this.deletedAt,
  });

  final int id;
  final String lastName;
  final String firstName;
  final String middleName;
  final String country;
  final int birthYear;
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

  Author copyWith({
    String? lastName,
    String? firstName,
    String? middleName,
    String? country,
    int? birthYear,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Author(
      id: id,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      country: country ?? this.country,
      birthYear: birthYear ?? this.birthYear,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}

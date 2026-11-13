import 'json_values.dart';

/// Книга каталога. Поля совпадают с моделью из методички.
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.isbn,
    required this.year,
    required this.pages,
    required this.publisherId,
    required this.authorIds,
    required this.genreIds,
    required this.copiesTotal,
    required this.copiesAvailable,
    this.deletedAt,
  });

  final int id;
  final String title;
  final String isbn;
  final int year;
  final int pages;
  final int publisherId;
  final List<int> authorIds;
  final List<int> genreIds;
  final int copiesTotal;
  final int copiesAvailable;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  /// [clearDeletedAt] отличает «поле не трогать» от «записать null».
  /// Обычный `deletedAt: null` в [copyWith] означает первое.
  Book copyWith({
    String? title,
    String? isbn,
    int? year,
    int? pages,
    int? publisherId,
    List<int>? authorIds,
    List<int>? genreIds,
    int? copiesTotal,
    int? copiesAvailable,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      isbn: isbn ?? this.isbn,
      year: year ?? this.year,
      pages: pages ?? this.pages,
      publisherId: publisherId ?? this.publisherId,
      authorIds: authorIds ?? this.authorIds,
      genreIds: genreIds ?? this.genreIds,
      copiesTotal: copiesTotal ?? this.copiesTotal,
      copiesAvailable: copiesAvailable ?? this.copiesAvailable,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isbn': isbn,
    'year': year,
    'pages': pages,
    'publisherId': publisherId,
    'authorIds': authorIds,
    'genreIds': genreIds,
    'copiesTotal': copiesTotal,
    'copiesAvailable': copiesAvailable,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: jsonInt(json['id']),
      title: jsonString(json['title']),
      isbn: jsonString(json['isbn']),
      year: jsonInt(json['year']),
      pages: jsonInt(json['pages']),
      publisherId: jsonInt(json['publisherId']),
      authorIds: jsonIntList(json['authorIds']),
      genreIds: jsonIntList(json['genreIds']),
      copiesTotal: jsonInt(json['copiesTotal']),
      copiesAvailable: jsonInt(json['copiesAvailable']),
      deletedAt: jsonDate(json['deletedAt']),
    );
  }
}

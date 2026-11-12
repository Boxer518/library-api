/// Все условия отбора книг. Объект целиком кладётся в адрес страницы.
class BookQuery {
  const BookQuery({
    this.search = '',
    this.genreId,
    this.publisherId,
    this.yearFrom,
    this.yearTo,
    this.sortField = 'title',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  final String search;
  final int? genreId;
  final int? publisherId;
  final int? yearFrom;
  final int? yearTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  static const allowedSortFields = {'title', 'year', 'pages'};
  static const allowedSizes = {10, 25, 50};

  bool get hasNarrowing =>
      search.trim().isNotEmpty ||
      genreId != null ||
      publisherId != null ||
      yearFrom != null ||
      yearTo != null ||
      includeDeleted;

  /// [_unset] отличает «аргумент не передали» от «передали null и сбрасываем фильтр».
  BookQuery copyWith({
    String? search,
    Object? genreId = _unset,
    Object? publisherId = _unset,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return BookQuery(
      search: search ?? this.search,
      genreId: genreId == _unset ? this.genreId : genreId as int?,
      publisherId: publisherId == _unset
          ? this.publisherId
          : publisherId as int?,
      yearFrom: yearFrom == _unset ? this.yearFrom : yearFrom as int?,
      yearTo: yearTo == _unset ? this.yearTo : yearTo as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      // Любое изменение условий отбора возвращает на первую страницу,
      // если номер страницы не передан явно.
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  factory BookQuery.fromParameters(Map<String, String> params) {
    final sort = _readSort(params['sort'], fallback: 'title');
    final size = int.tryParse(params['size'] ?? '');
    final page = int.tryParse(params['page'] ?? '');
    return BookQuery(
      search: params['search'] ?? '',
      genreId: _optionalId(params['genreId']),
      publisherId: _optionalId(params['publisherId']),
      yearFrom: int.tryParse(params['yearFrom'] ?? ''),
      yearTo: int.tryParse(params['yearTo'] ?? ''),
      sortField: allowedSortFields.contains(sort.$1) ? sort.$1 : 'title',
      sortAscending: sort.$2,
      page: page != null && page > 0 ? page : 1,
      size: size != null && allowedSizes.contains(size) ? size : 10,
      includeDeleted: params['includeDeleted'] == '1',
    );
  }

  Map<String, String> toParameters() {
    final params = <String, String>{};
    if (search.isNotEmpty) {
      params['search'] = search;
    }
    if (genreId != null) {
      params['genreId'] = '$genreId';
    }
    if (publisherId != null) {
      params['publisherId'] = '$publisherId';
    }
    if (yearFrom != null) {
      params['yearFrom'] = '$yearFrom';
    }
    if (yearTo != null) {
      params['yearTo'] = '$yearTo';
    }
    if (sortField != 'title' || !sortAscending) {
      params['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    }
    if (page != 1) {
      params['page'] = '$page';
    }
    if (size != 10) {
      params['size'] = '$size';
    }
    if (includeDeleted) {
      params['includeDeleted'] = '1';
    }
    return params;
  }

  String toLocation(String path) {
    final params = toParameters();
    return Uri(
      path: path,
      queryParameters: params.isEmpty ? null : params,
    ).toString();
  }

  @override
  bool operator ==(Object other) {
    return other is BookQuery &&
        other.search == search &&
        other.genreId == genreId &&
        other.publisherId == publisherId &&
        other.yearFrom == yearFrom &&
        other.yearTo == yearTo &&
        other.sortField == sortField &&
        other.sortAscending == sortAscending &&
        other.page == page &&
        other.size == size &&
        other.includeDeleted == includeDeleted;
  }

  @override
  int get hashCode => Object.hash(
    search,
    genreId,
    publisherId,
    yearFrom,
    yearTo,
    sortField,
    sortAscending,
    page,
    size,
    includeDeleted,
  );

  static const _unset = Object();
}

/// Ноль занят пунктом «все» в выпадающем списке, отрицательные id не бывают.
int? _optionalId(String? raw) {
  final id = int.tryParse(raw ?? '');
  if (id == null || id < 1) {
    return null;
  }
  return id;
}

(String, bool) _readSort(String? raw, {required String fallback}) {
  if (raw == null || !raw.contains(',')) {
    return (fallback, true);
  }
  final parts = raw.split(',');
  final field = parts.first.trim();
  final ascending = parts.length < 2 || parts[1].trim() != 'desc';
  if (field.isEmpty) {
    return (fallback, true);
  }
  return (field, ascending);
}

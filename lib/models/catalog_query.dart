/// Условия отбора для жанров, издательств и читателей.
class CatalogQuery {
  const CatalogQuery({
    this.search = '',
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  final String search;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  static const allowedSizes = {10, 25, 50};

  CatalogQuery copyWith({
    String? search,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return CatalogQuery(
      search: search ?? this.search,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  factory CatalogQuery.fromParameters(
    Map<String, String> params, {
    required String defaultSort,
    required Set<String> allowedSorts,
  }) {
    final sort = _readSort(params['sort'], fallback: defaultSort);
    final size = int.tryParse(params['size'] ?? '');
    final page = int.tryParse(params['page'] ?? '');
    return CatalogQuery(
      search: params['search'] ?? '',
      sortField: allowedSorts.contains(sort.$1) ? sort.$1 : defaultSort,
      sortAscending: sort.$2,
      page: page != null && page > 0 ? page : 1,
      size: size != null && allowedSizes.contains(size) ? size : 10,
      includeDeleted: params['includeDeleted'] == '1',
    );
  }

  Map<String, String> toParameters({required String defaultSort}) {
    final params = <String, String>{};
    if (search.isNotEmpty) {
      params['search'] = search;
    }
    if (sortField != defaultSort || !sortAscending) {
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

  String toLocation(String path, {required String defaultSort}) {
    final params = toParameters(defaultSort: defaultSort);
    return Uri(
      path: path,
      queryParameters: params.isEmpty ? null : params,
    ).toString();
  }

  @override
  bool operator ==(Object other) {
    return other is CatalogQuery &&
        other.search == search &&
        other.sortField == sortField &&
        other.sortAscending == sortAscending &&
        other.page == page &&
        other.size == size &&
        other.includeDeleted == includeDeleted;
  }

  @override
  int get hashCode =>
      Object.hash(search, sortField, sortAscending, page, size, includeDeleted);
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

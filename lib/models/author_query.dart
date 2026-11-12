/// Условия отбора авторов. В адресе живут так же, как фильтры книг.
class AuthorQuery {
  const AuthorQuery({
    this.search = '',
    this.sortField = 'lastName',
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

  static const allowedSortFields = {'lastName', 'country', 'birthYear'};
  static const allowedSizes = {10, 25, 50};

  AuthorQuery copyWith({
    String? search,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return AuthorQuery(
      search: search ?? this.search,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  factory AuthorQuery.fromParameters(Map<String, String> params) {
    final sort = _readSort(params['sort']);
    final size = int.tryParse(params['size'] ?? '');
    final page = int.tryParse(params['page'] ?? '');
    return AuthorQuery(
      search: params['search'] ?? '',
      sortField: allowedSortFields.contains(sort.$1) ? sort.$1 : 'lastName',
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
    if (sortField != 'lastName' || !sortAscending) {
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
    return other is AuthorQuery &&
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

(String, bool) _readSort(String? raw) {
  if (raw == null || !raw.contains(',')) {
    return ('lastName', true);
  }
  final parts = raw.split(',');
  final field = parts.first.trim();
  final ascending = parts.length < 2 || parts[1].trim() != 'desc';
  if (field.isEmpty) {
    return ('lastName', true);
  }
  return (field, ascending);
}

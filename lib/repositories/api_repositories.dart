import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/api_page.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/catalog_query.dart';
import '../models/json_values.dart';
import '../models/page_result.dart';
import '../models/reader.dart';
import '../models/reference.dart';
import 'author_repository.dart';
import 'book_repository.dart';
import 'in_memory_genre_repository.dart';
import 'in_memory_publisher_repository.dart';
import 'in_memory_reader_repository.dart';

/// Жанры, издательства, авторы и читатели нужны формам синхронно.
/// Их читаем один раз при старте и обновляем точечно после записи.
class ReferenceCache {
  final authors = <Author>[];
  final genres = <Genre>[];
  final publishers = <Publisher>[];
  final readers = <Reader>[];

  Future<void> warmUp(Dio dio) async {
    await _fill(
      authors,
      () => fetchAll(dio, '/authors', Author.fromJson, sortField: 'fullName'),
    );
    await _fill(
      genres,
      () => fetchAll(dio, '/genres', Genre.fromJson, sortField: 'name'),
    );
    await _fill(
      publishers,
      () => fetchAll(dio, '/publishers', Publisher.fromJson, sortField: 'name'),
    );
    await _fill(
      readers,
      () => fetchAll(dio, '/readers', Reader.fromJson, sortField: 'fullName'),
    );
  }

  Future<void> _fill<T>(List<T> target, Future<List<T>> Function() load) async {
    try {
      final loaded = await load();
      target
        ..clear()
        ..addAll(loaded);
    } on Object {
      // Сервер недоступен: кэш пустой, экран списка покажет ошибку сам.
    }
  }
}

class ApiBookRepository implements BookRepository {
  ApiBookRepository(Dio dio)
    : _store = _ApiStore(
        dio: dio,
        path: '/books',
        idOf: (book) => book.id,
        isDeleted: (book) => book.isDeleted,
      );

  final _ApiStore<Book> _store;

  @override
  Future<PageResult<Book>> find(BookQuery query) {
    return _store.find(
      search: query.search,
      sortField: query.sortField,
      sortAscending: query.sortAscending,
      page: query.page,
      size: query.size,
      includeDeleted: query.includeDeleted,
      extra: {
        if (query.genreId != null) 'genreId': query.genreId,
        if (query.publisherId != null) 'publisherId': query.publisherId,
        if (query.yearFrom != null) 'yearFrom': query.yearFrom,
        if (query.yearTo != null) 'yearTo': query.yearTo,
      },
      fromJson: Book.fromJson,
    );
  }

  @override
  Future<Book?> findById(int id) => _store.findById(id, Book.fromJson);

  @override
  Future<Book> create(Book book) =>
      _store.create(bookBody(book), Book.fromJson, fallback: book);

  @override
  Future<Book> update(Book book) =>
      _store.update(book.id, bookBody(book), Book.fromJson, fallback: book);

  @override
  Future<void> softDelete(int id) => _store.softDelete(
    id,
    Book.fromJson,
    (book) => book.copyWith(deletedAt: DateTime.now()),
  );

  @override
  Future<void> hardDelete(int id) => _store.hardDelete(id);

  @override
  Future<void> restore(int id) => _store.restore(
    id,
    Book.fromJson,
    (book) => book.copyWith(clearDeletedAt: true),
  );

  @override
  Future<int> deleteMany(List<int> ids) => _store.deleteMany(
    ids,
    (book) => book.copyWith(deletedAt: DateTime.now()),
  );

  @override
  List<Book> listAll({bool includeDeleted = false}) => const [];

  /// Уникальность ISBN решает сервер и возвращает 422 на поле.
  @override
  bool isbnTaken(String isbn, {int? exceptId}) => false;

  /// Связь с книгами проверяет сервер и отвечает 409.
  @override
  int countByPublisher(int publisherId) => 0;
}

Map<String, dynamic> bookBody(Book book) => {
  'title': book.title,
  'isbn': book.isbn,
  'year': book.year,
  'pages': book.pages,
  'publisherId': book.publisherId,
  'authorIds': book.authorIds,
  'genreIds': book.genreIds,
  'copiesTotal': book.copiesTotal,
};

class ApiAuthorRepository implements AuthorRepository {
  ApiAuthorRepository(Dio dio, ReferenceCache cache)
    : _store = _ApiStore(
        dio: dio,
        path: '/authors',
        rows: cache.authors,
        idOf: (author) => author.id,
        isDeleted: (author) => author.isDeleted,
      );

  final _ApiStore<Author> _store;

  @override
  Future<PageResult<Author>> find(AuthorQuery query) {
    return _store.find(
      search: query.search,
      sortField: query.sortField,
      sortAscending: query.sortAscending,
      page: query.page,
      size: query.size,
      includeDeleted: query.includeDeleted,
      fromJson: Author.fromJson,
    );
  }

  @override
  Future<Author?> findById(int id) => _store.findById(id, Author.fromJson);

  @override
  Future<Author> create(Author author) =>
      _store.create(authorBody(author), Author.fromJson, fallback: author);

  @override
  Future<Author> update(Author author) => _store.update(
    author.id,
    authorBody(author),
    Author.fromJson,
    fallback: author,
  );

  @override
  Future<void> softDelete(int id) => _store.softDelete(
    id,
    Author.fromJson,
    (author) => author.copyWith(deletedAt: DateTime.now()),
  );

  @override
  Future<void> hardDelete(int id) => _store.hardDelete(id);

  @override
  Future<void> restore(int id) => _store.restore(
    id,
    Author.fromJson,
    (author) => author.copyWith(clearDeletedAt: true),
  );

  @override
  Future<int> deleteMany(List<int> ids) => _store.deleteMany(
    ids,
    (author) => author.copyWith(deletedAt: DateTime.now()),
  );

  @override
  List<Author> listAll({bool includeDeleted = false}) =>
      _store.listAll(includeDeleted, (author) => author.isDeleted);
}

Map<String, dynamic> authorBody(Author author) => {
  'fullName': author.fullName,
  'country': author.country,
  'birthYear': author.birthYear,
};

class ApiGenreRepository implements GenreRepository {
  ApiGenreRepository(Dio dio, ReferenceCache cache)
    : _store = _ApiStore(
        dio: dio,
        path: '/genres',
        rows: cache.genres,
        idOf: (genre) => genre.id,
        isDeleted: (genre) => genre.isDeleted,
      );

  final _ApiStore<Genre> _store;

  @override
  Future<PageResult<Genre>> find(CatalogQuery query) => _find(query);

  Future<PageResult<Genre>> _find(CatalogQuery query) {
    return _store.find(
      search: query.search,
      sortField: query.sortField,
      sortAscending: query.sortAscending,
      page: query.page,
      size: query.size,
      includeDeleted: query.includeDeleted,
      fromJson: Genre.fromJson,
    );
  }

  @override
  Future<Genre?> findById(int id) => _store.findById(id, Genre.fromJson);

  @override
  Future<Genre> create(Genre genre) => _store.create(
    {'name': genre.name, 'description': genre.description},
    Genre.fromJson,
    fallback: genre,
  );

  @override
  Future<Genre> update(Genre genre) => _store.update(
    genre.id,
    {'name': genre.name, 'description': genre.description},
    Genre.fromJson,
    fallback: genre,
  );

  @override
  Future<void> softDelete(int id) => _store.softDelete(
    id,
    Genre.fromJson,
    (genre) => genre.copyWith(deletedAt: DateTime.now()),
  );

  @override
  Future<void> hardDelete(int id) => _store.hardDelete(id);

  @override
  Future<void> restore(int id) => _store.restore(
    id,
    Genre.fromJson,
    (genre) => genre.copyWith(clearDeletedAt: true),
  );

  @override
  Future<int> deleteMany(List<int> ids) => _store.deleteMany(
    ids,
    (genre) => genre.copyWith(deletedAt: DateTime.now()),
  );

  @override
  List<Genre> listAll({bool includeDeleted = false}) =>
      _store.listAll(includeDeleted, (genre) => genre.isDeleted);
}

class ApiPublisherRepository implements PublisherRepository {
  ApiPublisherRepository(Dio dio, ReferenceCache cache)
    : _store = _ApiStore(
        dio: dio,
        path: '/publishers',
        rows: cache.publishers,
        idOf: (publisher) => publisher.id,
        isDeleted: (publisher) => publisher.isDeleted,
      );

  final _ApiStore<Publisher> _store;

  @override
  Future<PageResult<Publisher>> find(CatalogQuery query) {
    return _store.find(
      search: query.search,
      sortField: query.sortField,
      sortAscending: query.sortAscending,
      page: query.page,
      size: query.size,
      includeDeleted: query.includeDeleted,
      fromJson: Publisher.fromJson,
    );
  }

  @override
  Future<Publisher?> findById(int id) =>
      _store.findById(id, Publisher.fromJson);

  @override
  Future<Publisher> create(Publisher publisher) => _store.create(
    {
      'name': publisher.name,
      'city': publisher.city,
      'foundedYear': publisher.foundedYear,
    },
    Publisher.fromJson,
    fallback: publisher,
  );

  @override
  Future<Publisher> update(Publisher publisher) => _store.update(
    publisher.id,
    {
      'name': publisher.name,
      'city': publisher.city,
      'foundedYear': publisher.foundedYear,
    },
    Publisher.fromJson,
    fallback: publisher,
  );

  @override
  Future<void> softDelete(int id) => _store.softDelete(
    id,
    Publisher.fromJson,
    (publisher) => publisher.copyWith(deletedAt: DateTime.now()),
  );

  @override
  Future<void> hardDelete(int id) => _store.hardDelete(id);

  @override
  Future<void> restore(int id) => _store.restore(
    id,
    Publisher.fromJson,
    (publisher) => publisher.copyWith(clearDeletedAt: true),
  );

  @override
  Future<int> deleteMany(List<int> ids) => _store.deleteMany(
    ids,
    (publisher) => publisher.copyWith(deletedAt: DateTime.now()),
  );

  @override
  List<Publisher> listAll({bool includeDeleted = false}) =>
      _store.listAll(includeDeleted, (publisher) => publisher.isDeleted);
}

class ApiReaderRepository implements ReaderRepository {
  ApiReaderRepository(Dio dio, ReferenceCache cache)
    : _store = _ApiStore(
        dio: dio,
        path: '/readers',
        rows: cache.readers,
        idOf: (reader) => reader.id,
        isDeleted: (reader) => reader.isDeleted,
      );

  final _ApiStore<Reader> _store;

  @override
  Future<PageResult<Reader>> find(CatalogQuery query) {
    return _store.find(
      search: query.search,
      sortField: query.sortField,
      sortAscending: query.sortAscending,
      page: query.page,
      size: query.size,
      includeDeleted: query.includeDeleted,
      fromJson: Reader.fromJson,
    );
  }

  @override
  Future<Reader?> findById(int id) => _store.findById(id, Reader.fromJson);

  @override
  Future<Reader> create(Reader reader) =>
      _store.create(readerBody(reader), Reader.fromJson, fallback: reader);

  @override
  Future<Reader> update(Reader reader) => _store.update(
    reader.id,
    readerBody(reader),
    Reader.fromJson,
    fallback: reader,
  );

  @override
  Future<void> softDelete(int id) => _store.softDelete(
    id,
    Reader.fromJson,
    (reader) => reader.copyWith(deletedAt: DateTime.now()),
  );

  @override
  Future<void> hardDelete(int id) => _store.hardDelete(id);

  @override
  Future<void> restore(int id) => _store.restore(
    id,
    Reader.fromJson,
    (reader) => reader.copyWith(clearDeletedAt: true),
  );

  @override
  Future<int> deleteMany(List<int> ids) => _store.deleteMany(
    ids,
    (reader) => reader.copyWith(deletedAt: DateTime.now()),
  );

  @override
  List<Reader> listAll({bool includeDeleted = false}) =>
      _store.listAll(includeDeleted, (reader) => reader.isDeleted);

  /// Повтор почты приходит с сервера как 422.
  @override
  bool emailTaken(String email, {int? exceptId}) => false;
}

Map<String, dynamic> readerBody(Reader reader) => {
  'fullName': reader.fullName,
  'email': reader.email,
  'phone': reader.phone,
};

class _ApiStore<T> {
  _ApiStore({
    required this.dio,
    required this.path,
    required this.idOf,
    required this.isDeleted,
    this.rows,
  });

  final Dio dio;
  final String path;
  final List<T>? rows;
  final int Function(T item) idOf;
  final bool Function(T item) isDeleted;
  CancelToken? _listToken;

  Future<PageResult<T>> find({
    required String search,
    required String sortField,
    required bool sortAscending,
    required int page,
    required int size,
    required bool includeDeleted,
    required T Function(Map<String, dynamic> json) fromJson,
    Map<String, dynamic>? extra,
  }) {
    _listToken?.cancel();
    final token = CancelToken();
    _listToken = token;
    return guard(() async {
      final response = await dio.get<dynamic>(
        path,
        queryParameters: pageQuery(
          search: search,
          sortField: sortField,
          sortAscending: sortAscending,
          page: page,
          size: size,
          includeDeleted: includeDeleted,
          extra: extra,
        ),
        cancelToken: token,
      );
      return parsePage(response.data, fromJson, fallbackSize: size);
    });
  }

  Future<T?> findById(
    int id,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    try {
      return await guard(() async {
        final response = await dio.get<dynamic>(
          '$path/$id',
          queryParameters: const {'includeDeleted': 'true'},
        );
        final item = fromJson(asJsonMap(response.data));
        _replace(item);
        return item;
      });
    } on NotFoundException {
      return null;
    }
  }

  Future<T> create(
    Map<String, dynamic> body,
    T Function(Map<String, dynamic> json) fromJson, {
    required T fallback,
  }) {
    return guard(() async {
      final response = await dio.post<dynamic>(path, data: body);
      final created = _read(response.data, fromJson, fallback);
      _replace(created);
      return created;
    });
  }

  Future<T> update(
    int id,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic> json) fromJson, {
    required T fallback,
  }) {
    return guard(() async {
      final response = await dio.put<dynamic>('$path/$id', data: body);
      final saved = _read(response.data, fromJson, fallback);
      _replace(saved);
      return saved;
    });
  }

  Future<void> softDelete(
    int id,
    T Function(Map<String, dynamic> json) fromJson,
    T Function(T item) markDeleted,
  ) {
    return guard(() async {
      final response = await dio.delete<dynamic>('$path/$id');
      final data = response.data;
      if (data is Map && data['id'] != null) {
        _replace(fromJson(Map<String, dynamic>.from(data)));
        return;
      }
      _touch(id, markDeleted);
    });
  }

  Future<void> hardDelete(int id) {
    return guard(() async {
      await dio.delete<dynamic>('$path/$id', queryParameters: {'hard': true});
      rows?.removeWhere((item) => idOf(item) == id);
    });
  }

  Future<void> restore(
    int id,
    T Function(Map<String, dynamic> json) fromJson,
    T Function(T item) markRestored,
  ) {
    return guard(() async {
      final response = await dio.post<dynamic>('$path/$id/restore');
      final data = response.data;
      if (data is Map && data['id'] != null) {
        _replace(fromJson(Map<String, dynamic>.from(data)));
        return;
      }
      _touch(id, markRestored);
    });
  }

  Future<int> deleteMany(List<int> ids, T Function(T item) markDeleted) {
    return guard(() async {
      final response = await dio.post<dynamic>(
        '$path/bulk-delete',
        data: {'ids': ids},
      );
      for (final id in ids) {
        _touch(id, (item) => isDeleted(item) ? item : markDeleted(item));
      }
      final data = response.data;
      if (data is Map && data['deleted'] != null) {
        return jsonInt(data['deleted'], ids.length);
      }
      return ids.length;
    });
  }

  List<T> listAll(bool includeDeleted, bool Function(T item) deleted) {
    final source = rows ?? <T>[];
    final visible = includeDeleted
        ? source
        : source.where((item) => !deleted(item));
    return List<T>.unmodifiable(visible);
  }

  T _read(
    Object? data,
    T Function(Map<String, dynamic> json) fromJson,
    T fallback,
  ) {
    if (data is Map && data.isNotEmpty) {
      return fromJson(Map<String, dynamic>.from(data));
    }
    return fallback;
  }

  void _replace(T item) {
    final target = rows;
    if (target == null) {
      return;
    }
    final id = idOf(item);
    final index = target.indexWhere((row) => idOf(row) == id);
    if (index == -1) {
      target.add(item);
    } else {
      target[index] = item;
    }
  }

  void _touch(int id, T Function(T item) change) {
    final target = rows;
    if (target == null) {
      return;
    }
    final index = target.indexWhere((row) => idOf(row) == id);
    if (index == -1) {
      return;
    }
    target[index] = change(target[index]);
  }
}

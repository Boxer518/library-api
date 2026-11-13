import '../data/seed.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/normalizers.dart';
import '../models/page_result.dart';
import 'book_repository.dart';
import 'paging.dart';

class InMemoryBookRepository implements BookRepository {
  InMemoryBookRepository({
    this.latency = const Duration(milliseconds: 250),
    List<Book>? books,
    this.persist,
  }) : _books = <Book>[...(books ?? seedBooks)],
       _nextId = _nextAfter(books ?? seedBooks);

  final Duration latency;
  final List<Book> _books;
  final Future<void> Function(List<Book> books)? persist;
  int _nextId;

  static int _nextAfter(List<Book> books) {
    var maxId = 0;
    for (final book in books) {
      if (book.id > maxId) {
        maxId = book.id;
      }
    }
    return maxId + 1;
  }

  Future<void> _save() async {
    await persist?.call(List<Book>.unmodifiable(_books));
  }

  @override
  Future<PageResult<Book>> find(BookQuery query) async {
    // Небольшая задержка имитирует сеть: без неё индикатор загрузки
    // невозможно увидеть, а в ПР4 он понадобится по-настоящему.
    await Future<void>.delayed(latency);

    var rows = _books
        .where((book) => query.includeDeleted || !book.isDeleted)
        .toList();

    final needle = query.search.trim().toLowerCase();
    if (needle.isNotEmpty) {
      rows = rows
          .where(
            (book) =>
                book.title.toLowerCase().contains(needle) ||
                book.isbn.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (query.genreId != null) {
      rows = rows
          .where((book) => book.genreIds.contains(query.genreId))
          .toList();
    }
    if (query.publisherId != null) {
      rows = rows
          .where((book) => book.publisherId == query.publisherId)
          .toList();
    }
    if (query.yearFrom != null) {
      rows = rows.where((book) => book.year >= query.yearFrom!).toList();
    }
    if (query.yearTo != null) {
      rows = rows.where((book) => book.year <= query.yearTo!).toList();
    }

    rows.sort((a, b) {
      final result = switch (query.sortField) {
        'year' => a.year.compareTo(b.year),
        'pages' => a.pages.compareTo(b.pages),
        _ => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      };
      final directed = query.sortAscending ? result : -result;
      if (directed != 0) {
        return directed;
      }
      return a.id.compareTo(b.id);
    });

    return slicePage(rows, page: query.page, size: query.size);
  }

  @override
  Future<Book?> findById(int id) async {
    await Future<void>.delayed(latency);
    for (final book in _books) {
      if (book.id == id) {
        return book;
      }
    }
    return null;
  }

  @override
  Future<Book> create(Book book) async {
    await Future<void>.delayed(latency);
    final created = Book(
      id: _nextId++,
      title: book.title,
      isbn: book.isbn,
      year: book.year,
      pages: book.pages,
      publisherId: book.publisherId,
      authorIds: List<int>.of(book.authorIds),
      genreIds: List<int>.of(book.genreIds),
      copiesTotal: book.copiesTotal,
      copiesAvailable: book.copiesAvailable,
      deletedAt: book.deletedAt,
    );
    _books.add(created);
    await _save();
    return created;
  }

  @override
  Future<Book> update(Book book) async {
    await Future<void>.delayed(latency);
    final index = _books.indexWhere((item) => item.id == book.id);
    if (index == -1) {
      throw StateError('Книга ${book.id} не найдена');
    }
    _books[index] = book;
    await _save();
    return book;
  }

  @override
  Future<void> softDelete(int id) async {
    await Future<void>.delayed(latency);
    final index = _books.indexWhere((book) => book.id == id);
    if (index == -1) {
      throw StateError('Книга $id не найдена');
    }
    _books[index] = _books[index].copyWith(deletedAt: DateTime.now());
    await _save();
  }

  @override
  Future<void> hardDelete(int id) async {
    await Future<void>.delayed(latency);
    _books.removeWhere((book) => book.id == id);
    await _save();
  }

  @override
  Future<void> restore(int id) async {
    await Future<void>.delayed(latency);
    final index = _books.indexWhere((book) => book.id == id);
    if (index == -1) {
      throw StateError('Книга $id не найдена');
    }
    _books[index] = _books[index].copyWith(clearDeletedAt: true);
    await _save();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    await Future<void>.delayed(latency);
    var count = 0;
    for (final id in ids) {
      // В методичке условие было `b.id == id && !b[i].isDeleted`.
      // `b` — это книга, а не список, оператора [] у неё нет, а `i`
      // внутри замыкания ещё не существует. Нужен флаг самой книги.
      final index = _books.indexWhere(
        (book) => book.id == id && !book.isDeleted,
      );
      if (index != -1) {
        _books[index] = _books[index].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _save();
    return count;
  }

  @override
  List<Book> listAll({bool includeDeleted = false}) {
    final rows = includeDeleted
        ? _books
        : _books.where((book) => !book.isDeleted);
    return List<Book>.unmodifiable(rows);
  }

  @override
  bool isbnTaken(String isbn, {int? exceptId}) {
    final needle = normalizeIsbn(isbn);
    if (needle.isEmpty) {
      return false;
    }
    return _books.any(
      (book) => book.id != exceptId && normalizeIsbn(book.isbn) == needle,
    );
  }

  @override
  int countByPublisher(int publisherId) {
    return _books.where((book) => book.publisherId == publisherId).length;
  }
}

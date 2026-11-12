import '../data/seed.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../models/page_result.dart';
import 'author_repository.dart';
import 'paging.dart';

class InMemoryAuthorRepository implements AuthorRepository {
  InMemoryAuthorRepository({this.latency = const Duration(milliseconds: 250)})
    : _authors = <Author>[...seedAuthors],
      _nextId = seedAuthors.length + 1;

  final Duration latency;
  final List<Author> _authors;
  int _nextId;

  @override
  Future<PageResult<Author>> find(AuthorQuery query) async {
    await Future<void>.delayed(latency);

    var rows = _authors
        .where((author) => query.includeDeleted || !author.isDeleted)
        .toList();

    final needle = query.search.trim().toLowerCase();
    if (needle.isNotEmpty) {
      rows = rows
          .where(
            (author) =>
                author.lastName.toLowerCase().contains(needle) ||
                author.country.toLowerCase().contains(needle),
          )
          .toList();
    }

    rows.sort((a, b) {
      var result = switch (query.sortField) {
        'country' => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        'birthYear' => a.birthYear.compareTo(b.birthYear),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      };
      if (result == 0) {
        result = a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
      }
      final directed = query.sortAscending ? result : -result;
      if (directed != 0) {
        return directed;
      }
      return a.id.compareTo(b.id);
    });

    return slicePage(rows, page: query.page, size: query.size);
  }

  @override
  Future<Author?> findById(int id) async {
    await Future<void>.delayed(latency);
    for (final author in _authors) {
      if (author.id == id) {
        return author;
      }
    }
    return null;
  }

  @override
  Future<Author> create(Author author) async {
    await Future<void>.delayed(latency);
    final created = Author(
      id: _nextId++,
      lastName: author.lastName,
      firstName: author.firstName,
      middleName: author.middleName,
      country: author.country,
      birthYear: author.birthYear,
      deletedAt: author.deletedAt,
    );
    _authors.add(created);
    return created;
  }

  @override
  Future<Author> update(Author author) async {
    await Future<void>.delayed(latency);
    final index = _authors.indexWhere((item) => item.id == author.id);
    if (index == -1) {
      throw StateError('Автор ${author.id} не найден');
    }
    _authors[index] = author;
    return author;
  }

  @override
  Future<void> softDelete(int id) async {
    await Future<void>.delayed(latency);
    final index = _authors.indexWhere((author) => author.id == id);
    if (index == -1) {
      throw StateError('Автор $id не найден');
    }
    _authors[index] = _authors[index].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    await Future<void>.delayed(latency);
    _authors.removeWhere((author) => author.id == id);
  }

  @override
  Future<void> restore(int id) async {
    await Future<void>.delayed(latency);
    final index = _authors.indexWhere((author) => author.id == id);
    if (index == -1) {
      throw StateError('Автор $id не найден');
    }
    _authors[index] = _authors[index].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    await Future<void>.delayed(latency);
    var count = 0;
    for (final id in ids) {
      final index = _authors.indexWhere(
        (author) => author.id == id && !author.isDeleted,
      );
      if (index != -1) {
        _authors[index] = _authors[index].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }
}

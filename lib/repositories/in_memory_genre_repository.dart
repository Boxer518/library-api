import '../data/seed.dart';
import '../models/catalog_query.dart';
import '../models/page_result.dart';
import '../models/reference.dart';
import 'paging.dart';

abstract interface class GenreRepository {
  Future<PageResult<Genre>> find(CatalogQuery query);
  Future<Genre?> findById(int id);
  Future<Genre> create(Genre genre);
  Future<Genre> update(Genre genre);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  List<Genre> listAll({bool includeDeleted = false});
}

class InMemoryGenreRepository implements GenreRepository {
  InMemoryGenreRepository({
    this.latency = const Duration(milliseconds: 250),
    List<Genre>? genres,
    this.persist,
  }) : _genres = <Genre>[...(genres ?? seedGenres())],
       _nextId = _nextAfter(genres ?? seedGenres());

  final Duration latency;
  final List<Genre> _genres;
  final Future<void> Function(List<Genre> genres)? persist;
  int _nextId;

  static List<Genre> seedGenres() => <Genre>[...genres];

  static int _nextAfter(List<Genre> items) {
    var maxId = 0;
    for (final item in items) {
      if (item.id > maxId) {
        maxId = item.id;
      }
    }
    return maxId + 1;
  }

  Future<void> _save() async {
    await persist?.call(List<Genre>.unmodifiable(_genres));
  }

  @override
  Future<PageResult<Genre>> find(CatalogQuery query) async {
    await Future<void>.delayed(latency);
    var rows = _genres
        .where((genre) => query.includeDeleted || !genre.isDeleted)
        .toList();
    final needle = query.search.trim().toLowerCase();
    if (needle.isNotEmpty) {
      rows = rows
          .where((genre) => genre.name.toLowerCase().contains(needle))
          .toList();
    }
    rows.sort((a, b) {
      final result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      final directed = query.sortAscending ? result : -result;
      if (directed != 0) {
        return directed;
      }
      return a.id.compareTo(b.id);
    });
    return slicePage(rows, page: query.page, size: query.size);
  }

  @override
  Future<Genre?> findById(int id) async {
    await Future<void>.delayed(latency);
    for (final genre in _genres) {
      if (genre.id == id) {
        return genre;
      }
    }
    return null;
  }

  @override
  Future<Genre> create(Genre genre) async {
    await Future<void>.delayed(latency);
    final created = Genre(
      id: _nextId++,
      name: genre.name,
      deletedAt: genre.deletedAt,
    );
    _genres.add(created);
    await _save();
    return created;
  }

  @override
  Future<Genre> update(Genre genre) async {
    await Future<void>.delayed(latency);
    final index = _genres.indexWhere((item) => item.id == genre.id);
    if (index == -1) {
      throw StateError('Жанр ${genre.id} не найден');
    }
    _genres[index] = genre;
    await _save();
    return genre;
  }

  @override
  Future<void> softDelete(int id) async {
    await Future<void>.delayed(latency);
    final index = _genres.indexWhere((genre) => genre.id == id);
    if (index == -1) {
      throw StateError('Жанр $id не найден');
    }
    _genres[index] = _genres[index].copyWith(deletedAt: DateTime.now());
    await _save();
  }

  @override
  Future<void> hardDelete(int id) async {
    await Future<void>.delayed(latency);
    _genres.removeWhere((genre) => genre.id == id);
    await _save();
  }

  @override
  Future<void> restore(int id) async {
    await Future<void>.delayed(latency);
    final index = _genres.indexWhere((genre) => genre.id == id);
    if (index == -1) {
      throw StateError('Жанр $id не найден');
    }
    _genres[index] = _genres[index].copyWith(clearDeletedAt: true);
    await _save();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    await Future<void>.delayed(latency);
    var count = 0;
    for (final id in ids) {
      final index = _genres.indexWhere(
        (genre) => genre.id == id && !genre.isDeleted,
      );
      if (index != -1) {
        _genres[index] = _genres[index].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _save();
    return count;
  }

  @override
  List<Genre> listAll({bool includeDeleted = false}) {
    final rows = includeDeleted
        ? _genres
        : _genres.where((genre) => !genre.isDeleted);
    return List<Genre>.unmodifiable(rows);
  }
}

import '../data/seed.dart';
import '../models/catalog_query.dart';
import '../models/normalizers.dart';
import '../models/page_result.dart';
import '../models/reader.dart';
import 'paging.dart';

abstract interface class ReaderRepository {
  Future<PageResult<Reader>> find(CatalogQuery query);
  Future<Reader?> findById(int id);
  Future<Reader> create(Reader reader);
  Future<Reader> update(Reader reader);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  List<Reader> listAll({bool includeDeleted = false});
  bool emailTaken(String email, {int? exceptId});
}

class InMemoryReaderRepository implements ReaderRepository {
  InMemoryReaderRepository({
    this.latency = const Duration(milliseconds: 250),
    List<Reader>? readers,
    this.persist,
  }) : _readers = <Reader>[...(readers ?? seedReaders)],
       _nextId = _nextAfter(readers ?? seedReaders);

  final Duration latency;
  final List<Reader> _readers;
  final Future<void> Function(List<Reader> readers)? persist;
  int _nextId;

  static int _nextAfter(List<Reader> items) {
    var maxId = 0;
    for (final item in items) {
      if (item.id > maxId) {
        maxId = item.id;
      }
    }
    return maxId + 1;
  }

  Future<void> _save() async {
    await persist?.call(List<Reader>.unmodifiable(_readers));
  }

  @override
  Future<PageResult<Reader>> find(CatalogQuery query) async {
    await Future<void>.delayed(latency);
    var rows = _readers
        .where((reader) => query.includeDeleted || !reader.isDeleted)
        .toList();
    final needle = query.search.trim().toLowerCase();
    if (needle.isNotEmpty) {
      rows = rows.where((reader) {
        return reader.lastName.toLowerCase().contains(needle) ||
            reader.email.toLowerCase().contains(needle) ||
            reader.card.number.toLowerCase().contains(needle);
      }).toList();
    }
    rows.sort((a, b) {
      final result = switch (query.sortField) {
        'email' => a.email.toLowerCase().compareTo(b.email.toLowerCase()),
        'card' => a.card.number.toLowerCase().compareTo(
          b.card.number.toLowerCase(),
        ),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
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
  Future<Reader?> findById(int id) async {
    await Future<void>.delayed(latency);
    for (final reader in _readers) {
      if (reader.id == id) {
        return reader;
      }
    }
    return null;
  }

  @override
  Future<Reader> create(Reader reader) async {
    await Future<void>.delayed(latency);
    final created = Reader(
      id: _nextId++,
      lastName: reader.lastName,
      firstName: reader.firstName,
      middleName: reader.middleName,
      email: reader.email,
      phone: reader.phone,
      card: reader.card,
      deletedAt: reader.deletedAt,
    );
    _readers.add(created);
    await _save();
    return created;
  }

  @override
  Future<Reader> update(Reader reader) async {
    await Future<void>.delayed(latency);
    final index = _readers.indexWhere((item) => item.id == reader.id);
    if (index == -1) {
      throw StateError('Читатель ${reader.id} не найден');
    }
    _readers[index] = reader;
    await _save();
    return reader;
  }

  @override
  Future<void> softDelete(int id) async {
    await Future<void>.delayed(latency);
    final index = _readers.indexWhere((reader) => reader.id == id);
    if (index == -1) {
      throw StateError('Читатель $id не найден');
    }
    _readers[index] = _readers[index].copyWith(deletedAt: DateTime.now());
    await _save();
  }

  @override
  Future<void> hardDelete(int id) async {
    await Future<void>.delayed(latency);
    _readers.removeWhere((reader) => reader.id == id);
    await _save();
  }

  @override
  Future<void> restore(int id) async {
    await Future<void>.delayed(latency);
    final index = _readers.indexWhere((reader) => reader.id == id);
    if (index == -1) {
      throw StateError('Читатель $id не найден');
    }
    _readers[index] = _readers[index].copyWith(clearDeletedAt: true);
    await _save();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    await Future<void>.delayed(latency);
    var count = 0;
    for (final id in ids) {
      final index = _readers.indexWhere(
        (reader) => reader.id == id && !reader.isDeleted,
      );
      if (index != -1) {
        _readers[index] = _readers[index].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _save();
    return count;
  }

  @override
  List<Reader> listAll({bool includeDeleted = false}) {
    final rows = includeDeleted
        ? _readers
        : _readers.where((reader) => !reader.isDeleted);
    return List<Reader>.unmodifiable(rows);
  }

  @override
  bool emailTaken(String email, {int? exceptId}) {
    final needle = normalizeEmail(email);
    if (needle.isEmpty) {
      return false;
    }
    return _readers.any(
      (reader) =>
          reader.id != exceptId && normalizeEmail(reader.email) == needle,
    );
  }
}

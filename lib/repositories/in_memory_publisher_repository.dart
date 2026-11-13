import '../data/seed.dart';
import '../models/catalog_query.dart';
import '../models/page_result.dart';
import '../models/reference.dart';
import 'paging.dart';

abstract interface class PublisherRepository {
  Future<PageResult<Publisher>> find(CatalogQuery query);
  Future<Publisher?> findById(int id);
  Future<Publisher> create(Publisher publisher);
  Future<Publisher> update(Publisher publisher);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  List<Publisher> listAll({bool includeDeleted = false});
}

class InMemoryPublisherRepository implements PublisherRepository {
  InMemoryPublisherRepository({
    this.latency = const Duration(milliseconds: 250),
    List<Publisher>? publishers,
    this.persist,
  }) : _publishers = <Publisher>[...(publishers ?? seedPublishers())],
       _nextId = _nextAfter(publishers ?? seedPublishers());

  final Duration latency;
  final List<Publisher> _publishers;
  final Future<void> Function(List<Publisher> publishers)? persist;
  int _nextId;

  static List<Publisher> seedPublishers() => <Publisher>[...publishers];

  static int _nextAfter(List<Publisher> items) {
    var maxId = 0;
    for (final item in items) {
      if (item.id > maxId) {
        maxId = item.id;
      }
    }
    return maxId + 1;
  }

  Future<void> _save() async {
    await persist?.call(List<Publisher>.unmodifiable(_publishers));
  }

  @override
  Future<PageResult<Publisher>> find(CatalogQuery query) async {
    await Future<void>.delayed(latency);
    var rows = _publishers
        .where((publisher) => query.includeDeleted || !publisher.isDeleted)
        .toList();
    final needle = query.search.trim().toLowerCase();
    if (needle.isNotEmpty) {
      rows = rows
          .where(
            (publisher) =>
                publisher.name.toLowerCase().contains(needle) ||
                publisher.city.toLowerCase().contains(needle),
          )
          .toList();
    }
    rows.sort((a, b) {
      final result = switch (query.sortField) {
        'city' => a.city.toLowerCase().compareTo(b.city.toLowerCase()),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
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
  Future<Publisher?> findById(int id) async {
    await Future<void>.delayed(latency);
    for (final publisher in _publishers) {
      if (publisher.id == id) {
        return publisher;
      }
    }
    return null;
  }

  @override
  Future<Publisher> create(Publisher publisher) async {
    await Future<void>.delayed(latency);
    final created = Publisher(
      id: _nextId++,
      name: publisher.name,
      city: publisher.city,
      deletedAt: publisher.deletedAt,
    );
    _publishers.add(created);
    await _save();
    return created;
  }

  @override
  Future<Publisher> update(Publisher publisher) async {
    await Future<void>.delayed(latency);
    final index = _publishers.indexWhere((item) => item.id == publisher.id);
    if (index == -1) {
      throw StateError('Издательство ${publisher.id} не найдено');
    }
    _publishers[index] = publisher;
    await _save();
    return publisher;
  }

  @override
  Future<void> softDelete(int id) async {
    await Future<void>.delayed(latency);
    final index = _publishers.indexWhere((publisher) => publisher.id == id);
    if (index == -1) {
      throw StateError('Издательство $id не найдено');
    }
    _publishers[index] = _publishers[index].copyWith(deletedAt: DateTime.now());
    await _save();
  }

  @override
  Future<void> hardDelete(int id) async {
    await Future<void>.delayed(latency);
    _publishers.removeWhere((publisher) => publisher.id == id);
    await _save();
  }

  @override
  Future<void> restore(int id) async {
    await Future<void>.delayed(latency);
    final index = _publishers.indexWhere((publisher) => publisher.id == id);
    if (index == -1) {
      throw StateError('Издательство $id не найдено');
    }
    _publishers[index] = _publishers[index].copyWith(clearDeletedAt: true);
    await _save();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    await Future<void>.delayed(latency);
    var count = 0;
    for (final id in ids) {
      final index = _publishers.indexWhere(
        (publisher) => publisher.id == id && !publisher.isDeleted,
      );
      if (index != -1) {
        _publishers[index] = _publishers[index].copyWith(
          deletedAt: DateTime.now(),
        );
        count++;
      }
    }
    await _save();
    return count;
  }

  @override
  List<Publisher> listAll({bool includeDeleted = false}) {
    final rows = includeDeleted
        ? _publishers
        : _publishers.where((publisher) => !publisher.isDeleted);
    return List<Publisher>.unmodifiable(rows);
  }
}

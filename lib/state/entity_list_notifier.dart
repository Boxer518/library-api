import 'package:flutter/foundation.dart';

import '../models/page_result.dart';
import 'load_status.dart';

/// Общее состояние списка: загрузка, страница, выделение.
/// Книги и авторы отличаются только типом записи и запросом.
class EntityListNotifier<T, Q> extends ChangeNotifier {
  EntityListNotifier({
    required Q initialQuery,
    required this.find,
    required this.deleteManyItems,
    required this.softDeleteItem,
    required this.hardDeleteItem,
    required this.restoreItem,
  }) : _query = initialQuery;

  final Future<PageResult<T>> Function(Q query) find;
  final Future<int> Function(List<int> ids) deleteManyItems;
  final Future<void> Function(int id) softDeleteItem;
  final Future<void> Function(int id) hardDeleteItem;
  final Future<void> Function(int id) restoreItem;

  Q _query;
  PageResult<T> _result = PageResult<T>.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = <int>{};
  int _request = 0;

  Q get query => _query;
  PageResult<T> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set<int>.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    final request = ++_request;
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final page = await find(_query);
      if (request != _request) {
        return;
      }
      _result = page;
      _status = LoadStatus.success;
    } catch (error) {
      if (request != _request) {
        return;
      }
      _result = PageResult<T>.empty();
      _error = 'Не удалось загрузить список: $error';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(Q next) async {
    _query = next;
    _selected.clear();
    await load();
  }

  /// Отдельный путь ошибки: хранилище в памяти само не падает,
  /// а состояние «ошибка» нужно показать и отличить от пустого списка.
  Future<void> demonstrateError() async {
    final request = ++_request;
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (request != _request) {
      return;
    }
    _result = PageResult<T>.empty();
    _error = 'Не удалось загрузить список: StateError: демонстрационный сбой';
    _status = LoadStatus.error;
    notifyListeners();
  }

  void toggleSelection(int id) {
    if (!_selected.add(id)) {
      _selected.remove(id);
    }
    notifyListeners();
  }

  void selectMany(Iterable<int> ids) {
    _selected.addAll(ids);
    notifyListeners();
  }

  void clearSelection() {
    if (_selected.isEmpty) {
      return;
    }
    _selected.clear();
    notifyListeners();
  }

  Future<int> deleteSelected() async {
    final count = await deleteManyItems(_selected.toList());
    _selected.clear();
    await load();
    return count;
  }

  Future<void> softDelete(int id) async {
    await softDeleteItem(id);
    _selected.remove(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await hardDeleteItem(id);
    _selected.remove(id);
    await load();
  }

  Future<void> restore(int id) async {
    await restoreItem(id);
    await load();
  }
}

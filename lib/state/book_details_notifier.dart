import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../repositories/book_repository.dart';
import 'load_status.dart';

class BookDetailsNotifier extends ChangeNotifier {
  BookDetailsNotifier(this._repository, this.id);

  final BookRepository _repository;
  final int id;

  Book? _book;
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  var _disposed = false;

  Book? get book => _book;
  LoadStatus get status => _status;
  String? get error => _error;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _publish() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    _publish();
    try {
      final book = await _repository.findById(id);
      if (_disposed) {
        return;
      }
      _book = book;
      if (_book == null) {
        _status = LoadStatus.error;
        _error = 'Книга не найдена';
      } else {
        _status = LoadStatus.success;
      }
    } catch (error) {
      if (_disposed) {
        return;
      }
      _status = LoadStatus.error;
      _error = 'Не удалось загрузить карточку: $error';
    }
    _publish();
  }

  Future<void> softDelete() async {
    await _repository.softDelete(id);
    await load();
  }

  Future<void> hardDelete() async {
    await _repository.hardDelete(id);
  }

  Future<void> restore() async {
    await _repository.restore(id);
    await load();
  }
}

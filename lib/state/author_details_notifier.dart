import 'package:flutter/foundation.dart';

import '../models/author.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../repositories/author_repository.dart';
import '../repositories/book_repository.dart';
import 'load_status.dart';

class AuthorDetailsNotifier extends ChangeNotifier {
  AuthorDetailsNotifier(this._authors, this._books, this.id);

  final AuthorRepository _authors;
  final BookRepository _books;
  final int id;

  Author? _author;
  List<Book> _written = const <Book>[];
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  var _disposed = false;

  Author? get author => _author;
  List<Book> get written => _written;
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
      final author = await _authors.findById(id);
      if (_disposed) {
        return;
      }
      _author = author;
      if (_author == null) {
        _written = const <Book>[];
        _status = LoadStatus.error;
        _error = 'Автор не найден';
      } else {
        final written = <Book>[];
        var page = 1;
        while (true) {
          final result = await _books.find(
            BookQuery(page: page, size: 50, includeDeleted: true),
          );
          if (_disposed) {
            return;
          }
          written.addAll(
            result.items.where((book) => book.authorIds.contains(id)),
          );
          if (!result.hasNext) {
            break;
          }
          page++;
        }
        _written = written;
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
    await _authors.softDelete(id);
    await load();
  }

  Future<void> hardDelete() async {
    await _authors.hardDelete(id);
  }

  Future<void> restore() async {
    await _authors.restore(id);
    await load();
  }
}

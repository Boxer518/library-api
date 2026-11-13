import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed.dart';
import '../models/author.dart';
import '../models/book.dart';
import '../models/page_result.dart';
import '../models/reader.dart';
import '../models/reference.dart';
import '../storage/persisted_list.dart';
import '../storage/storage_keys.dart';
import '../storage/storage_notice.dart';
import 'author_repository.dart';
import 'book_repository.dart';
import 'in_memory_author_repository.dart';
import 'in_memory_book_repository.dart';
import 'in_memory_genre_repository.dart';
import 'in_memory_publisher_repository.dart';
import 'in_memory_reader_repository.dart';

class PersistentBookRepository implements BookRepository {
  PersistentBookRepository._(this._inner);

  final InMemoryBookRepository _inner;

  static Future<PersistentBookRepository> open(
    SharedPreferences prefs,
    StorageNotice notice,
  ) async {
    final store = PersistedList<Book>(
      prefs: prefs,
      key: booksKey,
      seed: seedBooks,
      fromJson: Book.fromJson,
      toJson: (book) => book.toJson(),
      notice: notice,
    );
    final loaded = store.load();
    final inner = InMemoryBookRepository(
      books: loaded.items,
      persist: store.save,
    );
    if (loaded.shouldPersist) {
      await store.save(inner.listAll(includeDeleted: true));
    }
    return PersistentBookRepository._(inner);
  }

  @override
  Future<PageResult<Book>> find(query) => _inner.find(query);

  @override
  Future<Book?> findById(int id) => _inner.findById(id);

  @override
  Future<Book> create(Book book) => _inner.create(book);

  @override
  Future<Book> update(Book book) => _inner.update(book);

  @override
  Future<void> softDelete(int id) => _inner.softDelete(id);

  @override
  Future<void> hardDelete(int id) => _inner.hardDelete(id);

  @override
  Future<void> restore(int id) => _inner.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) => _inner.deleteMany(ids);

  @override
  List<Book> listAll({bool includeDeleted = false}) =>
      _inner.listAll(includeDeleted: includeDeleted);

  @override
  bool isbnTaken(String isbn, {int? exceptId}) =>
      _inner.isbnTaken(isbn, exceptId: exceptId);

  @override
  int countByPublisher(int publisherId) => _inner.countByPublisher(publisherId);
}

class PersistentAuthorRepository implements AuthorRepository {
  PersistentAuthorRepository._(this._inner);

  final InMemoryAuthorRepository _inner;

  static Future<PersistentAuthorRepository> open(
    SharedPreferences prefs,
    StorageNotice notice,
  ) async {
    final store = PersistedList<Author>(
      prefs: prefs,
      key: authorsKey,
      seed: seedAuthors,
      fromJson: Author.fromJson,
      toJson: (author) => author.toJson(),
      notice: notice,
    );
    final loaded = store.load();
    final inner = InMemoryAuthorRepository(
      authors: loaded.items,
      persist: store.save,
    );
    if (loaded.shouldPersist) {
      await store.save(inner.listAll(includeDeleted: true));
    }
    return PersistentAuthorRepository._(inner);
  }

  @override
  Future<PageResult<Author>> find(query) => _inner.find(query);

  @override
  Future<Author?> findById(int id) => _inner.findById(id);

  @override
  Future<Author> create(Author author) => _inner.create(author);

  @override
  Future<Author> update(Author author) => _inner.update(author);

  @override
  Future<void> softDelete(int id) => _inner.softDelete(id);

  @override
  Future<void> hardDelete(int id) => _inner.hardDelete(id);

  @override
  Future<void> restore(int id) => _inner.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) => _inner.deleteMany(ids);

  @override
  List<Author> listAll({bool includeDeleted = false}) =>
      _inner.listAll(includeDeleted: includeDeleted);
}

class PersistentGenreRepository implements GenreRepository {
  PersistentGenreRepository._(this._inner);

  final InMemoryGenreRepository _inner;

  static Future<PersistentGenreRepository> open(
    SharedPreferences prefs,
    StorageNotice notice,
  ) async {
    final store = PersistedList<Genre>(
      prefs: prefs,
      key: genresKey,
      seed: genres,
      fromJson: Genre.fromJson,
      toJson: (genre) => genre.toJson(),
      notice: notice,
    );
    final loaded = store.load();
    final inner = InMemoryGenreRepository(
      genres: loaded.items,
      persist: store.save,
    );
    if (loaded.shouldPersist) {
      await store.save(inner.listAll(includeDeleted: true));
    }
    return PersistentGenreRepository._(inner);
  }

  @override
  Future<PageResult<Genre>> find(query) => _inner.find(query);

  @override
  Future<Genre?> findById(int id) => _inner.findById(id);

  @override
  Future<Genre> create(Genre genre) => _inner.create(genre);

  @override
  Future<Genre> update(Genre genre) => _inner.update(genre);

  @override
  Future<void> softDelete(int id) => _inner.softDelete(id);

  @override
  Future<void> hardDelete(int id) => _inner.hardDelete(id);

  @override
  Future<void> restore(int id) => _inner.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) => _inner.deleteMany(ids);

  @override
  List<Genre> listAll({bool includeDeleted = false}) =>
      _inner.listAll(includeDeleted: includeDeleted);
}

class PersistentPublisherRepository implements PublisherRepository {
  PersistentPublisherRepository._(this._inner);

  final InMemoryPublisherRepository _inner;

  static Future<PersistentPublisherRepository> open(
    SharedPreferences prefs,
    StorageNotice notice,
  ) async {
    final store = PersistedList<Publisher>(
      prefs: prefs,
      key: publishersKey,
      seed: publishers,
      fromJson: Publisher.fromJson,
      toJson: (publisher) => publisher.toJson(),
      notice: notice,
    );
    final loaded = store.load();
    final inner = InMemoryPublisherRepository(
      publishers: loaded.items,
      persist: store.save,
    );
    if (loaded.shouldPersist) {
      await store.save(inner.listAll(includeDeleted: true));
    }
    return PersistentPublisherRepository._(inner);
  }

  @override
  Future<PageResult<Publisher>> find(query) => _inner.find(query);

  @override
  Future<Publisher?> findById(int id) => _inner.findById(id);

  @override
  Future<Publisher> create(Publisher publisher) => _inner.create(publisher);

  @override
  Future<Publisher> update(Publisher publisher) => _inner.update(publisher);

  @override
  Future<void> softDelete(int id) => _inner.softDelete(id);

  @override
  Future<void> hardDelete(int id) => _inner.hardDelete(id);

  @override
  Future<void> restore(int id) => _inner.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) => _inner.deleteMany(ids);

  @override
  List<Publisher> listAll({bool includeDeleted = false}) =>
      _inner.listAll(includeDeleted: includeDeleted);
}

class PersistentReaderRepository implements ReaderRepository {
  PersistentReaderRepository._(this._inner);

  final InMemoryReaderRepository _inner;

  static Future<PersistentReaderRepository> open(
    SharedPreferences prefs,
    StorageNotice notice,
  ) async {
    final store = PersistedList<Reader>(
      prefs: prefs,
      key: readersKey,
      seed: seedReaders,
      fromJson: Reader.fromJson,
      toJson: (reader) => reader.toJson(),
      notice: notice,
    );
    final loaded = store.load();
    final inner = InMemoryReaderRepository(
      readers: loaded.items,
      persist: store.save,
    );
    if (loaded.shouldPersist) {
      await store.save(inner.listAll(includeDeleted: true));
    }
    return PersistentReaderRepository._(inner);
  }

  @override
  Future<PageResult<Reader>> find(query) => _inner.find(query);

  @override
  Future<Reader?> findById(int id) => _inner.findById(id);

  @override
  Future<Reader> create(Reader reader) => _inner.create(reader);

  @override
  Future<Reader> update(Reader reader) => _inner.update(reader);

  @override
  Future<void> softDelete(int id) => _inner.softDelete(id);

  @override
  Future<void> hardDelete(int id) => _inner.hardDelete(id);

  @override
  Future<void> restore(int id) => _inner.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) => _inner.deleteMany(ids);

  @override
  List<Reader> listAll({bool includeDeleted = false}) =>
      _inner.listAll(includeDeleted: includeDeleted);

  @override
  bool emailTaken(String email, {int? exceptId}) =>
      _inner.emailTaken(email, exceptId: exceptId);
}

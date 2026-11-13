import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/data/seed.dart';
import 'package:library_web/forms/cascades.dart';
import 'package:library_web/models/book.dart';
import 'package:library_web/models/reader.dart';
import 'package:library_web/models/reference.dart';
import 'package:library_web/repositories/in_memory_book_repository.dart';
import 'package:library_web/repositories/in_memory_reader_repository.dart';
import 'package:library_web/storage/persisted_list.dart';
import 'package:library_web/storage/storage_keys.dart';
import 'package:library_web/storage/storage_notice.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fromJson не падает на пустом объекте', () {
    final book = Book.fromJson(const {});
    expect(book.id, 0);
    expect(book.title, '');
    expect(book.authorIds, isEmpty);
    expect(book.deletedAt, isNull);

    final reader = Reader.fromJson(const {});
    expect(reader.email, '');
    expect(reader.card, isNull);

    final publisher = Publisher.fromJson(const {'name': 'АСТ'});
    expect(publisher.city, '');
  });

  test('город и издательство сужают друг друга', () {
    const publishers = [
      Publisher(id: 1, name: 'АСТ', city: 'Москва'),
      Publisher(id: 4, name: 'Питер', city: 'Санкт-Петербург'),
    ];
    expect(
      narrowCities(
        cities: const ['Москва', 'Санкт-Петербург'],
        selectedPublisherCity: 'Москва',
      ),
      ['Москва'],
    );
    expect(
      narrowPublishers(
        publishers: publishers,
        city: 'Санкт-Петербург',
      ).single.name,
      'Питер',
    );
    expect(narrowPublishers(publishers: publishers, city: null), hasLength(2));
  });

  test('ISBN и почта уникальны, книги издательства считаются', () {
    final books = InMemoryBookRepository(latency: Duration.zero);
    expect(books.isbnTaken('978-5-17-100001-1'), isTrue);
    expect(books.isbnTaken('9785171000011'), isTrue);
    expect(books.isbnTaken('978-5-17-100001-1', exceptId: 1), isFalse);
    expect(
      books.countByPublisher(1),
      seedBooks.where((book) => book.publisherId == 1).length,
    );

    final readers = InMemoryReaderRepository(latency: Duration.zero);
    expect(readers.emailTaken('Anna.Ivanova@example.com'), isTrue);
    expect(
      readers.emailTaken('anna.ivanova@example.com', exceptId: 1),
      isFalse,
    );
  });

  test('список переживает запись и чтение', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notice = StorageNotice();
    final store = PersistedList<Book>(
      prefs: prefs,
      key: booksKey,
      seed: seedBooks,
      fromJson: Book.fromJson,
      toJson: (book) => book.toJson(),
      notice: notice,
    );
    final first = store.load();
    expect(first.shouldPersist, isTrue);
    await store.save(first.items);
    final again = PersistedList<Book>(
      prefs: prefs,
      key: booksKey,
      seed: seedBooks,
      fromJson: Book.fromJson,
      toJson: (book) => book.toJson(),
      notice: notice,
    ).load();
    expect(again.items.first.title, seedBooks.first.title);
    expect(again.shouldPersist, isFalse);
    expect(notice.message, isNull);
  });

  test('чужая версия схемы сбрасывает каталог и оставляет сообщение', () async {
    SharedPreferences.setMockInitialValues({
      schemaVersionKey: 99,
      booksKey: '[]',
      'books': '[]',
    });
    final prefs = await SharedPreferences.getInstance();
    final notice = StorageNotice();
    await prepareStorage(prefs, notice);
    expect(notice.message, contains('Формат хранилища'));
    expect(prefs.getString(booksKey), isNull);
    expect(prefs.getString('books'), isNull);
    expect(prefs.getInt(schemaVersionKey), schemaVersion);
  });

  test('битый JSON заменяется начальным набором', () async {
    SharedPreferences.setMockInitialValues({
      schemaVersionKey: schemaVersion,
      booksKey: '{',
    });
    final prefs = await SharedPreferences.getInstance();
    final notice = StorageNotice();
    final loaded = PersistedList<Book>(
      prefs: prefs,
      key: booksKey,
      seed: seedBooks,
      fromJson: Book.fromJson,
      toJson: (book) => book.toJson(),
      notice: notice,
    ).load();
    expect(loaded.shouldPersist, isTrue);
    expect(loaded.items, hasLength(seedBooks.length));
    expect(notice.message, contains('повреждены'));
  });
}

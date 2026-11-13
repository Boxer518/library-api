import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/data/seed.dart';
import 'package:library_web/models/author_query.dart';
import 'package:library_web/models/book.dart';
import 'package:library_web/models/book_query.dart';
import 'package:library_web/models/page_result.dart';
import 'package:library_web/repositories/in_memory_author_repository.dart';
import 'package:library_web/repositories/in_memory_book_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const instant = Duration.zero;

  test('начальный набор покрывает требование по числу записей', () {
    expect(seedBooks.length, greaterThanOrEqualTo(20));
    expect(seedAuthors.length, greaterThanOrEqualTo(8));
    expect(seedBooks.where((book) => book.isDeleted), isNotEmpty);
    expect(seedAuthors.where((author) => author.isDeleted), isNotEmpty);
  });

  test('PageResult считает страницы и пустое состояние', () {
    expect(
      const PageResult<int>(items: [], page: 1, size: 10, total: 0).totalPages,
      1,
    );
    expect(
      const PageResult<int>(items: [], page: 1, size: 10, total: 11).totalPages,
      2,
    );
    expect(PageResult<Book>.empty().items, isEmpty);
    expect(PageResult<Book>.empty().hasNext, isFalse);
  });

  test('BookQuery сбрасывает страницу и умеет очистить фильтр', () {
    const query = BookQuery(page: 7, genreId: 2, search: 'война');
    final changed = query.copyWith(search: 'мир');
    expect(changed.page, 1);
    expect(changed.genreId, 2);
    expect(changed.search, 'мир');
    expect(query.copyWith(page: 3).page, 3);
    expect(query.copyWith(genreId: null).genreId, isNull);
    expect(query.copyWith().genreId, 2);
  });

  test('адрес книг собирается и разбирается обратно', () {
    const query = BookQuery(
      search: 'война',
      genreId: 2,
      publisherId: 1,
      yearFrom: 1800,
      yearTo: 1900,
      sortField: 'year',
      sortAscending: false,
      page: 3,
      size: 25,
      includeDeleted: true,
    );
    final uri = Uri.parse(query.toLocation('/books'));
    final restored = BookQuery.fromParameters(uri.queryParameters);
    expect(restored, query);
    expect(uri.path, '/books');
    expect(uri.queryParameters['sort'], 'year,desc');
  });

  test('нулевой и пустой id фильтра не включаются в запрос', () {
    expect(BookQuery.fromParameters({'genreId': '0'}).genreId, isNull);
    expect(BookQuery.fromParameters({'publisherId': '-3'}).publisherId, isNull);
    expect(BookQuery.fromParameters({'genreId': 'нет'}).genreId, isNull);
    expect(BookQuery.fromParameters({'genreId': '99'}).genreId, 99);
  });

  test('поиск, три фильтра и страница работают вместе', () async {
    final repository = InMemoryBookRepository(latency: instant);

    final byTitle = await repository.find(const BookQuery(search: 'война'));
    expect(
      byTitle.items.map((book) => book.title),
      containsAll(['Война и мир', 'Война миров']),
    );

    final combined = await repository.find(
      const BookQuery(search: 'война', genreId: 2, publisherId: 1),
    );
    expect(combined.total, 1);
    expect(combined.items.single.title, 'Война миров');

    final byIsbn = await repository.find(const BookQuery(search: '100001'));
    expect(byIsbn.items.single.title, 'Война и мир');

    final years = await repository.find(
      const BookQuery(yearFrom: 1950, yearTo: 1953, size: 25),
    );
    expect(years.items, isNotEmpty);
    expect(
      years.items.every((book) => book.year >= 1950 && book.year <= 1953),
      isTrue,
    );

    final hidden = await repository.find(const BookQuery(size: 50));
    final withDeleted = await repository.find(
      const BookQuery(size: 50, includeDeleted: true),
    );
    expect(withDeleted.total, greaterThan(hidden.total));

    final page = await repository.find(
      const BookQuery(sortField: 'year', sortAscending: false, size: 10),
    );
    expect(page.items, hasLength(10));
    expect(page.total, hidden.total);
    expect(page.hasNext, isTrue);
    expect(page.items.first.year, greaterThanOrEqualTo(page.items.last.year));

    final far = await repository.find(const BookQuery(page: 9, size: 10));
    expect(far.items, isEmpty);
    expect(far.total, hidden.total);
  });

  test(
    'deleteMany пропускает уже удалённые и не стирает запись физически',
    () async {
      final repository = InMemoryBookRepository(latency: instant);
      final all = await repository.find(
        const BookQuery(includeDeleted: true, size: 50),
      );
      final deleted = all.items.firstWhere((book) => book.isDeleted);
      final alive = all.items.firstWhere((book) => !book.isDeleted);

      final count = await repository.deleteMany([deleted.id, alive.id, 99999]);
      expect(count, 1);

      final hidden = await repository.findById(alive.id);
      expect(hidden!.isDeleted, isTrue);
      final untouched = await repository.findById(deleted.id);
      expect(untouched!.deletedAt, deleted.deletedAt);

      await repository.restore(alive.id);
      expect((await repository.findById(alive.id))!.isDeleted, isFalse);

      await repository.hardDelete(alive.id);
      expect(await repository.findById(alive.id), isNull);
    },
  );

  test('create и update книги не мутируют исходный объект', () async {
    final repository = InMemoryBookRepository(latency: instant);
    const draft = Book(
      id: 0,
      title: 'Черновик',
      isbn: '978-0-00-000000-0',
      year: 2020,
      pages: 10,
      publisherId: 1,
      authorIds: [1],
      genreIds: [1],
      copiesTotal: 1,
      copiesAvailable: 1,
    );
    final created = await repository.create(draft);
    expect(created.id, isNot(0));
    final updated = await repository.update(created.copyWith(title: 'Готово'));
    expect(updated.title, 'Готово');
    expect((await repository.findById(created.id))!.title, 'Готово');
  });

  test('поиск авторов идёт по фамилии и стране', () async {
    final repository = InMemoryAuthorRepository(latency: instant);
    final family = await repository.find(const AuthorQuery(search: 'стругац'));
    expect(family.total, 2);
    expect(family.items.first.fullName, contains('Аркадий'));

    final country = await repository.find(
      const AuthorQuery(search: 'сша', sortField: 'birthYear'),
    );
    expect(country.items, isNotEmpty);
    expect(
      country.items.every((author) => author.country.toLowerCase() == 'сша'),
      isTrue,
    );

    final hidden = await repository.find(const AuthorQuery(size: 50));
    expect(
      hidden.items.any((author) => author.fullName.contains('Кристи')),
      isFalse,
    );
    final visible = await repository.find(
      const AuthorQuery(size: 50, includeDeleted: true, search: 'кристи'),
    );
    expect(visible.items.single.fullName, contains('Кристи'));

    final sorted = await repository.find(
      const AuthorQuery(
        sortField: 'country',
        sortAscending: false,
        size: 50,
        includeDeleted: true,
      ),
    );
    expect(
      sorted.items.first.country.toLowerCase().compareTo(
        sorted.items.last.country.toLowerCase(),
      ),
      greaterThanOrEqualTo(0),
    );
  });

  test('copyWith автора восстанавливает запись через clearDeletedAt', () {
    final author = seedAuthors.firstWhere((item) => item.isDeleted);
    expect(author.copyWith(country: 'Франция').isDeleted, isTrue);
    expect(author.copyWith(clearDeletedAt: true).isDeleted, isFalse);
  });
}

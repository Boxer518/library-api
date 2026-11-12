import '../models/author.dart';
import '../models/book.dart';
import '../models/reference.dart';

const genres = <Genre>[
  Genre(id: 1, name: 'Роман'),
  Genre(id: 2, name: 'Фантастика'),
  Genre(id: 3, name: 'Детектив'),
  Genre(id: 4, name: 'Поэзия'),
  Genre(id: 5, name: 'Историческая проза'),
];

const publishers = <Publisher>[
  Publisher(id: 1, name: 'АСТ'),
  Publisher(id: 2, name: 'Эксмо'),
  Publisher(id: 3, name: 'Азбука'),
  Publisher(id: 4, name: 'Питер'),
  Publisher(id: 5, name: 'МИФ'),
];

/// Начальный набор. После перезагрузки страницы репозиторий снова
/// копирует эти списки: правки в памяти не переживают обновление.
final List<Author> seedAuthors = <Author>[
  const Author(
    id: 1,
    lastName: 'Толстой',
    firstName: 'Лев',
    middleName: 'Николаевич',
    country: 'Россия',
    birthYear: 1828,
  ),
  const Author(
    id: 2,
    lastName: 'Достоевский',
    firstName: 'Фёдор',
    middleName: 'Михайлович',
    country: 'Россия',
    birthYear: 1821,
  ),
  const Author(
    id: 3,
    lastName: 'Пушкин',
    firstName: 'Александр',
    middleName: 'Сергеевич',
    country: 'Россия',
    birthYear: 1799,
  ),
  const Author(
    id: 4,
    lastName: 'Оруэлл',
    firstName: 'Джордж',
    country: 'Великобритания',
    birthYear: 1903,
  ),
  const Author(
    id: 5,
    lastName: 'Брэдбери',
    firstName: 'Рэй',
    middleName: 'Дуглас',
    country: 'США',
    birthYear: 1920,
  ),
  Author(
    id: 6,
    lastName: 'Кристи',
    firstName: 'Агата',
    country: 'Великобритания',
    birthYear: 1890,
    deletedAt: DateTime.utc(2024, 3, 12),
  ),
  const Author(
    id: 7,
    lastName: 'Стругацкий',
    firstName: 'Аркадий',
    middleName: 'Натанович',
    country: 'Россия',
    birthYear: 1925,
  ),
  const Author(
    id: 8,
    lastName: 'Стругацкий',
    firstName: 'Борис',
    middleName: 'Натанович',
    country: 'Россия',
    birthYear: 1933,
  ),
  const Author(
    id: 9,
    lastName: 'Кинг',
    firstName: 'Стивен',
    middleName: 'Эдвин',
    country: 'США',
    birthYear: 1947,
  ),
  const Author(
    id: 10,
    lastName: 'Азимов',
    firstName: 'Айзек',
    country: 'США',
    birthYear: 1920,
  ),
  const Author(
    id: 11,
    lastName: 'Булгаков',
    firstName: 'Михаил',
    middleName: 'Афанасьевич',
    country: 'Россия',
    birthYear: 1891,
  ),
  const Author(
    id: 12,
    lastName: 'Уэллс',
    firstName: 'Герберт',
    country: 'Великобритания',
    birthYear: 1866,
  ),
  const Author(
    id: 13,
    lastName: 'Ле Гуин',
    firstName: 'Урсула',
    country: 'США',
    birthYear: 1929,
  ),
];

final List<Book> seedBooks = <Book>[
  const Book(
    id: 1,
    title: 'Война и мир',
    isbn: '978-5-17-100001-1',
    year: 1869,
    pages: 1300,
    publisherId: 1,
    authorIds: [1],
    genreIds: [1],
    copiesTotal: 12,
    copiesAvailable: 4,
  ),
  const Book(
    id: 2,
    title: 'Анна Каренина',
    isbn: '978-5-04-100002-2',
    year: 1877,
    pages: 864,
    publisherId: 2,
    authorIds: [1],
    genreIds: [1],
    copiesTotal: 8,
    copiesAvailable: 8,
  ),
  const Book(
    id: 3,
    title: 'Преступление и наказание',
    isbn: '978-5-389-100003-3',
    year: 1866,
    pages: 672,
    publisherId: 3,
    authorIds: [2],
    genreIds: [1],
    copiesTotal: 10,
    copiesAvailable: 2,
  ),
  const Book(
    id: 4,
    title: 'Идиот',
    isbn: '978-5-17-100004-4',
    year: 1869,
    pages: 640,
    publisherId: 1,
    authorIds: [2],
    genreIds: [1],
    copiesTotal: 6,
    copiesAvailable: 1,
  ),
  const Book(
    id: 5,
    title: 'Братья Карамазовы',
    isbn: '978-5-04-100005-5',
    year: 1880,
    pages: 928,
    publisherId: 2,
    authorIds: [2],
    genreIds: [1],
    copiesTotal: 7,
    copiesAvailable: 5,
  ),
  const Book(
    id: 6,
    title: 'Евгений Онегин',
    isbn: '978-5-389-100006-6',
    year: 1833,
    pages: 224,
    publisherId: 3,
    authorIds: [3],
    genreIds: [4],
    copiesTotal: 9,
    copiesAvailable: 6,
  ),
  const Book(
    id: 7,
    title: 'Капитанская дочка',
    isbn: '978-5-04-100007-7',
    year: 1836,
    pages: 288,
    publisherId: 2,
    authorIds: [3],
    genreIds: [5],
    copiesTotal: 5,
    copiesAvailable: 0,
  ),
  const Book(
    id: 8,
    title: '1984',
    isbn: '978-5-17-100008-8',
    year: 1949,
    pages: 320,
    publisherId: 1,
    authorIds: [4],
    genreIds: [2],
    copiesTotal: 15,
    copiesAvailable: 3,
  ),
  Book(
    id: 9,
    title: 'Скотный двор',
    isbn: '978-5-4461-100009-9',
    year: 1945,
    pages: 176,
    publisherId: 4,
    authorIds: const [4],
    genreIds: const [2],
    copiesTotal: 4,
    copiesAvailable: 4,
    deletedAt: DateTime.utc(2024, 5, 2),
  ),
  const Book(
    id: 10,
    title: '451 градус по Фаренгейту',
    isbn: '978-5-04-100010-1',
    year: 1953,
    pages: 256,
    publisherId: 2,
    authorIds: [5],
    genreIds: [2],
    copiesTotal: 11,
    copiesAvailable: 7,
  ),
  const Book(
    id: 11,
    title: 'Марсианские хроники',
    isbn: '978-5-17-100011-2',
    year: 1950,
    pages: 304,
    publisherId: 1,
    authorIds: [5],
    genreIds: [2],
    copiesTotal: 6,
    copiesAvailable: 2,
  ),
  const Book(
    id: 12,
    title: 'Убийство в Восточном экспрессе',
    isbn: '978-5-389-100012-3',
    year: 1934,
    pages: 320,
    publisherId: 3,
    authorIds: [6],
    genreIds: [3],
    copiesTotal: 8,
    copiesAvailable: 8,
  ),
  Book(
    id: 13,
    title: 'И никого не стало',
    isbn: '978-5-04-100013-4',
    year: 1939,
    pages: 288,
    publisherId: 2,
    authorIds: const [6],
    genreIds: const [3],
    copiesTotal: 5,
    copiesAvailable: 1,
    deletedAt: DateTime.utc(2024, 8, 19),
  ),
  const Book(
    id: 14,
    title: 'Пикник на обочине',
    isbn: '978-5-17-100014-5',
    year: 1972,
    pages: 256,
    publisherId: 1,
    authorIds: [7, 8],
    genreIds: [2],
    copiesTotal: 14,
    copiesAvailable: 9,
  ),
  const Book(
    id: 15,
    title: 'Трудно быть богом',
    isbn: '978-5-699-100015-6',
    year: 1964,
    pages: 352,
    publisherId: 5,
    authorIds: [7, 8],
    genreIds: [2],
    copiesTotal: 7,
    copiesAvailable: 3,
  ),
  const Book(
    id: 16,
    title: 'Понедельник начинается в субботу',
    isbn: '978-5-17-100016-7',
    year: 1965,
    pages: 320,
    publisherId: 1,
    authorIds: [7, 8],
    genreIds: [2],
    copiesTotal: 6,
    copiesAvailable: 6,
  ),
  const Book(
    id: 17,
    title: 'Сияние',
    isbn: '978-5-4461-100017-8',
    year: 1977,
    pages: 480,
    publisherId: 4,
    authorIds: [9],
    genreIds: [1, 2],
    copiesTotal: 9,
    copiesAvailable: 4,
  ),
  const Book(
    id: 18,
    title: 'Оно',
    isbn: '978-5-17-100018-9',
    year: 1986,
    pages: 1136,
    publisherId: 1,
    authorIds: [9],
    genreIds: [2],
    copiesTotal: 4,
    copiesAvailable: 0,
  ),
  const Book(
    id: 19,
    title: 'Основание',
    isbn: '978-5-699-100019-1',
    year: 1951,
    pages: 320,
    publisherId: 5,
    authorIds: [10],
    genreIds: [2],
    copiesTotal: 10,
    copiesAvailable: 5,
  ),
  const Book(
    id: 20,
    title: 'Я, робот',
    isbn: '978-5-04-100020-2',
    year: 1950,
    pages: 272,
    publisherId: 2,
    authorIds: [10],
    genreIds: [2],
    copiesTotal: 8,
    copiesAvailable: 8,
  ),
  const Book(
    id: 21,
    title: 'Мастер и Маргарита',
    isbn: '978-5-389-100021-3',
    year: 1967,
    pages: 480,
    publisherId: 3,
    authorIds: [11],
    genreIds: [1],
    copiesTotal: 16,
    copiesAvailable: 2,
  ),
  Book(
    id: 22,
    title: 'Собачье сердце',
    isbn: '978-5-17-100022-4',
    year: 1925,
    pages: 192,
    publisherId: 1,
    authorIds: const [11],
    genreIds: const [1],
    copiesTotal: 7,
    copiesAvailable: 3,
    deletedAt: DateTime.utc(2025, 1, 9),
  ),
  const Book(
    id: 23,
    title: 'Война миров',
    isbn: '978-5-17-100023-5',
    year: 1898,
    pages: 256,
    publisherId: 1,
    authorIds: [12],
    genreIds: [2],
    copiesTotal: 9,
    copiesAvailable: 4,
  ),
  const Book(
    id: 24,
    title: 'Человек-невидимка',
    isbn: '978-5-389-100024-6',
    year: 1897,
    pages: 240,
    publisherId: 3,
    authorIds: [12],
    genreIds: [2],
    copiesTotal: 5,
    copiesAvailable: 5,
  ),
  const Book(
    id: 25,
    title: 'Волшебник Земноморья',
    isbn: '978-5-699-100025-7',
    year: 1968,
    pages: 288,
    publisherId: 5,
    authorIds: [13],
    genreIds: [2],
    copiesTotal: 6,
    copiesAvailable: 1,
  ),
];

String authorName(int id) {
  for (final author in seedAuthors) {
    if (author.id == id) {
      return '${author.lastName} ${author.firstName}';
    }
  }
  return 'Автор #$id';
}

String authorNames(List<int> ids) {
  if (ids.isEmpty) {
    return '—';
  }
  return ids.map(authorName).join(', ');
}

String genreName(int id) {
  for (final genre in genres) {
    if (genre.id == id) {
      return genre.name;
    }
  }
  return 'Жанр #$id';
}

String genreNames(List<int> ids) {
  if (ids.isEmpty) {
    return '—';
  }
  return ids.map(genreName).join(', ');
}

String publisherName(int id) {
  for (final publisher in publishers) {
    if (publisher.id == id) {
      return publisher.name;
    }
  }
  return 'Издательство #$id';
}

String formatTimestamp(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}

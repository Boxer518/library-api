import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/core/api_client.dart';
import 'package:library_web/core/api_exceptions.dart';
import 'package:library_web/models/book.dart';
import 'package:library_web/models/book_query.dart';
import 'package:library_web/repositories/api_repositories.dart';
import 'package:library_web/repositories/loan_repository.dart';

void main() {
  test('страница книг разбирается, вложенные связи тоже', () async {
    RequestOptions? seen;
    final dio = _scripted((options, handler) {
      seen = options;
      handler.answer(
        _ok(options, {
          'items': [
            {
              'id': 7,
              'title': 'Тихий Дон',
              'isbn': '978-1',
              'year': 1940,
              'pages': 800,
              'publisher': {'id': 3, 'name': 'Азбука'},
              'authors': [
                {'id': 4, 'lastName': 'Шолохов'},
              ],
              'genres': [
                {'id': 2, 'name': 'Роман'},
              ],
              'copiesTotal': 3,
              'copiesAvailable': 1,
            },
          ],
          'page': 2,
          'size': 25,
          'total': 40,
        }),
      );
    });
    final page = await ApiBookRepository(dio).find(
      const BookQuery(
        search: 'дон',
        genreId: 2,
        publisherId: 3,
        yearFrom: 1900,
        yearTo: 1950,
        sortField: 'year',
        sortAscending: false,
        page: 2,
        size: 25,
        includeDeleted: true,
      ),
    );

    expect(seen?.uri.path, endsWith('/books'));
    expect(seen?.queryParameters['search'], 'дон');
    expect(seen?.queryParameters['genreId'], 2);
    expect(seen?.queryParameters['sort'], 'year,desc');
    expect(seen?.queryParameters['page'], 2);
    expect(seen?.queryParameters['size'], 25);
    expect(seen?.queryParameters['includeDeleted'], 'true');
    expect(page.total, 40);
    expect(page.items.single.publisherId, 3);
    expect(page.items.single.authorIds, [4]);
    expect(page.items.single.genreIds, [2]);
  });

  test('создание книги уходит телом без id', () async {
    RequestOptions? seen;
    final dio = _scripted((options, handler) {
      seen = options;
      handler.answer(
        _ok(options, {
          'id': 15,
          'title': 'Новая',
          'isbn': '978-5-17-100099-1',
          'year': 2020,
          'pages': 120,
          'publisherId': 1,
          'authorIds': [2],
          'genreIds': [3],
          'copiesTotal': 4,
          'copiesAvailable': 4,
        }),
      );
    });
    final created = await ApiBookRepository(dio).create(_book());

    expect(seen?.method, 'POST');
    expect(seen?.uri.path, endsWith('/books'));
    final body = Map<String, dynamic>.from(seen?.data as Map);
    expect(body.containsKey('id'), isFalse);
    expect(body.containsKey('copiesAvailable'), isFalse);
    expect(body['title'], 'Новая');
    expect(body['copiesTotal'], 4);
    expect(created.id, 15);
  });

  test('422 становится ошибкой полей', () async {
    final dio = _scripted((options, handler) {
      handler.answer(
        Response(
          requestOptions: options,
          statusCode: 422,
          data: {
            'message': 'Ошибка валидации',
            'errors': {'isbn': 'Такой ISBN уже есть'},
          },
        ),
      );
    });

    await expectLater(
      ApiBookRepository(dio).create(_book()),
      throwsA(
        isA<ValidationException>().having(
          (error) => error.errors['isbn'],
          'isbn',
          'Такой ISBN уже есть',
        ),
      ),
    );
  });

  test('409 выдачи становится ConflictException', () async {
    final dio = _scripted((options, handler) {
      handler.answer(
        Response(
          requestOptions: options,
          statusCode: 409,
          data: {'message': 'Нет свободных экземпляров'},
        ),
      );
    });

    await expectLater(
      ApiLoanRepository(dio).issue(bookId: 1, readerId: 2),
      throwsA(
        isA<ConflictException>().having(
          (error) => error.message,
          'message',
          'Нет свободных экземпляров',
        ),
      ),
    );
  });

  test('недоступный сервер на чтении повторяется три раза', () async {
    var attempts = 0;
    final dio = _scripted((options, handler) {
      attempts += 1;
      handler.fail(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
    });

    await expectLater(
      ApiBookRepository(dio).find(const BookQuery()),
      throwsA(
        isA<NetworkException>().having(
          (error) => error.message,
          'message',
          contains('CORS'),
        ),
      ),
    );
    expect(attempts, 3);
  });

  test('создание при обрыве сети не повторяется', () async {
    var attempts = 0;
    final dio = _scripted((options, handler) {
      attempts += 1;
      handler.fail(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
    });

    await expectLater(
      ApiBookRepository(dio).create(_book()),
      throwsA(isA<NetworkException>()),
    );
    expect(attempts, 1);
  });

  test('новый поиск отменяет предыдущий запрос', () async {
    final started = Completer<void>();
    final gate = Completer<void>();
    CancelToken? firstToken;
    final dio = _scripted((options, handler) async {
      if (options.queryParameters['search'] == 'старый') {
        firstToken = options.cancelToken;
        if (!started.isCompleted) {
          started.complete();
        }
        await gate.future;
        if (!handler.isCompleted) {
          handler.fail(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
            ),
          );
        }
        return;
      }
      handler.answer(
        _ok(options, {'items': [], 'page': 1, 'size': 10, 'total': 0}),
      );
    });
    final repository = ApiBookRepository(dio);
    final first = repository.find(const BookQuery(search: 'старый'));
    await started.future;
    final second = repository.find(const BookQuery(search: 'новый'));
    expect(firstToken?.isCancelled, isTrue);
    gate.complete();

    await expectLater(
      first,
      throwsA(
        isA<NetworkException>().having(
          (error) => error.message,
          'message',
          'Запрос отменён.',
        ),
      ),
    );
    expect((await second).total, 0);
  });
}

Dio _scripted(
  void Function(RequestOptions options, RequestInterceptorHandler handler)
  respond,
) {
  final dio = buildDio();
  dio.interceptors.add(InterceptorsWrapper(onRequest: respond));
  return dio;
}

extension on RequestInterceptorHandler {
  void answer(Response<dynamic> response) => resolve(response, true);

  void fail(DioException error) => reject(error, true);
}

Response<dynamic> _ok(RequestOptions options, Object? data) {
  return Response(requestOptions: options, statusCode: 200, data: data);
}

Book _book() {
  return const Book(
    id: 0,
    title: 'Новая',
    isbn: '978-5-17-100099-1',
    year: 2020,
    pages: 120,
    publisherId: 1,
    authorIds: [2],
    genreIds: [3],
    copiesTotal: 4,
    copiesAvailable: 4,
  );
}

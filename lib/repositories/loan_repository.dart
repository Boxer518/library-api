import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';

/// Выдача книги. Учебный сервер принимает `POST /loans`.
abstract interface class LoanRepository {
  Future<void> issue({
    required int bookId,
    required int readerId,
    int days = 14,
  });
}

class ApiLoanRepository implements LoanRepository {
  ApiLoanRepository(this._dio);

  final Dio _dio;

  @override
  Future<void> issue({
    required int bookId,
    required int readerId,
    int days = 14,
  }) {
    return guard(() async {
      await _dio.post<dynamic>(
        '/loans',
        data: {'readerId': readerId, 'bookId': bookId, 'days': days},
      );
    });
  }
}

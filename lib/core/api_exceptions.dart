import 'package:dio/dio.dart';

/// Ошибки предметной области. Виджеты знают только их, не Dio.
sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Нет соединения, таймаут, сервер недоступен или запрос отменён.
class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Сервер недоступен. Проверьте соединение.',
  ]);
}

/// 401 — не аутентифицирован либо срок действия токена истёк.
class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Требуется вход в систему.']);
}

/// 403 — роль не позволяет выполнить операцию.
class ForbiddenException extends ApiException {
  const ForbiddenException([
    super.message = 'Недостаточно прав для этого действия.',
  ]);
}

/// 404.
class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Запись не найдена.']);
}

/// 409 — нарушено ограничение целостности.
class ConflictException extends ApiException {
  const ConflictException(super.message);
}

/// 422 — ошибки валидации по полям. Ключи совпадают с именами полей модели.
class ValidationException extends ApiException {
  const ValidationException(super.message, this.errors);

  final Map<String, String> errors;
}

/// 5xx и прочие необработанные коды.
class ServerException extends ApiException {
  const ServerException([
    super.message = 'Ошибка на сервере. Попробуйте позже.',
  ]);
}

ApiException mapHttpError(int status, dynamic body) {
  final message = (body is Map && body['message'] is String)
      ? body['message'] as String
      : null;
  return switch (status) {
    401 => UnauthorizedException(message ?? 'Требуется вход в систему.'),
    403 => ForbiddenException(
      message ?? 'Недостаточно прав для этого действия.',
    ),
    404 => NotFoundException(message ?? 'Запись не найдена.'),
    409 => ConflictException(message ?? 'Операция невозможна.'),
    422 => ValidationException(
      message ?? 'Ошибка валидации',
      (body is Map && body['errors'] is Map)
          ? (body['errors'] as Map).map(
              (key, value) => MapEntry('$key', '$value'),
            )
          : const {},
    ),
    _ => ServerException(message ?? 'Неизвестная ошибка (код $status).'),
  };
}

ApiException mapDioError(DioException error) {
  // Если исключение уже разобрал интерсептор, повторно его не разбираем.
  // Без этой проверки ошибка 422 придёт как ServerException.
  final existing = error.error;
  if (existing is ApiException) {
    return existing;
  }
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => const NetworkException(
      'Сервер не ответил вовремя.',
    ),
    DioExceptionType.connectionError => const NetworkException(
      'Не удалось соединиться с сервером. '
      'Если сервер запущен, откройте консоль браузера и проверьте наличие ошибки CORS.',
    ),
    DioExceptionType.cancel => const NetworkException('Запрос отменён.'),
    DioExceptionType.badResponse => mapHttpError(
      error.response?.statusCode ?? 0,
      error.response?.data,
    ),
    _ => const ServerException(),
  };
}

/// Не выпускает DioException наружу.
Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (error) {
    throw mapDioError(error);
  }
}

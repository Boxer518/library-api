import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_debug.dart';
import 'api_exceptions.dart';
import 'api_session.dart';
import 'config.dart';

Dio buildDio({
  String? Function()? tokenProvider,
  ApiDebugParams? debug,
  ApiSession? session,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      // Коды 4xx не бросают исключение сами: их разбирает интерсептор.
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider?.call();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        final fail = debug?.fail;
        final delay = debug?.delayMs;
        if (fail != null) {
          options.queryParameters['__fail'] = fail;
        }
        if (delay != null) {
          options.queryParameters['__delay'] = delay;
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final status = response.statusCode ?? 0;
        if (kDebugMode) {
          debugPrint(
            '[API] ${response.requestOptions.method} '
            '${response.requestOptions.uri} -> $status',
          );
        }
        if (status >= 400) {
          // throw из интерсептора Dio завернёт в DioException с типом unknown.
          // Поэтому ответ уходит по ветке ошибок уже с готовым исключением.
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          debugPrint(
            '[API] сбой ${error.requestOptions.method} '
            '${error.requestOptions.uri}: ${error.type}',
          );
        }
        return handler.next(error);
      },
    ),
  );
  dio.interceptors.add(_ReadRetryInterceptor(dio));
  if (session != null) {
    dio.interceptors.add(_RefreshInterceptor(dio, session));
  }
  return dio;
}

/// Повтор только чтений: создание записи повторять нельзя.
/// Не больше трёх попыток, пауза растёт.
class _ReadRetryInterceptor extends Interceptor {
  _ReadRetryInterceptor(this._dio);

  final Dio _dio;

  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.requestOptions.extra['skipRetry'] == true) {
      return handler.next(error);
    }
    final method = error.requestOptions.method.toUpperCase();
    if (method != 'GET' || !_isNetwork(error)) {
      return handler.next(error);
    }
    var current = error;
    var attempt = 1;
    while (attempt < 3 &&
        _isNetwork(current) &&
        current.requestOptions.cancelToken?.isCancelled != true) {
      await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
      if (current.requestOptions.cancelToken?.isCancelled == true) {
        break;
      }
      attempt += 1;
      try {
        final options = current.requestOptions;
        options.extra['attempt'] = attempt;
        options.extra['skipRetry'] = true;
        final response = await _dio.fetch<dynamic>(options);
        return handler.resolve(response);
      } on DioException catch (next) {
        current = next;
      }
    }
    return handler.next(current);
  }

  bool _isNetwork(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    };
  }
}

/// Один раз обновляет access-токен на 401 и повторяет исходный запрос.
class _RefreshInterceptor extends Interceptor {
  _RefreshInterceptor(this._dio, this._session);

  final Dio _dio;
  final ApiSession _session;

  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final status = error.response?.statusCode;
    final path = error.requestOptions.path;
    final already = error.requestOptions.extra['authRetried'] == true;
    final refresh = _session.refreshToken;
    if (status != 401 ||
        already ||
        path.contains('/auth/') ||
        refresh == null ||
        refresh.isEmpty) {
      return handler.next(error);
    }
    try {
      final response = await _dio.post<dynamic>(
        '/auth/refresh',
        data: {'refreshToken': refresh},
        options: Options(extra: {'authRetried': true, 'skipRetry': true}),
      );
      final data = response.data;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        _session.accessToken = map['accessToken'] as String?;
        _session.refreshToken = map['refreshToken'] as String?;
      }
      final options = error.requestOptions;
      options.extra['authRetried'] = true;
      options.extra['skipRetry'] = true;
      options.headers['Authorization'] = 'Bearer ${_session.accessToken}';
      final retried = await _dio.fetch<dynamic>(options);
      return handler.resolve(retried);
    } on DioException {
      return handler.next(error);
    }
  }
}

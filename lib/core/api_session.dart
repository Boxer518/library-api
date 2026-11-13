import 'package:dio/dio.dart';

import 'config.dart';

/// Пара токенов учебного сервера. Заголовок Authorization читает accessToken.
class ApiSession {
  String? accessToken;
  String? refreshToken;

  Future<void> login(Dio dio) async {
    try {
      final response = await dio.post<dynamic>(
        '/auth/login',
        data: {'username': apiUsername, 'password': apiPassword},
      );
      _take(response.data);
    } on DioException {
      accessToken = null;
      refreshToken = null;
    }
  }

  void _take(Object? data) {
    if (data is! Map) {
      return;
    }
    final map = Map<String, dynamic>.from(data);
    accessToken = map['accessToken'] as String?;
    refreshToken = map['refreshToken'] as String?;
  }
}

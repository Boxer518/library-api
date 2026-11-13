import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Параметры учебной диагностики из адреса страницы.
/// Сервер понимает `__fail=500` и `__delay=1500`.
class ApiDebugParams {
  int? fail;
  int? delayMs;

  void apply(Map<String, String> params) {
    fail = int.tryParse(params['__fail'] ?? '');
    delayMs = int.tryParse(params['__delay'] ?? '');
  }
}

/// Кладёт `__fail` и `__delay` текущего адреса в клиент и возвращает метку,
/// по которой список понимает, что диагностику надо запросить заново.
String? readNetworkProbe(BuildContext context) {
  try {
    final params = GoRouterState.of(context).uri.queryParameters;
    context.read<ApiDebugParams>().apply(params);
    return '${params['__fail'] ?? ''}|${params['__delay'] ?? ''}';
  } on Object {
    return null;
  }
}

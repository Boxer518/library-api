import 'package:dio/dio.dart';

import '../models/json_values.dart';
import '../models/page_result.dart';
import 'api_exceptions.dart';

Map<String, dynamic> pageQuery({
  String search = '',
  String? sortField,
  bool sortAscending = true,
  int page = 1,
  int size = 10,
  bool includeDeleted = false,
  Map<String, dynamic>? extra,
}) {
  return {
    if (search.trim().isNotEmpty) 'search': search.trim(),
    if (sortField != null)
      'sort': '$sortField,${sortAscending ? 'asc' : 'desc'}',
    'page': page,
    'size': size,
    if (includeDeleted) 'includeDeleted': 'true',
    ...?extra,
  };
}

PageResult<T> parsePage<T>(
  Object? data,
  T Function(Map<String, dynamic> json) fromJson, {
  required int fallbackSize,
}) {
  if (data is List) {
    final items = <T>[];
    for (final item in data) {
      if (item is Map) {
        items.add(fromJson(Map<String, dynamic>.from(item)));
      }
    }
    final size = items.isEmpty ? fallbackSize : items.length;
    return PageResult(items: items, page: 1, size: size, total: items.length);
  }
  if (data is! Map) {
    throw const FormatException('Ожидался объект страницы');
  }
  final map = Map<String, dynamic>.from(data);
  final rawItems = map['items'];
  final items = <T>[];
  if (rawItems is List) {
    for (final item in rawItems) {
      if (item is Map) {
        items.add(fromJson(Map<String, dynamic>.from(item)));
      }
    }
  }
  final size = map['size'] == null
      ? fallbackSize
      : jsonInt(map['size'], fallbackSize);
  return PageResult(
    items: items,
    page: jsonInt(map['page'], 1),
    size: size == 0 ? fallbackSize : size,
    total: jsonInt(map['total']),
  );
}

Map<String, dynamic> asJsonMap(Object? data) {
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  throw const FormatException('Ожидался объект записи');
}

/// Справочник читается один раз, страницами, и дальше живёт в кэше.
Future<List<T>> fetchAll<T>(
  Dio dio,
  String path,
  T Function(Map<String, dynamic> json) fromJson, {
  String? sortField,
}) {
  return guard(() => _fetchAll(dio, path, fromJson, sortField: sortField));
}

Future<List<T>> _fetchAll<T>(
  Dio dio,
  String path,
  T Function(Map<String, dynamic> json) fromJson, {
  String? sortField,
}) async {
  final items = <T>[];
  var page = 1;
  while (page <= 20) {
    final response = await dio.get<dynamic>(
      path,
      queryParameters: pageQuery(
        sortField: sortField,
        page: page,
        size: 100,
        includeDeleted: true,
      ),
    );
    final parsed = parsePage(response.data, fromJson, fallbackSize: 100);
    if (parsed.items.isEmpty) {
      break;
    }
    items.addAll(parsed.items);
    final reachedEnd = parsed.total > 0
        ? items.length >= parsed.total
        : parsed.items.length < 100;
    if (reachedEnd) {
      break;
    }
    page += 1;
  }
  return items;
}

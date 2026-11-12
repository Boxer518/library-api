import '../models/page_result.dart';

/// Границу страницы считаем явно: `num.clamp` возвращает `num`, а не `int`,
/// и в `sublist` его передать нельзя.
PageResult<T> slicePage<T>(
  List<T> rows, {
  required int page,
  required int size,
}) {
  final total = rows.length;
  final safeSize = size < 1 ? 10 : size;
  final safePage = page < 1 ? 1 : page;
  final from = (safePage - 1) * safeSize;
  final to = from + safeSize > total ? total : from + safeSize;
  final items = from >= total ? <T>[] : rows.sublist(from, to);
  return PageResult(items: items, page: safePage, size: safeSize, total: total);
}

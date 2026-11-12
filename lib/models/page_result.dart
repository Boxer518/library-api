/// Одна страница списка. Оболочка совпадает с ответом учебного API.
class PageResult<T> {
  const PageResult({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
  });

  final List<T> items;
  final int page;
  final int size;
  final int total;

  int get totalPages => total == 0 || size <= 0 ? 1 : (total / size).ceil();

  bool get hasPrevious => page > 1;

  bool get hasNext => page < totalPages;

  /// Пустая страница — начальное значение состояния экрана.
  ///
  /// Конструктор намеренно не const: пустой константный список
  /// с параметром типа `T` в Dart запрещён.
  PageResult.empty() : items = <T>[], page = 1, size = 10, total = 0;
}

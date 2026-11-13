import 'package:provider/provider.dart';
import 'package:material_ui/material_ui.dart';

import '../repositories/book_repository.dart';

/// Отказ, если на издательство ссылается хотя бы одна книга.
/// В тексте есть число связанных записей, включая логически удалённые.
Future<String?> publisherDeleteBlock(
  BuildContext context,
  List<int> ids,
) async {
  final books = context.read<BookRepository>();
  var total = 0;
  for (final id in ids) {
    total += books.countByPublisher(id);
  }
  if (total == 0) {
    return null;
  }
  return 'Удаление отклонено: с издательством связано книг: $total.';
}

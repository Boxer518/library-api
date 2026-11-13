import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../data/seed.dart';
import '../models/book.dart';
import '../repositories/book_repository.dart';
import '../repositories/in_memory_reader_repository.dart';
import '../repositories/loan_repository.dart';
import '../state/book_details_notifier.dart';
import '../state/book_list_notifier.dart';
import '../state/load_status.dart';
import '../widgets/catalog_names.dart';
import '../widgets/confirm.dart';
import '../widgets/library_scaffold.dart';
import '../widgets/reload_when_shown.dart';

class BookDetailsScreen extends StatelessWidget {
  const BookDetailsScreen({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey(id),
      create: (context) =>
          BookDetailsNotifier(context.read<BookRepository>(), id)..load(),
      child: const _BookDetailsBody(),
    );
  }
}

class _BookDetailsBody extends StatelessWidget {
  const _BookDetailsBody();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BookDetailsNotifier>();
    final book = notifier.book;
    return ReloadWhenShown(
      onShow: () => context.read<BookDetailsNotifier>().load(),
      child: LibraryScaffold(
        title: book?.title ?? 'Карточка книги',
        body: switch (notifier.status) {
          LoadStatus.idle || LoadStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          LoadStatus.error => _Message(
            icon: Icons.error_outline,
            title: notifier.error ?? 'Ошибка',
            onBack: () => _back(context),
          ),
          LoadStatus.success when book == null => _Message(
            icon: Icons.error_outline,
            title: 'Книга не найдена',
            onBack: () => _back(context),
          ),
          LoadStatus.success => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _back(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('К списку'),
                ),
              ),
              Text(
                book!.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (book.isDeleted) ...[
                const SizedBox(height: 8),
                Text('Удалена ${formatTimestamp(book.deletedAt!)}'),
              ],
              const SizedBox(height: 16),
              _line('ISBN', book.isbn),
              _line('Год', '${book.year}'),
              _line('Страниц', '${book.pages}'),
              _line('Издательство', publisherLabel(context, book.publisherId)),
              _line('Жанры', joinedGenres(context, book.genreIds)),
              _line(
                'Экземпляры',
                '${book.copiesAvailable} свободно из ${book.copiesTotal}',
              ),
              const SizedBox(height: 8),
              const Text('Авторы'),
              Wrap(
                children: [
                  for (final authorId in book.authorIds)
                    TextButton(
                      onPressed: () => context.push('/authors/$authorId'),
                      child: Text(authorLabel(context, authorId)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.push('/books/${book.id}/edit'),
                    icon: const Icon(Icons.edit),
                    label: const Text('Изменить'),
                  ),
                  if (!book.isDeleted)
                    FilledButton.tonalIcon(
                      onPressed: () => _issue(context, book),
                      icon: const Icon(Icons.assignment_ind_outlined),
                      label: const Text('Выдать'),
                    ),
                  if (!book.isDeleted)
                    OutlinedButton.icon(
                      onPressed: () => _softDelete(context),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Скрыть'),
                    ),
                  if (book.isDeleted)
                    FilledButton.icon(
                      onPressed: () => _restore(context),
                      icon: const Icon(Icons.restore),
                      label: const Text('Восстановить'),
                    ),
                  FilledButton.tonalIcon(
                    onPressed: () => _hardDelete(context),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Удалить навсегда'),
                  ),
                ],
              ),
            ],
          ),
        },
      ),
    );
  }

  Future<void> _issue(BuildContext context, Book book) async {
    final readers = context
        .read<ReaderRepository>()
        .listAll()
        .where((reader) => !reader.isDeleted)
        .toList();
    if (!context.mounted) {
      return;
    }
    final readerId = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Выдать книгу'),
          content: SizedBox(
            width: 420,
            height: readers.isEmpty ? null : 320,
            child: readers.isEmpty
                ? const Text('Нет читателей.')
                : ListView(
                    children: [
                      for (final reader in readers)
                        ListTile(
                          title: Text(reader.fullName),
                          subtitle: Text(reader.email),
                          onTap: () => Navigator.of(context).pop(reader.id),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
          ],
        );
      },
    );
    if (readerId == null || !context.mounted) {
      return;
    }
    try {
      await context.read<LoanRepository>().issue(
        bookId: book.id,
        readerId: readerId,
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Книга выдана')));
      await context.read<BookDetailsNotifier>().load();
    } on ApiException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/books');
  }

  Future<void> _softDelete(BuildContext context) async {
    final book = context.read<BookDetailsNotifier>().book;
    if (book == null) {
      return;
    }
    await runConfirmed(
      context,
      title: 'Логическое удаление',
      message: 'Скрыть «${book.title}» из каталога?',
      confirmLabel: 'Скрыть',
      action: () async {
        await context.read<BookDetailsNotifier>().softDelete();
        if (context.mounted) {
          await context.read<BookListNotifier>().load();
        }
        return 'Книга скрыта';
      },
    );
  }

  Future<void> _restore(BuildContext context) async {
    await runConfirmed(
      context,
      title: 'Восстановление',
      message: 'Вернуть книгу в каталог?',
      confirmLabel: 'Восстановить',
      action: () async {
        await context.read<BookDetailsNotifier>().restore();
        if (context.mounted) {
          await context.read<BookListNotifier>().load();
        }
        return 'Книга восстановлена';
      },
    );
  }

  Future<void> _hardDelete(BuildContext context) async {
    final book = context.read<BookDetailsNotifier>().book;
    await runConfirmed(
      context,
      title: 'Физическое удаление',
      message:
          'Стереть «${book?.title ?? 'книгу'}» без возможности восстановления?',
      confirmLabel: 'Удалить навсегда',
      action: () async {
        await context.read<BookDetailsNotifier>().hardDelete();
        if (context.mounted) {
          await context.read<BookListNotifier>().load();
          if (context.mounted) {
            context.go('/books');
          }
        }
        return 'Книга удалена навсегда';
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.onBack,
  });

  final IconData icon;
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          FilledButton(onPressed: onBack, child: const Text('К списку')),
        ],
      ),
    );
  }
}

Widget _line(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 160, child: Text(label)),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

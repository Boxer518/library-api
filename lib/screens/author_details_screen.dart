import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../repositories/author_repository.dart';
import '../repositories/book_repository.dart';
import '../state/author_details_notifier.dart';
import '../state/author_list_notifier.dart';
import '../state/load_status.dart';
import '../widgets/confirm.dart';
import '../widgets/library_scaffold.dart';

class AuthorDetailsScreen extends StatelessWidget {
  const AuthorDetailsScreen({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey(id),
      create: (context) => AuthorDetailsNotifier(
        context.read<AuthorRepository>(),
        context.read<BookRepository>(),
        id,
      )..load(),
      child: const _AuthorDetailsBody(),
    );
  }
}

class _AuthorDetailsBody extends StatelessWidget {
  const _AuthorDetailsBody();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AuthorDetailsNotifier>();
    final author = notifier.author;
    return LibraryScaffold(
      title: author?.fullName ?? 'Карточка автора',
      body: switch (notifier.status) {
        LoadStatus.idle ||
        LoadStatus.loading => const Center(child: CircularProgressIndicator()),
        LoadStatus.error => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(notifier.error ?? 'Ошибка'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _back(context),
                child: const Text('К списку'),
              ),
            ],
          ),
        ),
        LoadStatus.success when author == null => const SizedBox.shrink(),
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
              author!.fullName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (author.isDeleted) ...[
              const SizedBox(height: 8),
              const Text('Запись удалена логически'),
            ],
            const SizedBox(height: 16),
            Text('Страна: ${author.country}'),
            Text('Год рождения: ${author.birthYear}'),
            const SizedBox(height: 16),
            Text('Книги', style: Theme.of(context).textTheme.titleMedium),
            if (notifier.written.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('В каталоге нет книг этого автора.'),
              )
            else
              for (final book in notifier.written)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    book.isDeleted ? '${book.title} (удалена)' : book.title,
                  ),
                  subtitle: Text('${book.year}'),
                  onTap: () => context.push('/books/${book.id}'),
                ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (!author.isDeleted)
                  OutlinedButton.icon(
                    onPressed: () => _softDelete(context),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Скрыть'),
                  ),
                if (author.isDeleted)
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
    );
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/authors');
  }

  Future<void> _softDelete(BuildContext context) async {
    final author = context.read<AuthorDetailsNotifier>().author;
    await runConfirmed(
      context,
      title: 'Логическое удаление',
      message: 'Скрыть ${author?.fullName ?? 'автора'} из списка?',
      confirmLabel: 'Скрыть',
      action: () async {
        await context.read<AuthorDetailsNotifier>().softDelete();
        if (context.mounted) {
          await context.read<AuthorListNotifier>().load();
        }
        return 'Автор скрыт';
      },
    );
  }

  Future<void> _restore(BuildContext context) async {
    await runConfirmed(
      context,
      title: 'Восстановление',
      message: 'Вернуть автора в список?',
      confirmLabel: 'Восстановить',
      action: () async {
        await context.read<AuthorDetailsNotifier>().restore();
        if (context.mounted) {
          await context.read<AuthorListNotifier>().load();
        }
        return 'Автор восстановлен';
      },
    );
  }

  Future<void> _hardDelete(BuildContext context) async {
    final author = context.read<AuthorDetailsNotifier>().author;
    await runConfirmed(
      context,
      title: 'Физическое удаление',
      message:
          'Стереть ${author?.fullName ?? 'автора'} без возможности восстановления?',
      confirmLabel: 'Удалить навсегда',
      action: () async {
        await context.read<AuthorDetailsNotifier>().hardDelete();
        if (context.mounted) {
          await context.read<AuthorListNotifier>().load();
          if (context.mounted) {
            context.go('/authors');
          }
        }
        return 'Автор удалён навсегда';
      },
    );
  }
}

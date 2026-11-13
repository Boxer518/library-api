import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../widgets/library_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LibraryScaffold(
      title: 'Библиотека',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Каталог',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              const Text(
                'Каталог приходит с сервера: книги, авторы, жанры, '
                'издательства и читатели. Поиск, фильтры, сортировка и '
                'страницы считаются на сервере, в браузере остаётся только '
                'текущая страница. Условия списка записаны в адресе.',
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/books'),
                icon: const Icon(Icons.menu_book),
                label: const Text('Книги'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => context.go('/authors'),
                icon: const Icon(Icons.people),
                label: const Text('Авторы'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => context.go('/genres'),
                icon: const Icon(Icons.category),
                label: const Text('Жанры'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => context.go('/publishers'),
                icon: const Icon(Icons.apartment),
                label: const Text('Издательства'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => context.go('/readers'),
                icon: const Icon(Icons.badge),
                label: const Text('Читатели'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

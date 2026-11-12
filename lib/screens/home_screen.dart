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
                'Книги и авторы лежат в памяти. Поиск, фильтры, сортировка '
                'и номер страницы записаны в адресе: ссылку можно открыть '
                'в новой вкладке, а кнопка «Назад» вернёт предыдущий отбор.',
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
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/in_memory_author_repository.dart';
import 'repositories/in_memory_book_repository.dart';
import 'router.dart';
import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';

void main() {
  usePathUrlStrategy();
  runApp(const LibraryApp());
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<BookRepository>(create: (_) => InMemoryBookRepository()),
        ChangeNotifierProvider(
          create: (context) => BookListNotifier(context.read<BookRepository>()),
        ),
        Provider<AuthorRepository>(create: (_) => InMemoryAuthorRepository()),
        ChangeNotifierProvider(
          create: (context) =>
              AuthorListNotifier(context.read<AuthorRepository>()),
        ),
      ],
      child: MaterialApp.router(
        title: 'Библиотека',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6E4F)),
        ),
        routerConfig: appRouter,
      ),
    );
  }
}

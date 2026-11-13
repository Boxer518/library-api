import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/in_memory_author_repository.dart';
import 'repositories/in_memory_book_repository.dart';
import 'repositories/in_memory_genre_repository.dart';
import 'repositories/in_memory_publisher_repository.dart';
import 'repositories/in_memory_reader_repository.dart';
import 'repositories/persistent_book_repository.dart';
import 'router.dart';
import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';
import 'state/catalog_notifiers.dart';
import 'storage/persisted_list.dart';
import 'storage/storage_notice.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  final prefs = await SharedPreferences.getInstance();
  final notice = StorageNotice();
  await prepareStorage(prefs, notice);
  runApp(
    LibraryApp(
      notice: notice,
      bookRepository: await PersistentBookRepository.open(prefs, notice),
      authorRepository: await PersistentAuthorRepository.open(prefs, notice),
      genreRepository: await PersistentGenreRepository.open(prefs, notice),
      publisherRepository: await PersistentPublisherRepository.open(
        prefs,
        notice,
      ),
      readerRepository: await PersistentReaderRepository.open(prefs, notice),
    ),
  );
}

class LibraryApp extends StatefulWidget {
  const LibraryApp({
    super.key,
    this.notice,
    this.bookRepository,
    this.authorRepository,
    this.genreRepository,
    this.publisherRepository,
    this.readerRepository,
  });

  final StorageNotice? notice;
  final BookRepository? bookRepository;
  final AuthorRepository? authorRepository;
  final GenreRepository? genreRepository;
  final PublisherRepository? publisherRepository;
  final ReaderRepository? readerRepository;

  @override
  State<LibraryApp> createState() => _LibraryAppState();
}

class _LibraryAppState extends State<LibraryApp> {
  late final StorageNotice _notice = widget.notice ?? StorageNotice();
  late final BookRepository _books =
      widget.bookRepository ?? InMemoryBookRepository();
  late final AuthorRepository _authors =
      widget.authorRepository ?? InMemoryAuthorRepository();
  late final GenreRepository _genres =
      widget.genreRepository ?? InMemoryGenreRepository();
  late final PublisherRepository _publishers =
      widget.publisherRepository ?? InMemoryPublisherRepository();
  late final ReaderRepository _readers =
      widget.readerRepository ?? InMemoryReaderRepository();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<StorageNotice>.value(value: _notice),
        Provider<BookRepository>.value(value: _books),
        ChangeNotifierProvider(create: (_) => BookListNotifier(_books)),
        Provider<AuthorRepository>.value(value: _authors),
        ChangeNotifierProvider(create: (_) => AuthorListNotifier(_authors)),
        Provider<GenreRepository>.value(value: _genres),
        ChangeNotifierProvider(create: (_) => GenreListNotifier(_genres)),
        Provider<PublisherRepository>.value(value: _publishers),
        ChangeNotifierProvider(
          create: (_) => PublisherListNotifier(_publishers),
        ),
        Provider<ReaderRepository>.value(value: _readers),
        ChangeNotifierProvider(create: (_) => ReaderListNotifier(_readers)),
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

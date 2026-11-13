import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/api_debug.dart';
import 'core/api_session.dart';
import 'repositories/api_repositories.dart';
import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/in_memory_author_repository.dart';
import 'repositories/in_memory_book_repository.dart';
import 'repositories/in_memory_genre_repository.dart';
import 'repositories/in_memory_publisher_repository.dart';
import 'repositories/in_memory_reader_repository.dart';
import 'repositories/loan_repository.dart';
import 'router.dart';
import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';
import 'state/catalog_notifiers.dart';
import 'storage/storage_notice.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  final debug = ApiDebugParams();
  final session = ApiSession();
  final dio = buildDio(
    tokenProvider: () => session.accessToken,
    debug: debug,
    session: session,
  );
  await session.login(dio);
  final cache = ReferenceCache();
  await cache.warmUp(dio);
  runApp(
    LibraryApp(
      bookRepository: ApiBookRepository(dio),
      authorRepository: ApiAuthorRepository(dio, cache),
      genreRepository: ApiGenreRepository(dio, cache),
      publisherRepository: ApiPublisherRepository(dio, cache),
      readerRepository: ApiReaderRepository(dio, cache),
      loanRepository: ApiLoanRepository(dio),
      debugParams: debug,
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
    this.loanRepository,
    this.debugParams,
  });

  final StorageNotice? notice;
  final BookRepository? bookRepository;
  final AuthorRepository? authorRepository;
  final GenreRepository? genreRepository;
  final PublisherRepository? publisherRepository;
  final ReaderRepository? readerRepository;
  final LoanRepository? loanRepository;
  final ApiDebugParams? debugParams;

  @override
  State<LibraryApp> createState() => _LibraryAppState();
}

class _LibraryAppState extends State<LibraryApp> {
  late final StorageNotice _notice = widget.notice ?? StorageNotice();
  late final ApiDebugParams _debug = widget.debugParams ?? ApiDebugParams();
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
  late final LoanRepository _loans =
      widget.loanRepository ?? _NoLoanRepository();

  @override
  void initState() {
    super.initState();
    appRouter.routerDelegate.addListener(_syncDebug);
    _syncDebug();
  }

  @override
  void dispose() {
    appRouter.routerDelegate.removeListener(_syncDebug);
    super.dispose();
  }

  void _syncDebug() {
    _debug.apply(appRouter.routeInformationProvider.value.uri.queryParameters);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiDebugParams>.value(value: _debug),
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
        Provider<LoanRepository>.value(value: _loans),
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

class _NoLoanRepository implements LoanRepository {
  @override
  Future<void> issue({
    required int bookId,
    required int readerId,
    int days = 14,
  }) async {}
}

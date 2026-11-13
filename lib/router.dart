import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'models/author_query.dart';
import 'models/book_query.dart';
import 'models/catalog_query.dart';
import 'screens/author_details_screen.dart';
import 'screens/author_form_screen.dart';
import 'screens/author_list_screen.dart';
import 'screens/book_details_screen.dart';
import 'screens/book_form_screen.dart';
import 'screens/book_list_screen.dart';
import 'screens/genre_screens.dart';
import 'screens/home_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/publisher_screens.dart';
import 'screens/reader_screens.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/books',
      builder: (context, state) => BookListScreen(
        query: BookQuery.fromParameters(state.uri.queryParameters),
        simulateFailure: state.uri.queryParameters['fail'] == '1',
      ),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const BookFormScreen(),
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) =>
              _byId(state, (id) => BookDetailsScreen(id: id)),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) =>
                  _byId(state, (id) => BookFormScreen(id: id)),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/authors',
      builder: (context, state) => AuthorListScreen(
        query: AuthorQuery.fromParameters(state.uri.queryParameters),
        simulateFailure: state.uri.queryParameters['fail'] == '1',
      ),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const AuthorFormScreen(),
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) =>
              _byId(state, (id) => AuthorDetailsScreen(id: id)),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) =>
                  _byId(state, (id) => AuthorFormScreen(id: id)),
            ),
          ],
        ),
      ],
    ),
    _catalog(
      path: '/genres',
      defaultSort: 'name',
      sorts: {'name'},
      list: (query, fail) =>
          GenreListScreen(query: query, simulateFailure: fail),
      create: () => const GenreFormScreen(),
      details: (id) => GenreDetailsScreen(id: id),
      edit: (id) => GenreFormScreen(id: id),
    ),
    _catalog(
      path: '/publishers',
      defaultSort: 'name',
      sorts: {'name', 'city'},
      list: (query, fail) =>
          PublisherListScreen(query: query, simulateFailure: fail),
      create: () => const PublisherFormScreen(),
      details: (id) => PublisherDetailsScreen(id: id),
      edit: (id) => PublisherFormScreen(id: id),
    ),
    _catalog(
      path: '/readers',
      defaultSort: 'lastName',
      sorts: {'lastName', 'email', 'card'},
      list: (query, fail) =>
          ReaderListScreen(query: query, simulateFailure: fail),
      create: () => const ReaderFormScreen(),
      details: (id) => ReaderDetailsScreen(id: id),
      edit: (id) => ReaderFormScreen(id: id),
    ),
  ],
  errorBuilder: (context, state) =>
      NotFoundScreen(location: state.uri.toString()),
);

GoRoute _catalog({
  required String path,
  required String defaultSort,
  required Set<String> sorts,
  required Widget Function(CatalogQuery query, bool fail) list,
  required Widget Function() create,
  required Widget Function(int id) details,
  required Widget Function(int id) edit,
}) {
  return GoRoute(
    path: path,
    builder: (context, state) => list(
      CatalogQuery.fromParameters(
        state.uri.queryParameters,
        defaultSort: defaultSort,
        allowedSorts: sorts,
      ),
      state.uri.queryParameters['fail'] == '1',
    ),
    routes: [
      GoRoute(path: 'new', builder: (context, state) => create()),
      GoRoute(
        path: ':id',
        builder: (context, state) => _byId(state, details),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => _byId(state, edit),
          ),
        ],
      ),
    ],
  );
}

Widget _byId(GoRouterState state, Widget Function(int id) build) {
  final id = int.tryParse(state.pathParameters['id'] ?? '');
  if (id == null) {
    return NotFoundScreen(location: state.uri.toString());
  }
  return build(id);
}

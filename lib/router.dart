import 'package:go_router/go_router.dart';

import 'models/author_query.dart';
import 'models/book_query.dart';
import 'screens/author_details_screen.dart';
import 'screens/author_list_screen.dart';
import 'screens/book_details_screen.dart';
import 'screens/book_list_screen.dart';
import 'screens/home_screen.dart';
import 'screens/not_found_screen.dart';

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
          path: ':id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) {
              return NotFoundScreen(location: state.uri.toString());
            }
            return BookDetailsScreen(id: id);
          },
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
          path: ':id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) {
              return NotFoundScreen(location: state.uri.toString());
            }
            return AuthorDetailsScreen(id: id);
          },
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) =>
      NotFoundScreen(location: state.uri.toString()),
);

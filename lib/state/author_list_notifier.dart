import '../models/author.dart';
import '../models/author_query.dart';
import '../repositories/author_repository.dart';
import 'entity_list_notifier.dart';

class AuthorListNotifier extends EntityListNotifier<Author, AuthorQuery> {
  AuthorListNotifier(AuthorRepository repository)
    : super(
        initialQuery: const AuthorQuery(),
        find: repository.find,
        deleteManyItems: repository.deleteMany,
        softDeleteItem: repository.softDelete,
        hardDeleteItem: repository.hardDelete,
        restoreItem: repository.restore,
      );
}

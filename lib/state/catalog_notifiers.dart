import '../models/catalog_query.dart';
import '../models/reader.dart';
import '../models/reference.dart';
import '../repositories/in_memory_genre_repository.dart';
import '../repositories/in_memory_publisher_repository.dart';
import '../repositories/in_memory_reader_repository.dart';
import 'entity_list_notifier.dart';

class GenreListNotifier extends EntityListNotifier<Genre, CatalogQuery> {
  GenreListNotifier(GenreRepository repository)
    : super(
        initialQuery: const CatalogQuery(),
        find: repository.find,
        deleteManyItems: repository.deleteMany,
        softDeleteItem: repository.softDelete,
        hardDeleteItem: repository.hardDelete,
        restoreItem: repository.restore,
      );
}

class PublisherListNotifier
    extends EntityListNotifier<Publisher, CatalogQuery> {
  PublisherListNotifier(PublisherRepository repository)
    : super(
        initialQuery: const CatalogQuery(),
        find: repository.find,
        deleteManyItems: repository.deleteMany,
        softDeleteItem: repository.softDelete,
        hardDeleteItem: repository.hardDelete,
        restoreItem: repository.restore,
      );
}

class ReaderListNotifier extends EntityListNotifier<Reader, CatalogQuery> {
  ReaderListNotifier(ReaderRepository repository)
    : super(
        initialQuery: const CatalogQuery(sortField: 'lastName'),
        find: repository.find,
        deleteManyItems: repository.deleteMany,
        softDeleteItem: repository.softDelete,
        hardDeleteItem: repository.hardDelete,
        restoreItem: repository.restore,
      );
}

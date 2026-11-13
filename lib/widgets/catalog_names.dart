import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../repositories/author_repository.dart';
import '../repositories/in_memory_genre_repository.dart';
import '../repositories/in_memory_publisher_repository.dart';

String joinedAuthors(BuildContext context, List<int> ids) {
  if (ids.isEmpty) {
    return '—';
  }
  final authors = context.read<AuthorRepository>().listAll(
    includeDeleted: true,
  );
  final names = <int, String>{
    for (final author in authors)
      author.id: '${author.lastName} ${author.firstName}',
  };
  return ids.map((id) => names[id] ?? 'Автор #$id').join(', ');
}

String authorLabel(BuildContext context, int id) {
  return joinedAuthors(context, [id]);
}

String joinedGenres(BuildContext context, List<int> ids) {
  if (ids.isEmpty) {
    return '—';
  }
  final genres = context.read<GenreRepository>().listAll(includeDeleted: true);
  final names = {for (final genre in genres) genre.id: genre.name};
  return ids.map((id) => names[id] ?? 'Жанр #$id').join(', ');
}

String publisherLabel(BuildContext context, int id) {
  final publishers = context.read<PublisherRepository>().listAll(
    includeDeleted: true,
  );
  for (final publisher in publishers) {
    if (publisher.id == id) {
      return publisher.name;
    }
  }
  return 'Издательство #$id';
}

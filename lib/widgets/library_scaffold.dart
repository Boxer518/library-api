import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../storage/storage_notice.dart';

class LibraryScaffold extends StatelessWidget {
  const LibraryScaffold({
    required this.title,
    required this.body,
    this.confirmLeave,
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final Widget body;
  final Future<bool> Function()? confirmLeave;
  final Widget? floatingActionButton;

  static const _sections = <(String, String)>[
    ('/', 'Главная'),
    ('/books', 'Книги'),
    ('/authors', 'Авторы'),
    ('/genres', 'Жанры'),
    ('/publishers', 'Издательства'),
    ('/readers', 'Читатели'),
  ];

  @override
  Widget build(BuildContext context) {
    final path = GoRouter.of(context).routeInformationProvider.value.uri.path;
    final section = _sectionOf(path);
    final wide = MediaQuery.sizeOf(context).width >= 1280;
    final notice = context.watch<StorageNotice>().message;

    return Scaffold(
      appBar: AppBar(
        title: wide
            ? Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  for (final item in _sections)
                    _sectionButton(context, section, item.$1, item.$2),
                ],
              )
            : Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: wide
            ? null
            : [
                PopupMenuButton<String>(
                  tooltip: 'Разделы',
                  onSelected: (value) => _open(context, section, value),
                  itemBuilder: (context) => [
                    for (final item in _sections)
                      PopupMenuItem(value: item.$1, child: Text(item.$2)),
                  ],
                ),
              ],
      ),
      floatingActionButton: floatingActionButton,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (notice != null)
            MaterialBanner(
              content: Text(notice),
              actions: [
                TextButton(
                  onPressed: () => context.read<StorageNotice>().dismiss(),
                  child: const Text('Скрыть'),
                ),
              ],
            ),
          Expanded(child: body),
        ],
      ),
    );
  }

  String _sectionOf(String path) {
    for (final item in _sections) {
      if (item.$1 != '/' && path.startsWith(item.$1)) {
        return item.$1;
      }
    }
    return '/';
  }

  Future<void> _open(BuildContext context, String section, String path) async {
    if (path == section) {
      return;
    }
    final confirm = confirmLeave;
    if (confirm != null) {
      final leave = await confirm();
      if (!leave || !context.mounted) {
        return;
      }
    }
    context.go(path);
  }

  Widget _sectionButton(
    BuildContext context,
    String section,
    String path,
    String label,
  ) {
    final selected = section == path;
    return TextButton(
      onPressed: selected ? null : () => _open(context, section, path),
      child: Text(label),
    );
  }
}

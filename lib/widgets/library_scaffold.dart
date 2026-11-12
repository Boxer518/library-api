import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class LibraryScaffold extends StatelessWidget {
  const LibraryScaffold({required this.title, required this.body, super.key});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final path = GoRouter.of(context).state.uri.path;
    final section = path.startsWith('/books')
        ? '/books'
        : path.startsWith('/authors')
        ? '/authors'
        : '/';
    final wide = MediaQuery.sizeOf(context).width >= 720;

    final links = <Widget>[
      _sectionButton(context, section, '/', 'Главная'),
      _sectionButton(context, section, '/books', 'Книги'),
      _sectionButton(context, section, '/authors', 'Авторы'),
    ];

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
                  ...links,
                ],
              )
            : Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: wide
            ? null
            : [
                PopupMenuButton<String>(
                  tooltip: 'Разделы',
                  onSelected: (value) {
                    if (value != section) {
                      context.go(value);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: '/', child: Text('Главная')),
                    PopupMenuItem(value: '/books', child: Text('Книги')),
                    PopupMenuItem(value: '/authors', child: Text('Авторы')),
                  ],
                ),
              ],
      ),
      body: body,
    );
  }

  Widget _sectionButton(
    BuildContext context,
    String section,
    String path,
    String label,
  ) {
    final selected = section == path;
    return TextButton(
      onPressed: selected ? null : () => context.go(path),
      child: Text(label),
    );
  }
}

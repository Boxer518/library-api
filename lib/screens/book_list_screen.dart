import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/api_debug.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../repositories/in_memory_genre_repository.dart';
import '../repositories/in_memory_publisher_repository.dart';
import '../state/book_list_notifier.dart';
import '../widgets/catalog_list_view.dart';
import '../widgets/catalog_names.dart';
import '../widgets/confirm.dart';
import '../widgets/debounced_text_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/library_scaffold.dart';
import '../widgets/record_actions.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({
    required this.query,
    required this.simulateFailure,
    super.key,
  });

  final BookQuery query;
  final bool simulateFailure;

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  var _syncScheduled = false;
  String? _probe;

  @override
  void initState() {
    super.initState();
    _scheduleSync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final probe = readNetworkProbe(context);
    if (probe == null || probe == _probe) {
      return;
    }
    final first = _probe == null;
    _probe = probe;
    if (!first) {
      _scheduleSync();
    }
  }

  @override
  void didUpdateWidget(BookListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query ||
        oldWidget.simulateFailure != widget.simulateFailure) {
      _scheduleSync();
    }
  }

  /// Загрузка меняет провайдер, поэтому её нельзя запускать прямо из
  /// didUpdateWidget: это середина сборки маршрута.
  void _scheduleSync() {
    if (_syncScheduled) {
      return;
    }
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      _syncFromRoute();
    });
  }

  void _syncFromRoute() {
    if (!mounted) {
      return;
    }
    readNetworkProbe(context);
    final notifier = context.read<BookListNotifier>();
    if (widget.simulateFailure) {
      notifier.demonstrateError();
      return;
    }
    notifier.applyQuery(widget.query);
  }

  void _go(BookQuery next) {
    if (!mounted || next == widget.query) {
      return;
    }
    context.go(next.toLocation('/books'));
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BookListNotifier>();
    final query = widget.query;
    final result = notifier.result;
    return LibraryScaffold(
      title: 'Книги',
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-book'),
        onPressed: () => context.push('/books/new'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      body: CatalogListView<Book>(
        title: 'Книги',
        filters: [
          SizedBox(
            width: 280,
            child: DebouncedTextField(
              key: const Key('book-search'),
              value: query.search,
              label: 'Название или ISBN',
              onDebounced: (value) {
                if (value == query.search) {
                  return;
                }
                _go(query.copyWith(search: value));
              },
            ),
          ),
          _idDropdown(
            label: 'Жанр',
            fieldKey: const Key('books-genre'),
            value: query.genreId,
            emptyLabel: 'Все жанры',
            options: [
              for (final genre in context.read<GenreRepository>().listAll(
                includeDeleted: true,
              ))
                if (!genre.isDeleted || genre.id == query.genreId)
                  (genre.id, genre.name),
            ],
            onChanged: (value) => _go(query.copyWith(genreId: value)),
          ),
          _idDropdown(
            label: 'Издательство',
            fieldKey: const Key('books-publisher'),
            value: query.publisherId,
            emptyLabel: 'Все издательства',
            options: [
              for (final publisher
                  in context.read<PublisherRepository>().listAll(
                    includeDeleted: true,
                  ))
                if (!publisher.isDeleted || publisher.id == query.publisherId)
                  (publisher.id, publisher.name),
            ],
            onChanged: (value) => _go(query.copyWith(publisherId: value)),
          ),
          SizedBox(
            width: 120,
            child: DebouncedTextField(
              key: const Key('books-year-from'),
              value: query.yearFrom?.toString() ?? '',
              label: 'Год от',
              keyboardType: TextInputType.number,
              onDebounced: (raw) => _applyYear(raw, from: true),
            ),
          ),
          SizedBox(
            width: 120,
            child: DebouncedTextField(
              key: const Key('books-year-to'),
              value: query.yearTo?.toString() ?? '',
              label: 'Год до',
              keyboardType: TextInputType.number,
              onDebounced: (raw) => _applyYear(raw, from: false),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                key: const Key('books-deleted-switch'),
                value: query.includeDeleted,
                onChanged: (value) =>
                    _go(query.copyWith(includeDeleted: value)),
              ),
              const Text('Показывать удалённые'),
            ],
          ),
          TextButton(
            onPressed: query == const BookQuery()
                ? null
                : () => context.go('/books'),
            child: const Text('Сбросить'),
          ),
        ],
        status: notifier.status,
        error: notifier.error,
        items: result.items,
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
        hasPrevious: result.hasPrevious,
        hasNext: result.hasNext,
        pageSize: query.size,
        selectedCount: notifier.selected.length,
        selected: notifier.selected,
        onToggleSelect: notifier.toggleSelection,
        onSelectPage: () =>
            notifier.selectMany(result.items.map((book) => book.id)),
        onClearSelection: notifier.clearSelection,
        onDeleteSelected: notifier.hasSelection ? _deleteSelected : null,
        onRetry: _retry,
        onPage: (page) => _go(query.copyWith(page: page)),
        onPageSize: (size) => _go(query.copyWith(size: size)),
        columns: _columns(context),
        idOf: (book) => book.id,
        sortField: query.sortField,
        sortAscending: query.sortAscending,
        onSort: (field) => _go(
          query.copyWith(
            sortField: field,
            sortAscending: field == query.sortField
                ? !query.sortAscending
                : true,
          ),
        ),
        actions: (book) => recordActions(
          deleted: book.isDeleted,
          onOpen: () => context.push('/books/${book.id}'),
          onSoftDelete: () => _softDelete(book),
          onHardDelete: () => _hardDelete(book),
          onRestore: () => _restore(book),
        ),
        cardTitle: (book) => _titleButton(context, book),
        cardSubtitle: (book) => Text(_subtitle(book)),
        tableKey: const Key('book-table'),
        cardsKey: const Key('book-cards'),
      ),
    );
  }

  List<TableColumnSpec<Book>> _columns(BuildContext context) {
    return [
      TableColumnSpec(
        label: 'Название',
        sortField: 'title',
        build: (book) => _titleButton(context, book),
      ),
      TableColumnSpec(
        label: 'Авторы',
        build: (book) => Text(joinedAuthors(context, book.authorIds)),
      ),
      TableColumnSpec(
        label: 'Год',
        sortField: 'year',
        numeric: true,
        build: (book) => Text('${book.year}'),
      ),
      TableColumnSpec(
        label: 'Страниц',
        sortField: 'pages',
        numeric: true,
        build: (book) => Text('${book.pages}'),
      ),
      TableColumnSpec(label: 'ISBN', build: (book) => Text(book.isbn)),
      TableColumnSpec(
        label: 'Издательство',
        build: (book) => Text(publisherLabel(context, book.publisherId)),
      ),
      TableColumnSpec(
        label: 'Жанры',
        build: (book) => Text(joinedGenres(context, book.genreIds)),
      ),
      TableColumnSpec(
        label: 'Экземпляры',
        numeric: true,
        build: (book) => Text('${book.copiesAvailable}/${book.copiesTotal}'),
      ),
    ];
  }

  Widget _titleButton(BuildContext context, Book book) {
    final label = book.isDeleted ? '${book.title} (удалена)' : book.title;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () => context.push('/books/${book.id}'),
        child: Text(
          label,
          style: book.isDeleted
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
      ),
    );
  }

  String _subtitle(Book book) {
    return '${joinedAuthors(context, book.authorIds)}\n'
        '${book.year} · ${publisherLabel(context, book.publisherId)} · ${book.isbn}';
  }

  void _applyYear(String raw, {required bool from}) {
    final text = raw.trim();
    int? year;
    if (text.isNotEmpty) {
      year = int.tryParse(text);
      if (year == null) {
        return;
      }
    }
    final current = from ? widget.query.yearFrom : widget.query.yearTo;
    if (year == current) {
      return;
    }
    _go(
      from
          ? widget.query.copyWith(yearFrom: year)
          : widget.query.copyWith(yearTo: year),
    );
  }

  void _retry() {
    final notifier = context.read<BookListNotifier>();
    if (widget.simulateFailure) {
      notifier.demonstrateError();
      return;
    }
    notifier.load();
  }

  Future<void> _deleteSelected() {
    final notifier = context.read<BookListNotifier>();
    final count = notifier.selected.length;
    return runConfirmed(
      context,
      title: 'Удалить выбранные',
      message:
          'Логически удалить $count записей? Они пропадут из списка, '
          'пока не включён показ удалённых.',
      confirmLabel: 'Удалить',
      action: () async {
        final removed = await notifier.deleteSelected();
        return 'Удалено записей: $removed';
      },
    );
  }

  Future<void> _softDelete(Book book) {
    return runConfirmed(
      context,
      title: 'Логическое удаление',
      message: 'Скрыть «${book.title}» из каталога?',
      confirmLabel: 'Скрыть',
      action: () async {
        await context.read<BookListNotifier>().softDelete(book.id);
        return 'Книга скрыта';
      },
    );
  }

  Future<void> _hardDelete(Book book) {
    return runConfirmed(
      context,
      title: 'Физическое удаление',
      message: 'Стереть «${book.title}» без возможности восстановления?',
      confirmLabel: 'Удалить навсегда',
      action: () async {
        await context.read<BookListNotifier>().hardDelete(book.id);
        return 'Книга удалена навсегда';
      },
    );
  }

  Future<void> _restore(Book book) {
    return runConfirmed(
      context,
      title: 'Восстановление',
      message: 'Вернуть «${book.title}» в каталог?',
      confirmLabel: 'Восстановить',
      action: () async {
        await context.read<BookListNotifier>().restore(book.id);
        return 'Книга восстановлена';
      },
    );
  }
}

Widget _idDropdown({
  required String label,
  required Key fieldKey,
  required int? value,
  required String emptyLabel,
  required List<(int, String)> options,
  required ValueChanged<int?> onChanged,
}) {
  final known = value != null && options.any((option) => option.$1 == value);
  return SizedBox(
    width: 230,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          key: fieldKey,
          isExpanded: true,
          value: value ?? 0,
          items: [
            DropdownMenuItem(value: 0, child: Text(emptyLabel)),
            if (value != null && value != 0 && !known)
              DropdownMenuItem(value: value, child: Text('#$value')),
            for (final option in options)
              if (option.$1 != 0)
                DropdownMenuItem(value: option.$1, child: Text(option.$2)),
          ],
          onChanged: (next) =>
              onChanged(next == null || next == 0 ? null : next),
        ),
      ),
    ),
  );
}

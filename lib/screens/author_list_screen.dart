import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/author.dart';
import '../models/author_query.dart';
import '../state/author_list_notifier.dart';
import '../widgets/catalog_list_view.dart';
import '../widgets/confirm.dart';
import '../widgets/debounced_text_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/library_scaffold.dart';
import '../widgets/record_actions.dart';

class AuthorListScreen extends StatefulWidget {
  const AuthorListScreen({
    required this.query,
    required this.simulateFailure,
    super.key,
  });

  final AuthorQuery query;
  final bool simulateFailure;

  @override
  State<AuthorListScreen> createState() => _AuthorListScreenState();
}

class _AuthorListScreenState extends State<AuthorListScreen> {
  var _syncScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleSync();
  }

  @override
  void didUpdateWidget(AuthorListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query ||
        oldWidget.simulateFailure != widget.simulateFailure) {
      _scheduleSync();
    }
  }

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
    final notifier = context.read<AuthorListNotifier>();
    if (widget.simulateFailure) {
      notifier.demonstrateError();
      return;
    }
    notifier.applyQuery(widget.query);
  }

  void _go(AuthorQuery next) {
    if (!mounted || next == widget.query) {
      return;
    }
    context.go(next.toLocation('/authors'));
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AuthorListNotifier>();
    final query = widget.query;
    final result = notifier.result;
    return LibraryScaffold(
      title: 'Авторы',
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-author'),
        onPressed: () => context.push('/authors/new'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      body: CatalogListView<Author>(
        title: 'Авторы',
        filters: [
          SizedBox(
            width: 280,
            child: DebouncedTextField(
              key: const Key('author-search'),
              value: query.search,
              label: 'Фамилия или страна',
              onDebounced: (value) {
                if (value == query.search) {
                  return;
                }
                _go(query.copyWith(search: value));
              },
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                key: const Key('authors-deleted-switch'),
                value: query.includeDeleted,
                onChanged: (value) =>
                    _go(query.copyWith(includeDeleted: value)),
              ),
              const Text('Показывать удалённые'),
            ],
          ),
          TextButton(
            onPressed: query == const AuthorQuery()
                ? null
                : () => context.go('/authors'),
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
            notifier.selectMany(result.items.map((author) => author.id)),
        onClearSelection: notifier.clearSelection,
        onDeleteSelected: notifier.hasSelection ? _deleteSelected : null,
        onRetry: _retry,
        onPage: (page) => _go(query.copyWith(page: page)),
        onPageSize: (size) => _go(query.copyWith(size: size)),
        columns: _columns(context),
        idOf: (author) => author.id,
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
        actions: (author) => recordActions(
          deleted: author.isDeleted,
          onOpen: () => context.push('/authors/${author.id}'),
          onSoftDelete: () => _softDelete(author),
          onHardDelete: () => _hardDelete(author),
          onRestore: () => _restore(author),
        ),
        cardTitle: (author) => _titleButton(context, author),
        cardSubtitle: (author) => Text(
          '${author.firstName}'
          '${author.middleName.isEmpty ? '' : ' ${author.middleName}'}\n'
          '${author.country} · ${author.birthYear}',
        ),
        tableKey: const Key('author-table'),
        cardsKey: const Key('author-cards'),
      ),
    );
  }

  List<TableColumnSpec<Author>> _columns(BuildContext context) {
    return [
      TableColumnSpec(
        label: 'Фамилия',
        sortField: 'lastName',
        build: (author) => _titleButton(context, author),
      ),
      TableColumnSpec(label: 'Имя', build: (author) => Text(author.firstName)),
      TableColumnSpec(
        label: 'Отчество',
        build: (author) =>
            Text(author.middleName.isEmpty ? '—' : author.middleName),
      ),
      TableColumnSpec(
        label: 'Страна',
        sortField: 'country',
        build: (author) => Text(author.country),
      ),
      TableColumnSpec(
        label: 'Год рождения',
        sortField: 'birthYear',
        numeric: true,
        build: (author) => Text('${author.birthYear}'),
      ),
    ];
  }

  Widget _titleButton(BuildContext context, Author author) {
    final label = author.isDeleted
        ? '${author.lastName} (удалён)'
        : author.lastName;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () => context.push('/authors/${author.id}'),
        child: Text(
          label,
          style: author.isDeleted
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
      ),
    );
  }

  void _retry() {
    final notifier = context.read<AuthorListNotifier>();
    if (widget.simulateFailure) {
      notifier.demonstrateError();
      return;
    }
    notifier.load();
  }

  Future<void> _deleteSelected() {
    final notifier = context.read<AuthorListNotifier>();
    final count = notifier.selected.length;
    return runConfirmed(
      context,
      title: 'Удалить выбранные',
      message: 'Логически удалить $count авторов?',
      confirmLabel: 'Удалить',
      action: () async {
        final removed = await notifier.deleteSelected();
        return 'Удалено записей: $removed';
      },
    );
  }

  Future<void> _softDelete(Author author) {
    return runConfirmed(
      context,
      title: 'Логическое удаление',
      message: 'Скрыть ${author.fullName} из списка?',
      confirmLabel: 'Скрыть',
      action: () async {
        await context.read<AuthorListNotifier>().softDelete(author.id);
        return 'Автор скрыт';
      },
    );
  }

  Future<void> _hardDelete(Author author) {
    return runConfirmed(
      context,
      title: 'Физическое удаление',
      message: 'Стереть ${author.fullName} без возможности восстановления?',
      confirmLabel: 'Удалить навсегда',
      action: () async {
        await context.read<AuthorListNotifier>().hardDelete(author.id);
        return 'Автор удалён навсегда';
      },
    );
  }

  Future<void> _restore(Author author) {
    return runConfirmed(
      context,
      title: 'Восстановление',
      message: 'Вернуть ${author.fullName} в список?',
      confirmLabel: 'Восстановить',
      action: () async {
        await context.read<AuthorListNotifier>().restore(author.id);
        return 'Автор восстановлен';
      },
    );
  }
}

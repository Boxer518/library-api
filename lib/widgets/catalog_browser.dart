import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../models/catalog_query.dart';
import '../state/entity_list_notifier.dart';
import 'catalog_list_view.dart';
import 'confirm.dart';
import 'debounced_text_field.dart';
import 'entity_table.dart';
import 'library_scaffold.dart';
import 'record_actions.dart';

/// Список жанра, издательства или читателя на общем каркасе каталога.
class CatalogBrowser<T> extends StatefulWidget {
  const CatalogBrowser({
    required this.title,
    required this.query,
    required this.simulateFailure,
    required this.watch,
    required this.read,
    required this.basePath,
    required this.searchLabel,
    required this.defaultSort,
    required this.columns,
    required this.idOf,
    required this.cardTitle,
    required this.cardSubtitle,
    required this.tableKey,
    required this.cardsKey,
    required this.isDeleted,
    this.deletionBlock,
    super.key,
  });

  final String title;
  final CatalogQuery query;
  final bool simulateFailure;
  final EntityListNotifier<T, CatalogQuery> Function(BuildContext context)
  watch;
  final EntityListNotifier<T, CatalogQuery> Function(BuildContext context) read;
  final String basePath;
  final String searchLabel;
  final String defaultSort;
  final List<TableColumnSpec<T>> Function(
    BuildContext context,
    void Function(int id) open,
  )
  columns;
  final int Function(T item) idOf;
  final Widget Function(BuildContext context, T item, VoidCallback open)
  cardTitle;
  final Widget Function(T item) cardSubtitle;
  final Key tableKey;
  final Key cardsKey;
  final bool Function(T item) isDeleted;
  final Future<String?> Function(List<int> ids)? deletionBlock;

  @override
  State<CatalogBrowser<T>> createState() => _CatalogBrowserState<T>();
}

class _CatalogBrowserState<T> extends State<CatalogBrowser<T>> {
  var _syncScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleSync();
  }

  @override
  void didUpdateWidget(CatalogBrowser<T> oldWidget) {
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
    final notifier = widget.read(context);
    if (widget.simulateFailure) {
      notifier.demonstrateError();
      return;
    }
    notifier.applyQuery(widget.query);
  }

  void _go(CatalogQuery next) {
    if (!mounted || next == widget.query) {
      return;
    }
    context.go(
      next.toLocation(widget.basePath, defaultSort: widget.defaultSort),
    );
  }

  void _open(int id) => context.push('${widget.basePath}/$id');

  @override
  Widget build(BuildContext context) {
    final notifier = widget.watch(context);
    final query = widget.query;
    final result = notifier.result;
    return LibraryScaffold(
      title: widget.title,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('${widget.basePath}/new'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      body: CatalogListView<T>(
        title: widget.title,
        filters: [
          SizedBox(
            width: 280,
            child: DebouncedTextField(
              value: query.search,
              label: widget.searchLabel,
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
                value: query.includeDeleted,
                onChanged: (value) =>
                    _go(query.copyWith(includeDeleted: value)),
              ),
              const Text('Показывать удалённые'),
            ],
          ),
          TextButton(
            onPressed: query == CatalogQuery(sortField: widget.defaultSort)
                ? null
                : () => context.go(widget.basePath),
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
        onSelectPage: () => notifier.selectMany(result.items.map(widget.idOf)),
        onClearSelection: notifier.clearSelection,
        onDeleteSelected: notifier.hasSelection
            ? () => _deleteIds(
                notifier.selected.toList(),
                notifier.deleteSelected,
              )
            : null,
        onRetry: () {
          if (widget.simulateFailure) {
            notifier.demonstrateError();
            return;
          }
          notifier.load();
        },
        onPage: (page) => _go(query.copyWith(page: page)),
        onPageSize: (size) => _go(query.copyWith(size: size)),
        columns: widget.columns(context, _open),
        idOf: widget.idOf,
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
        actions: (item) {
          final id = widget.idOf(item);
          final deleted = widget.isDeleted(item);
          return recordActions(
            deleted: deleted,
            onOpen: () => _open(id),
            onSoftDelete: () =>
                _mutate(id, notifier.softDelete, 'Скрыть запись?'),
            onHardDelete: () => _mutate(
              id,
              notifier.hardDelete,
              'Удалить запись без восстановления?',
              forever: true,
            ),
            onRestore: () => _mutate(
              id,
              notifier.restore,
              'Вернуть запись в список?',
              checkBlock: false,
            ),
          );
        },
        cardTitle: (item) =>
            widget.cardTitle(context, item, () => _open(widget.idOf(item))),
        cardSubtitle: widget.cardSubtitle,
        tableKey: widget.tableKey,
        cardsKey: widget.cardsKey,
      ),
    );
  }

  Future<void> _deleteIds(List<int> ids, Future<int> Function() remove) async {
    final blocked = await widget.deletionBlock?.call(ids);
    if (!mounted) {
      return;
    }
    if (blocked != null) {
      await showBlocked(context, blocked);
      return;
    }
    await runConfirmed(
      context,
      title: 'Удалить выбранные',
      message: 'Логически удалить ${ids.length} записей?',
      confirmLabel: 'Удалить',
      action: () async {
        final count = await remove();
        return 'Удалено записей: $count';
      },
    );
  }

  Future<void> _mutate(
    int id,
    Future<void> Function(int id) action,
    String message, {
    bool forever = false,
    bool checkBlock = true,
  }) async {
    final blocked = checkBlock ? await widget.deletionBlock?.call([id]) : null;
    if (!mounted) {
      return;
    }
    if (blocked != null) {
      await showBlocked(context, blocked);
      return;
    }
    await runConfirmed(
      context,
      title: forever ? 'Физическое удаление' : 'Подтверждение',
      message: message,
      confirmLabel: forever ? 'Удалить навсегда' : 'Подтвердить',
      action: () async {
        await action(id);
        return 'Готово';
      },
    );
  }
}

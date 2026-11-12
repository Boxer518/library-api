import 'package:material_ui/material_ui.dart';

import '../state/load_status.dart';
import 'entity_card_list.dart';
import 'entity_table.dart';

/// Каркас списка: фильтры, четыре состояния, таблица или карточки, страницы.
class CatalogListView<T> extends StatelessWidget {
  const CatalogListView({
    required this.title,
    required this.filters,
    required this.status,
    required this.error,
    required this.items,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.hasPrevious,
    required this.hasNext,
    required this.pageSize,
    required this.selectedCount,
    required this.selected,
    required this.onToggleSelect,
    required this.onSelectPage,
    required this.onClearSelection,
    required this.onDeleteSelected,
    required this.onRetry,
    required this.onPage,
    required this.onPageSize,
    required this.columns,
    required this.idOf,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    required this.actions,
    required this.cardTitle,
    required this.cardSubtitle,
    required this.tableKey,
    required this.cardsKey,
    super.key,
  });

  final String title;
  final List<Widget> filters;
  final LoadStatus status;
  final String? error;
  final List<T> items;
  final int total;
  final int page;
  final int totalPages;
  final bool hasPrevious;
  final bool hasNext;
  final int pageSize;
  final int selectedCount;
  final Set<int> selected;
  final ValueChanged<int> onToggleSelect;
  final VoidCallback onSelectPage;
  final VoidCallback onClearSelection;
  final VoidCallback? onDeleteSelected;
  final VoidCallback onRetry;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onPageSize;
  final List<TableColumnSpec<T>> columns;
  final int Function(T item) idOf;
  final String sortField;
  final bool sortAscending;
  final void Function(String field) onSort;
  final List<Widget> Function(T item) actions;
  final Widget Function(T item) cardTitle;
  final Widget Function(T item) cardSubtitle;
  final Key tableKey;
  final Key cardsKey;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final showPager = status == LoadStatus.success;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: filters,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Выбрано: $selectedCount'),
              TextButton(
                onPressed: items.isEmpty ? null : onSelectPage,
                child: const Text('Выбрать страницу'),
              ),
              TextButton(
                onPressed: selectedCount == 0 ? null : onClearSelection,
                child: const Text('Снять выделение'),
              ),
              FilledButton.icon(
                onPressed: onDeleteSelected,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Удалить выбранные'),
              ),
            ],
          ),
        ),
        Expanded(child: _body(context, wide)),
        if (showPager) _pager(context),
      ],
    );
  }

  Widget _body(BuildContext context, bool wide) {
    return switch (status) {
      LoadStatus.idle || LoadStatus.loading => const Center(
        child: CircularProgressIndicator(key: Key('catalog-loading')),
      ),
      LoadStatus.error => _StatusPane(
        icon: Icons.error_outline,
        title: 'Не удалось загрузить данные',
        message: error ?? 'Неизвестная ошибка',
        action: FilledButton(
          onPressed: onRetry,
          child: const Text('Повторить'),
        ),
      ),
      LoadStatus.success when total == 0 => const _StatusPane(
        icon: Icons.search_off,
        title: 'Ничего не найдено',
        message: 'Измените поиск или снимите часть фильтров.',
      ),
      LoadStatus.success when items.isEmpty => const _StatusPane(
        icon: Icons.filter_none,
        title: 'На этой странице нет записей',
        message: 'Вернитесь на предыдущую страницу.',
      ),
      LoadStatus.success when wide => EntityTable<T>(
        key: tableKey,
        columns: columns,
        items: items,
        idOf: idOf,
        selected: selected,
        onToggleSelect: onToggleSelect,
        sortField: sortField,
        sortAscending: sortAscending,
        onSort: onSort,
        actions: actions,
      ),
      LoadStatus.success => EntityCardList<T>(
        key: cardsKey,
        items: items,
        idOf: idOf,
        selected: selected,
        onToggleSelect: onToggleSelect,
        title: cardTitle,
        subtitle: cardSubtitle,
        actions: actions,
      ),
    };
  }

  Widget _pager(BuildContext context) {
    return Material(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Записей: $total · страница $page из $totalPages'),
            IconButton(
              key: const Key('page-first'),
              tooltip: 'Первая страница',
              onPressed: page > 1 ? () => onPage(1) : null,
              icon: const Icon(Icons.first_page),
            ),
            IconButton(
              key: const Key('page-prev'),
              tooltip: 'Предыдущая страница',
              onPressed: hasPrevious ? () => onPage(page - 1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              key: const Key('page-next'),
              tooltip: 'Следующая страница',
              onPressed: hasNext ? () => onPage(page + 1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
            IconButton(
              key: const Key('page-last'),
              tooltip: 'Последняя страница',
              onPressed: page < totalPages ? () => onPage(totalPages) : null,
              icon: const Icon(Icons.last_page),
            ),
            DropdownButton<int>(
              key: const Key('page-size'),
              value: pageSize,
              items: const [
                DropdownMenuItem(value: 10, child: Text('10')),
                DropdownMenuItem(value: 25, child: Text('25')),
                DropdownMenuItem(value: 50, child: Text('50')),
              ],
              onChanged: (value) {
                if (value != null) {
                  onPageSize(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPane extends StatelessWidget {
  const _StatusPane({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

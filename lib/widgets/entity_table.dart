import 'package:material_ui/material_ui.dart';

class TableColumnSpec<T> {
  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });

  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;
}

/// Одна таблица на все сущности. Колонки, сортировка и действия приходят снаружи.
class EntityTable<T> extends StatefulWidget {
  const EntityTable({
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
    super.key,
  });

  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;

  @override
  State<EntityTable<T>> createState() => _EntityTableState<T>();
}

class _EntityTableState<T> extends State<EntityTable<T>> {
  final ScrollController _vertical = ScrollController();
  final ScrollController _horizontal = ScrollController();

  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortIndex = _sortIndex();
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          controller: _vertical,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _vertical,
            child: Scrollbar(
              controller: _horizontal,
              thumbVisibility: true,
              notificationPredicate: (notification) =>
                  notification.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                controller: _horizontal,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    sortColumnIndex: sortIndex,
                    sortAscending: widget.sortAscending,
                    showCheckboxColumn: widget.onToggleSelect != null,
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 88,
                    columns: [
                      for (final column in widget.columns)
                        DataColumn(
                          label: Text(column.label),
                          numeric: column.numeric,
                          onSort:
                              column.sortField == null || widget.onSort == null
                              ? null
                              : (_, _) => widget.onSort!(column.sortField!),
                        ),
                      if (widget.actions != null)
                        const DataColumn(label: Text('Действия')),
                    ],
                    rows: [
                      for (final item in widget.items)
                        DataRow(
                          selected: widget.selected.contains(widget.idOf(item)),
                          onSelectChanged: widget.onToggleSelect == null
                              ? null
                              : (_) =>
                                    widget.onToggleSelect!(widget.idOf(item)),
                          cells: [
                            for (final column in widget.columns)
                              DataCell(column.build(item)),
                            if (widget.actions != null)
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: widget.actions!(item),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  int? _sortIndex() {
    final field = widget.sortField;
    if (field == null) {
      return null;
    }
    final index = widget.columns.indexWhere(
      (column) => column.sortField == field,
    );
    return index == -1 ? null : index;
  }
}

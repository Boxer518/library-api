import 'package:material_ui/material_ui.dart';

/// Список карточек для узкого окна. Та же модель колонок не нужна:
/// экран сам собирает заголовок и подпись.
class EntityCardList<T> extends StatelessWidget {
  const EntityCardList({
    required this.items,
    required this.idOf,
    required this.title,
    required this.subtitle,
    this.selected = const {},
    this.onToggleSelect,
    this.actions,
    super.key,
  });

  final List<T> items;
  final int Function(T item) idOf;
  final Widget Function(T item) title;
  final Widget Function(T item) subtitle;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final List<Widget> Function(T item)? actions;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final id = idOf(item);
        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (onToggleSelect != null)
                      Checkbox(
                        value: selected.contains(id),
                        onChanged: (_) => onToggleSelect!(id),
                      ),
                    Expanded(child: title(item)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 12),
                  child: subtitle(item),
                ),
                if (actions != null) Wrap(spacing: 4, children: actions!(item)),
              ],
            ),
          ),
        );
      },
    );
  }
}

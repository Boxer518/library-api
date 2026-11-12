import 'package:material_ui/material_ui.dart';

List<Widget> recordActions({
  required bool deleted,
  required VoidCallback onOpen,
  required VoidCallback onSoftDelete,
  required VoidCallback onHardDelete,
  required VoidCallback onRestore,
}) {
  return [
    IconButton(
      tooltip: 'Открыть карточку',
      onPressed: onOpen,
      icon: const Icon(Icons.open_in_new),
    ),
    if (!deleted)
      IconButton(
        tooltip: 'Логическое удаление',
        onPressed: onSoftDelete,
        icon: const Icon(Icons.delete_outline),
      ),
    if (deleted)
      IconButton(
        tooltip: 'Восстановить',
        onPressed: onRestore,
        icon: const Icon(Icons.restore),
      ),
    IconButton(
      tooltip: 'Удалить навсегда',
      onPressed: onHardDelete,
      icon: const Icon(Icons.delete_forever),
    ),
  ];
}

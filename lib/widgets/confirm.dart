import 'package:material_ui/material_ui.dart';

Future<String?> runConfirmed(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required Future<String?> Function() action,
}) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  if (accepted != true || !context.mounted) {
    return null;
  }
  final notice = await action();
  if (notice != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(notice)));
  }
  return notice;
}

Future<bool> askToLeave(BuildContext context) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Несохранённые изменения'),
        content: const Text('Уйти со страницы без сохранения?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Остаться'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Уйти'),
          ),
        ],
      );
    },
  );
  return accepted == true;
}

Future<void> showBlocked(BuildContext context, String message) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Удаление невозможно'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Понятно'),
          ),
        ],
      );
    },
  );
}

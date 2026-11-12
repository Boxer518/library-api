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

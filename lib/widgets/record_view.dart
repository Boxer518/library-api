import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../state/load_status.dart';
import 'library_scaffold.dart';

class RecordView extends StatelessWidget {
  const RecordView({
    required this.title,
    required this.status,
    required this.error,
    required this.missing,
    required this.backPath,
    required this.lines,
    required this.deleted,
    required this.onEdit,
    required this.onSoftDelete,
    required this.onRestore,
    required this.onHardDelete,
    super.key,
  });

  final String title;
  final LoadStatus status;
  final String? error;
  final bool missing;
  final String backPath;
  final List<(String, String)> lines;
  final bool deleted;
  final VoidCallback? onEdit;
  final VoidCallback? onSoftDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onHardDelete;

  @override
  Widget build(BuildContext context) {
    return LibraryScaffold(
      title: title,
      body: switch (status) {
        LoadStatus.idle ||
        LoadStatus.loading => const Center(child: CircularProgressIndicator()),
        LoadStatus.error => Center(child: Text(error ?? 'Ошибка')),
        LoadStatus.success when missing => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Запись не найдена'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go(backPath),
                child: const Text('К списку'),
              ),
            ],
          ),
        ),
        LoadStatus.success => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }
                  context.go(backPath);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('К списку'),
              ),
            ),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            if (deleted) ...[
              const SizedBox(height: 8),
              const Text('Запись удалена логически'),
            ],
            const SizedBox(height: 16),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 180, child: Text(line.$1)),
                    Expanded(child: Text(line.$2)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (onEdit != null)
                  FilledButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text('Изменить'),
                  ),
                if (onSoftDelete != null)
                  OutlinedButton.icon(
                    onPressed: onSoftDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Скрыть'),
                  ),
                if (onRestore != null)
                  FilledButton.icon(
                    onPressed: onRestore,
                    icon: const Icon(Icons.restore),
                    label: const Text('Восстановить'),
                  ),
                if (onHardDelete != null)
                  FilledButton.tonalIcon(
                    onPressed: onHardDelete,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Удалить навсегда'),
                  ),
              ],
            ),
          ],
        ),
      },
    );
  }
}

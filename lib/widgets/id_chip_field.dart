import 'package:material_ui/material_ui.dart';

/// Множественный выбор идентификаторов. Участвует в общем validate().
class IdChipField extends StatelessWidget {
  const IdChipField({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.emptyMessage,
    this.serverError,
    super.key,
  });

  final String label;
  final List<(int, String)> options;
  final List<int> value;
  final ValueChanged<List<int>> onChanged;
  final String emptyMessage;
  final String? Function()? serverError;

  @override
  Widget build(BuildContext context) {
    return FormField<List<int>>(
      initialValue: value,
      validator: (selected) {
        final server = serverError?.call();
        if (server != null && server.isNotEmpty) {
          return server;
        }
        return (selected == null || selected.isEmpty) ? emptyMessage : null;
      },
      builder: (field) {
        final selected = field.value ?? const <int>[];
        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            errorText: field.errorText,
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                FilterChip(
                  label: Text(option.$2),
                  selected: selected.contains(option.$1),
                  onSelected: (_) {
                    final next = [...selected];
                    if (!next.remove(option.$1)) {
                      next.add(option.$1);
                    }
                    field.didChange(next);
                    onChanged(next);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

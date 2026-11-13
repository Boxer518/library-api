import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/api_exceptions.dart';
import 'confirm.dart';
import 'library_scaffold.dart';

/// Общая разметка формы: проверка, отправка и предупреждение при уходе.
class EntityForm extends StatefulWidget {
  const EntityForm({
    required this.title,
    required this.isEditing,
    required this.fields,
    required this.onSubmit,
    required this.dirty,
    this.ready = true,
    this.missing,
    this.clearServerErrors,
    this.onValidation,
    super.key,
  });

  final String title;
  final bool isEditing;
  final List<Widget> fields;
  final Future<bool> Function() onSubmit;
  final bool dirty;
  final bool ready;
  final String? missing;
  final VoidCallback? clearServerErrors;
  final void Function(Map<String, String> errors)? onValidation;

  @override
  State<EntityForm> createState() => _EntityFormState();
}

class _EntityFormState extends State<EntityForm> {
  final _formKey = GlobalKey<FormState>();
  var _saving = false;
  var _allowPop = false;

  Future<void> _submit() async {
    widget.clearServerErrors?.call();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await widget.onSubmit();
      if (!mounted || !saved) {
        return;
      }
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pop();
        }
      });
    } on ValidationException catch (error) {
      if (!mounted) {
        return;
      }
      widget.onValidation?.call(error.errors);
      _formKey.currentState!.validate();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<bool> _confirmLeave() => askToLeave(context);

  @override
  Widget build(BuildContext context) {
    final canPop = _allowPop || !widget.dirty;
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _allowPop) {
          return;
        }
        final leave = await _confirmLeave();
        if (!leave || !mounted) {
          return;
        }
        setState(() => _allowPop = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.pop();
          }
        });
      },
      child: LibraryScaffold(
        title: widget.title,
        confirmLeave: widget.dirty ? _confirmLeave : null,
        body: !widget.ready
            ? const Center(child: CircularProgressIndicator())
            : widget.missing != null
            ? Center(child: Text(widget.missing!))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () async {
                            if (!widget.dirty || await _confirmLeave()) {
                              if (context.mounted) {
                                setState(() => _allowPop = true);
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted) {
                                    context.pop();
                                  }
                                });
                              }
                            }
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Назад'),
                        ),
                      ),
                      Text(
                        widget.isEditing ? 'Редактирование' : 'Новая запись',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ...widget.fields,
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton(
                          onPressed: _saving ? null : _submit,
                          child: Text(
                            widget.isEditing ? 'Сохранить' : 'Создать',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// Текст ошибки сервера по первому совпавшему ключу поля.
String? firstServerError(Map<String, String> errors, List<String> keys) {
  for (final key in keys) {
    final message = errors[key];
    if (message != null && message.isNotEmpty) {
      return message;
    }
  }
  return null;
}

Widget formField({
  required TextEditingController controller,
  required String label,
  required String? Function(String?) validator,
  Key? fieldKey,
  TextInputType? keyboardType,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    ),
  );
}

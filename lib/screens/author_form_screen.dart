import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/author.dart';
import '../repositories/author_repository.dart';
import '../state/author_list_notifier.dart';
import '../validation/validators.dart';
import '../widgets/entity_form.dart';

class AuthorFormScreen extends StatefulWidget {
  const AuthorFormScreen({this.id, super.key});

  final int? id;

  bool get isEditing => id != null;

  @override
  State<AuthorFormScreen> createState() => _AuthorFormScreenState();
}

class _AuthorFormScreenState extends State<AuthorFormScreen> {
  final _fullName = TextEditingController();
  final _country = TextEditingController();
  final _birthYear = TextEditingController();

  var _ready = false;
  var _missing = false;
  var _dirty = false;
  var _hydrating = false;
  final _serverErrors = <String, String>{};
  DateTime? _deletedAt;

  @override
  void initState() {
    super.initState();
    for (final controller in [_fullName, _country, _birthYear]) {
      controller.addListener(_touch);
    }
    _load();
  }

  @override
  void dispose() {
    _fullName.dispose();
    _country.dispose();
    _birthYear.dispose();
    super.dispose();
  }

  void _touch() {
    if (_hydrating || _dirty) {
      return;
    }
    setState(() => _dirty = true);
  }

  Future<void> _load() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }
    Author? author;
    if (widget.id != null) {
      author = await context.read<AuthorRepository>().findById(widget.id!);
      if (!mounted) {
        return;
      }
    }
    _hydrating = true;
    if (author != null) {
      _fullName.text = author.fullName;
      _country.text = author.country;
      _birthYear.text = '${author.birthYear}';
      _deletedAt = author.deletedAt;
    }
    setState(() {
      _ready = true;
      _missing = widget.id != null && author == null;
    });
    _hydrating = false;
  }

  Future<bool> _save() async {
    final author = Author(
      id: widget.id ?? 0,
      fullName: _fullName.text.trim(),
      country: _country.text.trim(),
      birthYear: int.parse(_birthYear.text.trim()),
      deletedAt: _deletedAt,
    );
    final repository = context.read<AuthorRepository>();
    if (widget.isEditing) {
      await repository.update(author);
    } else {
      await repository.create(author);
    }
    if (!mounted) {
      return true;
    }
    await context.read<AuthorListNotifier>().load();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    return EntityForm(
      title: widget.isEditing ? 'Автор' : 'Новый автор',
      isEditing: widget.isEditing,
      ready: _ready,
      missing: _missing ? 'Автор не найден' : null,
      dirty: _dirty,
      onSubmit: _save,
      clearServerErrors: _serverErrors.clear,
      onValidation: (errors) {
        _serverErrors
          ..clear()
          ..addAll(errors);
      },
      fields: [
        formField(
          controller: _fullName,
          label: 'ФИО',
          validator: (value) =>
              firstServerError(_serverErrors, const ['fullName']) ??
              Validators.requiredText(
                value,
                emptyMessage: 'Укажите имя автора',
                max: 160,
              ),
        ),
        formField(
          controller: _country,
          label: 'Страна',
          validator: (value) =>
              firstServerError(_serverErrors, const ['country']) ??
              Validators.requiredText(
                value,
                emptyMessage: 'Укажите страну',
                max: 80,
              ),
        ),
        formField(
          controller: _birthYear,
          label: 'Год рождения',
          keyboardType: TextInputType.number,
          validator: (value) =>
              firstServerError(_serverErrors, const ['birthYear']) ??
              Validators.intInRange(
                value,
                label: 'год рождения',
                min: 1,
                max: year,
              ),
        ),
      ],
    );
  }
}

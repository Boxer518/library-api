import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/catalog_query.dart';
import '../models/json_values.dart';
import '../models/reader.dart';
import '../repositories/in_memory_reader_repository.dart';
import '../state/catalog_notifiers.dart';
import '../state/load_status.dart';
import '../validation/validators.dart';
import '../widgets/catalog_browser.dart';
import '../widgets/confirm.dart';
import '../widgets/entity_form.dart';
import '../widgets/entity_table.dart';
import '../widgets/record_view.dart';
import '../widgets/reload_when_shown.dart';

class ReaderListScreen extends StatelessWidget {
  const ReaderListScreen({
    required this.query,
    required this.simulateFailure,
    super.key,
  });

  final CatalogQuery query;
  final bool simulateFailure;

  @override
  Widget build(BuildContext context) {
    return CatalogBrowser<Reader>(
      title: 'Читатели',
      query: query,
      simulateFailure: simulateFailure,
      watch: (context) => context.watch<ReaderListNotifier>(),
      read: (context) => context.read<ReaderListNotifier>(),
      basePath: '/readers',
      searchLabel: 'Фамилия, почта или билет',
      defaultSort: 'lastName',
      tableKey: const Key('reader-table'),
      cardsKey: const Key('reader-cards'),
      idOf: (reader) => reader.id,
      isDeleted: (reader) => reader.isDeleted,
      columns: (context, open) => [
        TableColumnSpec(
          label: 'Фамилия',
          sortField: 'lastName',
          build: (reader) => TextButton(
            onPressed: () => open(reader.id),
            child: Text(
              reader.isDeleted
                  ? '${reader.lastName} (удалён)'
                  : reader.lastName,
            ),
          ),
        ),
        TableColumnSpec(
          label: 'Имя',
          build: (reader) => Text(reader.firstName),
        ),
        TableColumnSpec(
          label: 'Почта',
          sortField: 'email',
          build: (reader) => Text(reader.email),
        ),
        TableColumnSpec(
          label: 'Билет',
          sortField: 'card',
          build: (reader) => Text(reader.card.number),
        ),
      ],
      cardTitle: (context, reader, open) => TextButton(
        onPressed: open,
        child: Text(
          reader.isDeleted ? '${reader.fullName} (удалён)' : reader.fullName,
        ),
      ),
      cardSubtitle: (reader) => Text('${reader.email}\n${reader.card.number}'),
    );
  }
}

class ReaderDetailsScreen extends StatefulWidget {
  const ReaderDetailsScreen({required this.id, super.key});

  final int id;

  @override
  State<ReaderDetailsScreen> createState() => _ReaderDetailsScreenState();
}

class _ReaderDetailsScreenState extends State<ReaderDetailsScreen> {
  Reader? _reader;
  var _status = LoadStatus.loading;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_status != LoadStatus.loading) {
      setState(() {
        _status = LoadStatus.loading;
        _error = null;
      });
    }
    try {
      final reader = await context.read<ReaderRepository>().findById(widget.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _reader = reader;
        _status = LoadStatus.success;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Не удалось загрузить карточку: $error';
        _status = LoadStatus.error;
      });
    }
  }

  Future<void> _mutate(
    String message,
    Future<void> Function() action, {
    bool forever = false,
    bool reload = true,
  }) async {
    await runConfirmed(
      context,
      title: forever ? 'Физическое удаление' : 'Подтверждение',
      message: message,
      confirmLabel: forever ? 'Удалить навсегда' : 'Подтвердить',
      action: () async {
        await action();
        if (mounted) {
          await context.read<ReaderListNotifier>().load();
        }
        return 'Готово';
      },
    );
    if (reload && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reader = _reader;
    return ReloadWhenShown(
      onShow: _load,
      child: RecordView(
        title: reader?.fullName ?? 'Читатель',
        status: _status,
        error: _error,
        missing: reader == null,
        backPath: '/readers',
        lines: reader == null
            ? const []
            : [
                ('Фамилия', reader.lastName),
                ('Имя', reader.firstName),
                (
                  'Отчество',
                  reader.middleName.isEmpty ? '—' : reader.middleName,
                ),
                ('Почта', reader.email),
                ('Телефон', reader.phone),
                ('Номер билета', reader.card.number),
                ('Выдан', formatDate(reader.card.issuedAt)),
                ('Действует до', formatDate(reader.card.expiresAt)),
              ],
        deleted: reader?.isDeleted ?? false,
        onEdit: reader == null
            ? null
            : () => context.push('/readers/${reader.id}/edit'),
        onSoftDelete: reader == null || reader.isDeleted
            ? null
            : () => _mutate('Скрыть читателя?', () async {
                await context.read<ReaderRepository>().softDelete(reader.id);
              }),
        onRestore: reader != null && reader.isDeleted
            ? () => _mutate('Вернуть читателя в список?', () async {
                await context.read<ReaderRepository>().restore(reader.id);
              })
            : null,
        onHardDelete: reader == null
            ? null
            : () => _mutate(
                'Удалить читателя без восстановления?',
                () async {
                  await context.read<ReaderRepository>().hardDelete(reader.id);
                  if (context.mounted) {
                    context.go('/readers');
                  }
                },
                forever: true,
                reload: false,
              ),
      ),
    );
  }
}

class ReaderFormScreen extends StatefulWidget {
  const ReaderFormScreen({this.id, super.key});

  final int? id;

  bool get isEditing => id != null;

  @override
  State<ReaderFormScreen> createState() => _ReaderFormScreenState();
}

class _ReaderFormScreenState extends State<ReaderFormScreen> {
  final _lastName = TextEditingController();
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _cardNumber = TextEditingController();
  final _issuedAt = TextEditingController();
  final _expiresAt = TextEditingController();
  var _ready = false;
  var _missing = false;
  var _dirty = false;
  var _hydrating = false;
  DateTime? _deletedAt;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _lastName,
      _firstName,
      _middleName,
      _email,
      _phone,
      _cardNumber,
      _issuedAt,
      _expiresAt,
    ]) {
      controller.addListener(() {
        if (_hydrating || _dirty) {
          return;
        }
        setState(() => _dirty = true);
      });
    }
    _load();
  }

  @override
  void dispose() {
    _lastName.dispose();
    _firstName.dispose();
    _middleName.dispose();
    _email.dispose();
    _phone.dispose();
    _cardNumber.dispose();
    _issuedAt.dispose();
    _expiresAt.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }
    Reader? reader;
    if (widget.id != null) {
      reader = await context.read<ReaderRepository>().findById(widget.id!);
      if (!mounted) {
        return;
      }
    }
    _hydrating = true;
    if (reader != null) {
      _lastName.text = reader.lastName;
      _firstName.text = reader.firstName;
      _middleName.text = reader.middleName;
      _email.text = reader.email;
      _phone.text = reader.phone;
      _cardNumber.text = reader.card.number;
      _issuedAt.text = formatDate(reader.card.issuedAt);
      _expiresAt.text = formatDate(reader.card.expiresAt);
      _deletedAt = reader.deletedAt;
    }
    setState(() {
      _ready = true;
      _missing = widget.id != null && reader == null;
    });
    _hydrating = false;
  }

  String? _emailError(String? value) {
    final format = Validators.email(value);
    if (format != null) {
      return format;
    }
    final taken = context.read<ReaderRepository>().emailTaken(
      value!.trim(),
      exceptId: widget.id,
    );
    if (taken) {
      return 'Такой адрес уже есть';
    }
    return null;
  }

  String? _expiresError(String? value) {
    final format = Validators.date(value, label: 'Срок');
    if (format != null) {
      return format;
    }
    final issued = parseDate(_issuedAt.text);
    final expires = parseDate(value);
    if (issued != null && expires != null && expires.isBefore(issued)) {
      return 'Срок раньше даты выдачи';
    }
    return null;
  }

  Future<bool> _save() async {
    final reader = Reader(
      id: widget.id ?? 0,
      lastName: _lastName.text.trim(),
      firstName: _firstName.text.trim(),
      middleName: _middleName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      card: LibraryCard(
        number: _cardNumber.text.trim(),
        issuedAt: parseDate(_issuedAt.text)!,
        expiresAt: parseDate(_expiresAt.text)!,
      ),
      deletedAt: _deletedAt,
    );
    final repository = context.read<ReaderRepository>();
    if (widget.isEditing) {
      await repository.update(reader);
    } else {
      await repository.create(reader);
    }
    if (!mounted) {
      return true;
    }
    await context.read<ReaderListNotifier>().load();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return EntityForm(
      title: widget.isEditing ? 'Читатель' : 'Новый читатель',
      isEditing: widget.isEditing,
      ready: _ready,
      missing: _missing ? 'Читатель не найден' : null,
      dirty: _dirty,
      onSubmit: _save,
      fields: [
        formField(
          controller: _lastName,
          label: 'Фамилия',
          validator: (value) => Validators.requiredText(
            value,
            emptyMessage: 'Укажите фамилию',
            max: 80,
          ),
        ),
        formField(
          controller: _firstName,
          label: 'Имя',
          validator: (value) => Validators.requiredText(
            value,
            emptyMessage: 'Укажите имя',
            max: 80,
          ),
        ),
        formField(
          controller: _middleName,
          label: 'Отчество',
          validator: (value) => Validators.optionalText(value, max: 80),
        ),
        formField(controller: _email, label: 'Почта', validator: _emailError),
        formField(
          controller: _phone,
          label: 'Телефон',
          validator: Validators.phone,
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Читательский билет'),
        ),
        formField(
          controller: _cardNumber,
          label: 'Номер билета',
          validator: (value) => Validators.requiredText(
            value,
            emptyMessage: 'Укажите номер билета',
            max: 40,
          ),
        ),
        formField(
          controller: _issuedAt,
          label: 'Дата выдачи',
          validator: (value) => Validators.date(value, label: 'Дата выдачи'),
        ),
        formField(
          controller: _expiresAt,
          label: 'Действует до',
          validator: _expiresError,
        ),
      ],
    );
  }
}

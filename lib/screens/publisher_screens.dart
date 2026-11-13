import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../forms/publisher_guard.dart';
import '../models/catalog_query.dart';
import '../models/reference.dart';
import '../repositories/in_memory_publisher_repository.dart';
import '../state/catalog_notifiers.dart';
import '../state/load_status.dart';
import '../validation/validators.dart';
import '../widgets/catalog_browser.dart';
import '../widgets/confirm.dart';
import '../widgets/entity_form.dart';
import '../widgets/entity_table.dart';
import '../widgets/record_view.dart';
import '../widgets/reload_when_shown.dart';

class PublisherListScreen extends StatelessWidget {
  const PublisherListScreen({
    required this.query,
    required this.simulateFailure,
    super.key,
  });

  final CatalogQuery query;
  final bool simulateFailure;

  @override
  Widget build(BuildContext context) {
    return CatalogBrowser<Publisher>(
      title: 'Издательства',
      query: query,
      simulateFailure: simulateFailure,
      watch: (context) => context.watch<PublisherListNotifier>(),
      read: (context) => context.read<PublisherListNotifier>(),
      basePath: '/publishers',
      searchLabel: 'Название или город',
      defaultSort: 'name',
      tableKey: const Key('publisher-table'),
      cardsKey: const Key('publisher-cards'),
      idOf: (publisher) => publisher.id,
      isDeleted: (publisher) => publisher.isDeleted,
      deletionBlock: (ids) => publisherDeleteBlock(context, ids),
      columns: (context, open) => [
        TableColumnSpec(
          label: 'Название',
          sortField: 'name',
          build: (publisher) => TextButton(
            onPressed: () => open(publisher.id),
            child: Text(
              publisher.isDeleted
                  ? '${publisher.name} (удалено)'
                  : publisher.name,
            ),
          ),
        ),
        TableColumnSpec(
          label: 'Город',
          sortField: 'city',
          build: (publisher) => Text(publisher.city),
        ),
      ],
      cardTitle: (context, publisher, open) => TextButton(
        onPressed: open,
        child: Text(
          publisher.isDeleted ? '${publisher.name} (удалено)' : publisher.name,
        ),
      ),
      cardSubtitle: (publisher) => Text(publisher.city),
    );
  }
}

class PublisherDetailsScreen extends StatefulWidget {
  const PublisherDetailsScreen({required this.id, super.key});

  final int id;

  @override
  State<PublisherDetailsScreen> createState() => _PublisherDetailsScreenState();
}

class _PublisherDetailsScreenState extends State<PublisherDetailsScreen> {
  Publisher? _publisher;
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
      final publisher = await context.read<PublisherRepository>().findById(
        widget.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _publisher = publisher;
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

  Future<void> _remove(
    String message,
    Future<void> Function() action, {
    bool forever = false,
    bool reload = true,
  }) async {
    final blocked = await publisherDeleteBlock(context, [widget.id]);
    if (!mounted) {
      return;
    }
    if (blocked != null) {
      await showBlocked(context, blocked);
      return;
    }
    await runConfirmed(
      context,
      title: forever ? 'Физическое удаление' : 'Подтверждение',
      message: message,
      confirmLabel: forever ? 'Удалить навсегда' : 'Подтвердить',
      action: () async {
        await action();
        if (mounted) {
          await context.read<PublisherListNotifier>().load();
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
    final publisher = _publisher;
    return ReloadWhenShown(
      onShow: _load,
      child: RecordView(
        title: publisher?.name ?? 'Издательство',
        status: _status,
        error: _error,
        missing: publisher == null,
        backPath: '/publishers',
        lines: publisher == null
            ? const []
            : [('Название', publisher.name), ('Город', publisher.city)],
        deleted: publisher?.isDeleted ?? false,
        onEdit: publisher == null
            ? null
            : () => context.push('/publishers/${publisher.id}/edit'),
        onSoftDelete: publisher == null || publisher.isDeleted
            ? null
            : () => _remove('Скрыть издательство?', () async {
                await context.read<PublisherRepository>().softDelete(
                  publisher.id,
                );
              }),
        onRestore: publisher != null && publisher.isDeleted
            ? () => _restore(publisher)
            : null,
        onHardDelete: publisher == null
            ? null
            : () => _remove(
                'Удалить издательство без восстановления?',
                () async {
                  await context.read<PublisherRepository>().hardDelete(
                    publisher.id,
                  );
                  if (context.mounted) {
                    context.go('/publishers');
                  }
                },
                forever: true,
                reload: false,
              ),
      ),
    );
  }

  Future<void> _restore(Publisher publisher) {
    return runConfirmed(
      context,
      title: 'Восстановление',
      message: 'Вернуть издательство в список?',
      confirmLabel: 'Восстановить',
      action: () async {
        await context.read<PublisherRepository>().restore(publisher.id);
        if (mounted) {
          await context.read<PublisherListNotifier>().load();
          await _load();
        }
        return 'Готово';
      },
    );
  }
}

class PublisherFormScreen extends StatefulWidget {
  const PublisherFormScreen({this.id, super.key});

  final int? id;

  bool get isEditing => id != null;

  @override
  State<PublisherFormScreen> createState() => _PublisherFormScreenState();
}

class _PublisherFormScreenState extends State<PublisherFormScreen> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  var _ready = false;
  var _missing = false;
  var _dirty = false;
  var _hydrating = false;
  DateTime? _deletedAt;

  @override
  void initState() {
    super.initState();
    for (final controller in [_name, _city]) {
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
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }
    Publisher? publisher;
    if (widget.id != null) {
      publisher = await context.read<PublisherRepository>().findById(
        widget.id!,
      );
      if (!mounted) {
        return;
      }
    }
    _hydrating = true;
    if (publisher != null) {
      _name.text = publisher.name;
      _city.text = publisher.city;
      _deletedAt = publisher.deletedAt;
    }
    setState(() {
      _ready = true;
      _missing = widget.id != null && publisher == null;
    });
    _hydrating = false;
  }

  Future<bool> _save() async {
    final publisher = Publisher(
      id: widget.id ?? 0,
      name: _name.text.trim(),
      city: _city.text.trim(),
      deletedAt: _deletedAt,
    );
    final repository = context.read<PublisherRepository>();
    if (widget.isEditing) {
      await repository.update(publisher);
    } else {
      await repository.create(publisher);
    }
    if (!mounted) {
      return true;
    }
    await context.read<PublisherListNotifier>().load();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return EntityForm(
      title: widget.isEditing ? 'Издательство' : 'Новое издательство',
      isEditing: widget.isEditing,
      ready: _ready,
      missing: _missing ? 'Издательство не найдено' : null,
      dirty: _dirty,
      onSubmit: _save,
      fields: [
        formField(
          controller: _name,
          label: 'Название',
          validator: (value) => Validators.requiredText(
            value,
            emptyMessage: 'Укажите название',
            max: 120,
          ),
        ),
        formField(
          controller: _city,
          label: 'Город',
          validator: (value) => Validators.requiredText(
            value,
            emptyMessage: 'Укажите город',
            max: 80,
          ),
        ),
      ],
    );
  }
}

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/catalog_query.dart';
import '../models/reference.dart';
import '../repositories/in_memory_genre_repository.dart';
import '../state/catalog_notifiers.dart';
import '../state/load_status.dart';
import '../validation/validators.dart';
import '../widgets/catalog_browser.dart';
import '../widgets/confirm.dart';
import '../widgets/entity_form.dart';
import '../widgets/entity_table.dart';
import '../widgets/record_view.dart';
import '../widgets/reload_when_shown.dart';

class GenreListScreen extends StatelessWidget {
  const GenreListScreen({
    required this.query,
    required this.simulateFailure,
    super.key,
  });

  final CatalogQuery query;
  final bool simulateFailure;

  @override
  Widget build(BuildContext context) {
    return CatalogBrowser<Genre>(
      title: 'Жанры',
      query: query,
      simulateFailure: simulateFailure,
      watch: (context) => context.watch<GenreListNotifier>(),
      read: (context) => context.read<GenreListNotifier>(),
      basePath: '/genres',
      searchLabel: 'Название',
      defaultSort: 'name',
      tableKey: const Key('genre-table'),
      cardsKey: const Key('genre-cards'),
      idOf: (genre) => genre.id,
      isDeleted: (genre) => genre.isDeleted,
      columns: (context, open) => [
        TableColumnSpec(
          label: 'Название',
          sortField: 'name',
          build: (genre) => TextButton(
            onPressed: () => open(genre.id),
            child: Text(
              genre.isDeleted ? '${genre.name} (удалён)' : genre.name,
            ),
          ),
        ),
      ],
      cardTitle: (context, genre, open) => TextButton(
        onPressed: open,
        child: Text(genre.isDeleted ? '${genre.name} (удалён)' : genre.name),
      ),
      cardSubtitle: (genre) => const Text('Жанр каталога'),
    );
  }
}

class GenreDetailsScreen extends StatefulWidget {
  const GenreDetailsScreen({required this.id, super.key});

  final int id;

  @override
  State<GenreDetailsScreen> createState() => _GenreDetailsScreenState();
}

class _GenreDetailsScreenState extends State<GenreDetailsScreen> {
  Genre? _genre;
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
      final genre = await context.read<GenreRepository>().findById(widget.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _genre = genre;
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

  @override
  Widget build(BuildContext context) {
    final genre = _genre;
    return ReloadWhenShown(
      onShow: _load,
      child: RecordView(
        title: genre?.name ?? 'Жанр',
        status: _status,
        error: _error,
        missing: genre == null,
        backPath: '/genres',
        lines: genre == null
            ? const []
            : [
                ('Название', genre.name),
                (
                  'Описание',
                  genre.description.isEmpty ? '—' : genre.description,
                ),
              ],
        deleted: genre?.isDeleted ?? false,
        onEdit: genre == null
            ? null
            : () => context.push('/genres/${genre.id}/edit'),
        onSoftDelete: genre == null || genre.isDeleted
            ? null
            : () => _mutate('Скрыть жанр?', () async {
                await context.read<GenreRepository>().softDelete(genre.id);
              }),
        onRestore: genre != null && genre.isDeleted
            ? () => _mutate('Вернуть жанр в список?', () async {
                await context.read<GenreRepository>().restore(genre.id);
              })
            : null,
        onHardDelete: genre == null
            ? null
            : () => _mutate(
                'Удалить жанр без восстановления?',
                () async {
                  await context.read<GenreRepository>().hardDelete(genre.id);
                  if (context.mounted) {
                    context.go('/genres');
                  }
                },
                forever: true,
                reload: false,
              ),
      ),
    );
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
          await context.read<GenreListNotifier>().load();
        }
        return 'Готово';
      },
    );
    if (reload && mounted) {
      await _load();
    }
  }
}

class GenreFormScreen extends StatefulWidget {
  const GenreFormScreen({this.id, super.key});

  final int? id;

  bool get isEditing => id != null;

  @override
  State<GenreFormScreen> createState() => _GenreFormScreenState();
}

class _GenreFormScreenState extends State<GenreFormScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  var _ready = false;
  var _missing = false;
  var _dirty = false;
  var _hydrating = false;
  final _serverErrors = <String, String>{};
  DateTime? _deletedAt;

  @override
  void initState() {
    super.initState();
    for (final controller in [_name, _description]) {
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
    _description.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }
    Genre? genre;
    if (widget.id != null) {
      genre = await context.read<GenreRepository>().findById(widget.id!);
      if (!mounted) {
        return;
      }
    }
    _hydrating = true;
    if (genre != null) {
      _name.text = genre.name;
      _description.text = genre.description;
      _deletedAt = genre.deletedAt;
    }
    setState(() {
      _ready = true;
      _missing = widget.id != null && genre == null;
    });
    _hydrating = false;
  }

  Future<bool> _save() async {
    final genre = Genre(
      id: widget.id ?? 0,
      name: _name.text.trim(),
      description: _description.text.trim(),
      deletedAt: _deletedAt,
    );
    final repository = context.read<GenreRepository>();
    if (widget.isEditing) {
      await repository.update(genre);
    } else {
      await repository.create(genre);
    }
    if (!mounted) {
      return true;
    }
    await context.read<GenreListNotifier>().load();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return EntityForm(
      title: widget.isEditing ? 'Жанр' : 'Новый жанр',
      isEditing: widget.isEditing,
      ready: _ready,
      missing: _missing ? 'Жанр не найден' : null,
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
          controller: _name,
          label: 'Название',
          validator: (value) =>
              firstServerError(_serverErrors, const ['name']) ??
              Validators.requiredText(
                value,
                emptyMessage: 'Укажите название',
                max: 80,
              ),
        ),
        formField(
          controller: _description,
          label: 'Описание',
          validator: (value) =>
              firstServerError(_serverErrors, const ['description']) ??
              Validators.optionalText(value, max: 300),
        ),
      ],
    );
  }
}

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../forms/cascades.dart';
import '../models/author.dart';
import '../models/book.dart';
import '../models/reference.dart';
import '../repositories/author_repository.dart';
import '../repositories/book_repository.dart';
import '../repositories/in_memory_genre_repository.dart';
import '../repositories/in_memory_publisher_repository.dart';
import '../state/book_list_notifier.dart';
import '../validation/validators.dart';
import '../widgets/entity_form.dart';
import '../widgets/id_chip_field.dart';

class BookFormScreen extends StatefulWidget {
  const BookFormScreen({this.id, super.key});

  final int? id;

  bool get isEditing => id != null;

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _title = TextEditingController();
  final _isbn = TextEditingController();
  final _year = TextEditingController();
  final _pages = TextEditingController();
  final _copiesTotal = TextEditingController();

  var _ready = false;
  var _missing = false;
  var _dirty = false;
  var _hydrating = false;
  final _serverErrors = <String, String>{};
  int? _publisherId;
  String? _city;
  DateTime? _deletedAt;
  List<int> _authorIds = [];
  List<int> _genreIds = [];
  List<Author> _authors = const [];
  List<Genre> _genres = const [];
  int? _loadedAvailable;
  List<Publisher> _publishers = const [];

  @override
  void initState() {
    super.initState();
    for (final controller in [_title, _isbn, _year, _pages, _copiesTotal]) {
      controller.addListener(_touch);
    }
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _isbn.dispose();
    _year.dispose();
    _pages.dispose();
    _copiesTotal.dispose();
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
    final authors = context.read<AuthorRepository>().listAll(
      includeDeleted: true,
    );
    final genres = context.read<GenreRepository>().listAll(
      includeDeleted: true,
    );
    final publishers = context.read<PublisherRepository>().listAll(
      includeDeleted: true,
    );
    Book? book;
    if (widget.id != null) {
      book = await context.read<BookRepository>().findById(widget.id!);
      if (!mounted) {
        return;
      }
    }
    _hydrating = true;
    if (book != null) {
      _title.text = book.title;
      _isbn.text = book.isbn;
      _year.text = '${book.year}';
      _pages.text = '${book.pages}';
      _copiesTotal.text = '${book.copiesTotal}';
      _loadedAvailable = book.copiesAvailable;
      _publisherId = book.publisherId;
      _authorIds = List<int>.of(book.authorIds);
      _genreIds = List<int>.of(book.genreIds);
      _deletedAt = book.deletedAt;
      for (final publisher in publishers) {
        if (publisher.id == book.publisherId) {
          _city = publisher.city;
        }
      }
    }
    setState(() {
      _authors = authors;
      _genres = genres;
      _publishers = publishers;
      _ready = true;
      _missing = widget.id != null && book == null;
    });
    _hydrating = false;
  }

  List<String> get _cities {
    final cities = <String>{
      for (final publisher in _publishers) publisher.city,
    };
    final sorted = cities.toList()..sort();
    return sorted;
  }

  Publisher? get _selectedPublisher {
    for (final publisher in _publishers) {
      if (publisher.id == _publisherId) {
        return publisher;
      }
    }
    return null;
  }

  List<Publisher> get _visiblePublishers {
    final active = _publishers.where((publisher) {
      return !publisher.isDeleted || publisher.id == _publisherId;
    }).toList();
    return narrowPublishers(publishers: active, city: _city);
  }

  Future<bool> _save() async {
    final total = int.parse(_copiesTotal.text.trim());
    final available = (_loadedAvailable ?? total).clamp(0, total);
    final book = Book(
      id: widget.id ?? 0,
      title: _title.text.trim(),
      isbn: _isbn.text.trim(),
      year: int.parse(_year.text.trim()),
      pages: int.parse(_pages.text.trim()),
      publisherId: _publisherId!,
      authorIds: List<int>.of(_authorIds),
      genreIds: List<int>.of(_genreIds),
      copiesTotal: total,
      copiesAvailable: available,
      deletedAt: _deletedAt,
    );
    final repository = context.read<BookRepository>();
    if (widget.isEditing) {
      await repository.update(book);
    } else {
      await repository.create(book);
    }
    if (!mounted) {
      return true;
    }
    await context.read<BookListNotifier>().load();
    return true;
  }

  String? _isbnError(String? value) {
    final server = firstServerError(_serverErrors, const ['isbn']);
    if (server != null) {
      return server;
    }
    final format = Validators.isbn(value);
    if (format != null) {
      return format;
    }
    final taken = context.read<BookRepository>().isbnTaken(
      value!.trim(),
      exceptId: widget.id,
    );
    if (taken) {
      return 'Такой ISBN уже есть';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cities = narrowCities(
      cities: _cities,
      selectedPublisherCity: _selectedPublisher?.city,
    );
    final publishers = _visiblePublishers;
    return EntityForm(
      title: widget.isEditing ? 'Книга' : 'Новая книга',
      isEditing: widget.isEditing,
      ready: _ready,
      missing: _missing ? 'Книга не найдена' : null,
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
          fieldKey: const Key('book-title'),
          controller: _title,
          label: 'Название',
          validator: (value) =>
              firstServerError(_serverErrors, const ['title']) ??
              Validators.requiredText(
                value,
                emptyMessage: 'Укажите название',
                max: 200,
              ),
        ),
        formField(
          fieldKey: const Key('book-isbn'),
          controller: _isbn,
          label: 'ISBN',
          validator: _isbnError,
        ),
        formField(
          fieldKey: const Key('book-year'),
          controller: _year,
          label: 'Год издания',
          keyboardType: TextInputType.number,
          validator: (value) =>
              firstServerError(_serverErrors, const ['year']) ??
              Validators.intInRange(value, label: 'год', min: 1450, max: 2100),
        ),
        formField(
          fieldKey: const Key('book-pages'),
          controller: _pages,
          label: 'Страниц',
          keyboardType: TextInputType.number,
          validator: (value) =>
              firstServerError(_serverErrors, const ['pages']) ??
              Validators.intInRange(
                value,
                label: 'страницы',
                min: 1,
                max: 20000,
              ),
        ),
        DropdownButtonFormField<String>(
          key: ValueKey('city-$_city'),
          initialValue: cities.contains(_city) ? _city : null,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Город издательства',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final city in cities)
              DropdownMenuItem(value: city, child: Text(city)),
          ],
          onChanged: (city) {
            setState(() {
              _city = city;
              final allowed = narrowPublishers(
                publishers: _publishers,
                city: city,
              );
              if (_publisherId != null &&
                  !allowed.any((item) => item.id == _publisherId)) {
                _publisherId = null;
              }
              _dirty = true;
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          key: ValueKey('publisher-$_city-$_publisherId'),
          initialValue: publishers.any((item) => item.id == _publisherId)
              ? _publisherId
              : null,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Издательство',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final publisher in publishers)
              DropdownMenuItem(
                value: publisher.id,
                child: Text('${publisher.name}, ${publisher.city}'),
              ),
          ],
          validator: (value) {
            _publisherId = value;
            return firstServerError(_serverErrors, const ['publisherId']) ??
                Validators.requiredId(value, 'Выберите издательство');
          },
          onChanged: (id) {
            Publisher? selected;
            for (final publisher in _publishers) {
              if (publisher.id == id) {
                selected = publisher;
              }
            }
            setState(() {
              _publisherId = id;
              if (selected != null) {
                _city = selected.city;
              }
              _dirty = true;
            });
          },
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () {
              setState(() {
                _city = null;
                _publisherId = null;
                _dirty = true;
              });
            },
            child: const Text('Сбросить связь'),
          ),
        ),
        IdChipField(
          label: 'Авторы',
          options: [
            for (final author in _authors)
              if (!author.isDeleted || _authorIds.contains(author.id))
                (author.id, author.fullName),
          ],
          value: _authorIds,
          emptyMessage: 'Выберите хотя бы одного автора',
          serverError: () =>
              firstServerError(_serverErrors, const ['authorIds']),
          onChanged: (ids) => setState(() {
            _authorIds = ids;
            _dirty = true;
          }),
        ),
        const SizedBox(height: 12),
        IdChipField(
          label: 'Жанры',
          options: [
            for (final genre in _genres)
              if (!genre.isDeleted || _genreIds.contains(genre.id))
                (genre.id, genre.name),
          ],
          value: _genreIds,
          emptyMessage: 'Выберите хотя бы один жанр',
          serverError: () =>
              firstServerError(_serverErrors, const ['genreIds']),
          onChanged: (ids) => setState(() {
            _genreIds = ids;
            _dirty = true;
          }),
        ),
        const SizedBox(height: 12),
        formField(
          fieldKey: const Key('book-copies-total'),
          controller: _copiesTotal,
          label: 'Экземпляров всего',
          keyboardType: TextInputType.number,
          validator: (value) =>
              firstServerError(_serverErrors, const ['copiesTotal']) ??
              Validators.intInRange(
                value,
                label: 'экземпляры',
                min: 0,
                max: 10000,
              ),
        ),
      ],
    );
  }
}

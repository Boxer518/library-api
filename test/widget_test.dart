import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/main.dart';
import 'package:library_web/router.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    appRouter.go('/');
  });

  Future<void> openBooks(WidgetTester tester) async {
    await tester.pumpWidget(const LibraryApp());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Книги'));
    await tester.pumpAndSettle();
  }

  testWidgets('поиск ждёт паузу и попадает в адрес', (tester) async {
    await openBooks(tester);
    expect(find.byKey(const Key('book-table')), findsOneWidget);
    expect(find.textContaining('Записей: 22'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('book-search')), 'война');
    await tester.pump(const Duration(milliseconds: 200));
    expect(appRouter.state.uri.queryParameters.containsKey('search'), isFalse);

    await tester.pump(const Duration(milliseconds: 200));
    expect(appRouter.state.uri.queryParameters['search'], 'война');
    await tester.pumpAndSettle();

    expect(find.text('Война и мир'), findsOneWidget);
    expect(find.text('Война миров'), findsOneWidget);
    expect(find.text('1984'), findsNothing);
  });

  testWidgets('фильтр жанра и пустой результат отличаются от ошибки', (
    tester,
  ) async {
    await openBooks(tester);

    appRouter.go('/books?search=война&genreId=2&sort=year,desc');
    await tester.pumpAndSettle();
    expect(appRouter.state.uri.queryParameters['genreId'], '2');
    expect(appRouter.state.uri.queryParameters['sort'], 'year,desc');
    expect(find.text('Война миров'), findsOneWidget);
    expect(find.text('Война и мир'), findsNothing);

    appRouter.go('/books?search=нет-такой-книги');
    await tester.pumpAndSettle();
    expect(find.text('Ничего не найдено'), findsOneWidget);
    expect(find.text('Повторить'), findsNothing);

    appRouter.go('/books?fail=1');
    await tester.pumpAndSettle();
    expect(find.text('Не удалось загрузить данные'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.text('Ничего не найдено'), findsNothing);
  });

  testWidgets('узкое окно показывает карточки, а не таблицу', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openBooks(tester);
    expect(find.byKey(const Key('book-cards')), findsOneWidget);
    expect(find.byKey(const Key('book-table')), findsNothing);
    expect(find.text('1984'), findsOneWidget);
  });

  testWidgets('карточка открывается по адресу и неизвестный id — ошибка', (
    tester,
  ) async {
    await tester.pumpWidget(const LibraryApp());
    appRouter.go('/books/1');
    await tester.pumpAndSettle();
    expect(find.text('Война и мир'), findsWidgets);
    expect(find.text('978-5-17-100001-1'), findsOneWidget);

    appRouter.go('/books/999');
    await tester.pumpAndSettle();
    expect(find.text('Книга не найдена'), findsOneWidget);

    appRouter.go('/qwerty');
    await tester.pumpAndSettle();
    expect(find.text('На главную'), findsOneWidget);
  });

  testWidgets('набор не стирается, пока список ещё грузится', (tester) async {
    await openBooks(tester);
    await tester.enterText(find.byKey(const Key('book-search')), 'вой');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byKey(const Key('book-search')), 'война');
    await tester.pump(const Duration(milliseconds: 250));

    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('book-search')),
        matching: find.byType(TextField),
      ),
    );
    expect(field.controller?.text, 'война');
    await tester.pumpAndSettle();
  });

  testWidgets('неизвестный жанр в адресе не роняет список', (tester) async {
    await tester.pumpWidget(const LibraryApp());
    appRouter.go('/books?genreId=99');
    await tester.pumpAndSettle();
    expect(find.text('#99'), findsOneWidget);
    expect(find.text('Ничего не найдено'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('уход с карточки во время загрузки не падает', (tester) async {
    await tester.pumpWidget(const LibraryApp());
    appRouter.go('/books/1');
    await tester.pump();
    appRouter.go('/books');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Записей: 22'), findsOneWidget);
  });

  testWidgets('узкая карточка автора показывает имя', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LibraryApp());
    appRouter.go('/authors?search=стругац');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('author-cards')), findsOneWidget);
    expect(find.textContaining('Аркадий'), findsOneWidget);
    expect(find.textContaining('Борис'), findsOneWidget);
  });

  testWidgets('страница авторов ищет по стране', (tester) async {
    await tester.pumpWidget(const LibraryApp());
    appRouter.go('/authors?search=сша');
    await tester.pumpAndSettle();
    expect(find.text('Брэдбери'), findsOneWidget);
    expect(find.text('Толстой'), findsNothing);
    expect(find.text('Кристи'), findsNothing);
  });

  testWidgets('пустая форма книги показывает ошибки у полей', (tester) async {
    await tester.pumpWidget(const LibraryApp());
    appRouter.go('/books/new');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final submit = find.widgetWithText(FilledButton, 'Создать');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(find.text('Укажите название'), findsOneWidget);
    expect(find.text('Укажите ISBN'), findsOneWidget);
    expect(find.text('Выберите издательство'), findsOneWidget);
    expect(find.text('Выберите хотя бы одного автора'), findsOneWidget);
    expect(find.text('Выберите хотя бы один жанр'), findsOneWidget);
  });

  testWidgets('повтор ISBN пишет ошибку под полем', (tester) async {
    await tester.pumpWidget(const LibraryApp());
    appRouter.go('/books/new');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('book-title')), 'Новая книга');
    await tester.enterText(
      find.byKey(const Key('book-isbn')),
      '978-5-17-100001-1',
    );
    await tester.enterText(find.byKey(const Key('book-year')), '2000');
    await tester.enterText(find.byKey(const Key('book-pages')), '320');
    await tester.enterText(find.byKey(const Key('book-copies-total')), '4');
    await tester.enterText(find.byKey(const Key('book-copies-available')), '2');

    await tester.ensureVisible(
      find.byKey(const ValueKey('publisher-null-null')),
    );
    await tester.tap(find.byKey(const ValueKey('publisher-null-null')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('АСТ, Москва').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.widgetWithText(FilterChip, 'Толстой Лев Николаевич'),
    );
    await tester.tap(find.widgetWithText(FilterChip, 'Толстой Лев Николаевич'));
    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Роман'));
    await tester.tap(find.widgetWithText(FilterChip, 'Роман'));
    await tester.pump();

    final submit = find.widgetWithText(FilledButton, 'Создать');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(find.text('Такой ISBN уже есть'), findsOneWidget);
  });
}

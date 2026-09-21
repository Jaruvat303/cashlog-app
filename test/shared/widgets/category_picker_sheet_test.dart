// Ticket 03 (cashlog-fixes-redesign): the category-assign bottom sheet stays
// half-screen height regardless of category count, and a category list too
// tall to fit is reachable via a visible scrollbar instead of resizing the
// sheet or silently clipping. Same fake-repository pattern as
// category_quick_assign_sheet_test.dart — the real repository/dio call is
// never exercised.
import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/categories/data/categories_repository.dart';
import 'package:cashlog/features/categories/domain/category.dart';
import 'package:cashlog/shared/widgets/category_picker_sheet.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCategoriesRepository implements CategoriesRepository {
  _FakeCategoriesRepository(this.categories);
  final List<Category> categories;

  @override
  Stream<List<Category>> watchAll() => Stream.value(categories);
  @override
  Future<Either<Failure, void>> refreshFromApi() async => const Right(null);
  @override
  Future<Either<Failure, Category>> create({
    required String name,
    required CategoryType type,
    required String iconKey,
    required String colorHex,
  }) => throw UnimplementedError('not exercised by this test');
  @override
  Future<Either<Failure, Category>> update(
    int id, {
    required String name,
    required CategoryType type,
    required String iconKey,
    required String colorHex,
  }) => throw UnimplementedError('not exercised by this test');
  @override
  Future<int> countLinkedTransactions(int categoryId) => throw UnimplementedError('not exercised by this test');
  @override
  Future<Either<Failure, void>> delete(int id) => throw UnimplementedError('not exercised by this test');
}

List<Category> _expenseCategories(int count) => List.generate(
  count,
  (i) => Category(id: i + 1, name: 'Category $i', type: CategoryType.expense, iconKey: 'restaurant-fill', colorHex: '#FF6B6B'),
);

CategoryPickerResult? _lastResult;

Widget _buildApp(List<Category> categories) => ProviderScope(
  overrides: [categoriesRepositoryProvider.overrideWithValue(_FakeCategoriesRepository(categories))],
  child: MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            _lastResult = await showCategoryGridPicker(context, categoryType: CategoryType.expense, currentCategoryId: null, subtitle: 'test');
          },
          child: const Text('open'),
        ),
      ),
    ),
  ),
);

/// `flutter_test`'s default 800x600 surface is unrealistically wide for a
/// phone-only app (CLAUDE.md: Android only, real devices) and doesn't
/// reproduce the ticket 11 overflow at all — a realistic phone width is
/// what actually squeezes `CategoryGridTile`'s grid cells down to where a
/// 2-line label used to overflow.
void _usePhoneSizedViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// pumpAndSettle can't tell "still legitimately loading" from "stuck
/// forever" — a bounded pump loop fails fast instead (same reasoning as
/// transaction_list_tile_test.dart's `_pumpBounded`).
Future<void> _pumpBounded(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Finds the sheet's fixed-height root `SizedBox` — distinguished from the
/// several small fixed-size `SizedBox`es used as spacers inside the sheet
/// (heights of 4/6/14) by requiring a height clearly in "sheet" territory.
Finder _sheetSizedBox() => find.byWidgetPredicate((w) => w is SizedBox && (w.height ?? 0) > 100);

void main() {
  setUp(() {
    _lastResult = null;
  });

  testWidgets('sheet height is the same half-screen size for a short category list as for a long one', (tester) async {
    final expectedHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio * 0.5;

    await tester.pumpWidget(_buildApp(_expenseCategories(2)));
    await tester.tap(find.text('open'));
    await _pumpBounded(tester);
    expect(tester.getSize(_sheetSizedBox()).height, expectedHeight);
    await tester.tap(find.byKey(const Key('categoryPickerCloseButton')));
    await _pumpBounded(tester);

    await tester.pumpWidget(_buildApp(_expenseCategories(40)));
    await tester.tap(find.text('open'));
    await _pumpBounded(tester);
    expect(tester.getSize(_sheetSizedBox()).height, expectedHeight);
  });

  testWidgets('a category list too tall to fit shows a visible scrollbar and is reachable by scrolling', (tester) async {
    final categories = _expenseCategories(40);
    await tester.pumpWidget(_buildApp(categories));
    await tester.tap(find.text('open'));
    await _pumpBounded(tester);

    final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
    expect(scrollbar.thumbVisibility, isTrue);

    final lastOptionKey = Key('categoryOption_${categories.last.id}');
    expect(find.byKey(lastOptionKey), findsNothing);

    await tester.scrollUntilVisible(find.byKey(lastOptionKey), 300, scrollable: find.byType(Scrollable));
    await _pumpBounded(tester);
    expect(find.byKey(lastOptionKey), findsOneWidget);

    await tester.tap(find.byKey(lastOptionKey));
    await _pumpBounded(tester);

    expect(_lastResult?.categoryId, categories.last.id);
  });

  testWidgets('a category list that fits within half-screen needs no scrolling and selecting still closes the sheet', (tester) async {
    await tester.pumpWidget(_buildApp(_expenseCategories(2)));
    await tester.tap(find.text('open'));
    await _pumpBounded(tester);

    await tester.tap(find.byKey(const Key('categoryOption_1')));
    await _pumpBounded(tester);

    expect(_lastResult?.categoryId, 1);
    expect(find.byKey(const Key('categoryOption_1')), findsNothing);
  });

  group('ticket 11: CategoryGridTile overflow regression', () {
    testWidgets('a long, 2-line category name does not overflow its grid tile at phone width', (tester) async {
      _usePhoneSizedViewport(tester);
      final categories = [
        // Real category names confirmed to reproduce the exact "overflowed
        // by 7.6 pixels" QA reported, before this ticket's fix.
        Category(id: 1, name: 'ที่อยู่อาศัย (ค่าเช่า/ผ่อนบ้าน)', type: CategoryType.expense, iconKey: 'home-4-fill', colorHex: '#FF6B6B'),
        Category(id: 2, name: 'เบี้ยประกัน (ชีวิต/สุขภาพ/รถ)', type: CategoryType.expense, iconKey: 'shield-check-fill', colorHex: '#FF6B6B'),
      ];

      await tester.pumpWidget(_buildApp(categories));
      await tester.tap(find.text('open'));
      await _pumpBounded(tester);

      // A RenderFlex overflow throws during layout/paint, surfaced here as
      // an exception `tester.takeException()` would otherwise swallow
      // silently if unchecked — this is the actual regression guard, not
      // just "the widget rendered something". This also incidentally
      // guards the unrelated footer-hint-text overflow found and fixed
      // alongside this ticket (see `category_picker_sheet.dart`'s footer
      // `Row` comment) — that row renders on every sheet open regardless of
      // category content, so the same exception check covers it too.
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('categoryOption_1')), findsOneWidget);
      expect(find.byKey(const Key('categoryOption_2')), findsOneWidget);
      expect(find.textContaining('แตะไอคอนเดียว'), findsOneWidget);
    });
  });
}

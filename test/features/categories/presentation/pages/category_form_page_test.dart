// Ticket 02 (post-launch-ux-redesign): the create/edit category icon picker
// must offer only income icons for an income category and only expense
// icons for an expense category, never a single mixed list. Same fake-
// repository pattern as category_picker_sheet_test.dart — the real
// repository/dio call is never exercised since these tests never submit.
import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/categories/data/categories_repository.dart';
import 'package:cashlog/features/categories/domain/category.dart';
import 'package:cashlog/features/categories/presentation/pages/category_form_page.dart';
import 'package:cashlog/shared/widgets/category_icon.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _CreateArgs = ({
  String name,
  CategoryType type,
  String iconKey,
  String colorHex,
});
typedef _UpdateArgs = ({
  int id,
  String name,
  CategoryType type,
  String iconKey,
  String colorHex,
});

class _FakeCategoriesRepository implements CategoriesRepository {
  int createCallCount = 0;
  int updateCallCount = 0;
  int deleteCallCount = 0;
  int linkedTransactionCount = 0;
  Either<Failure, Category>? nextResult;
  Either<Failure, void>? nextDeleteResult;
  _CreateArgs? lastCreateArgs;
  _UpdateArgs? lastUpdateArgs;

  @override
  Stream<List<Category>> watchAll() => Stream.value(const []);
  @override
  Future<Either<Failure, void>> refreshFromApi() async => const Right(null);
  @override
  Future<Either<Failure, Category>> create({
    required String name,
    required CategoryType type,
    required String iconKey,
    required String colorHex,
  }) async {
    createCallCount++;
    lastCreateArgs = (
      name: name,
      type: type,
      iconKey: iconKey,
      colorHex: colorHex,
    );
    return nextResult ??
        Right(
          Category(
            id: 1,
            name: name,
            type: type,
            iconKey: iconKey,
            colorHex: colorHex,
          ),
        );
  }

  @override
  Future<Either<Failure, Category>> update(
    int id, {
    required String name,
    required CategoryType type,
    required String iconKey,
    required String colorHex,
  }) async {
    updateCallCount++;
    lastUpdateArgs = (
      id: id,
      name: name,
      type: type,
      iconKey: iconKey,
      colorHex: colorHex,
    );
    return nextResult ??
        Right(
          Category(
            id: id,
            name: name,
            type: type,
            iconKey: iconKey,
            colorHex: colorHex,
          ),
        );
  }

  @override
  Future<int> countLinkedTransactions(int categoryId) async =>
      linkedTransactionCount;
  @override
  Future<Either<Failure, void>> delete(int id) async {
    deleteCallCount++;
    return nextDeleteResult ?? const Right(null);
  }
}

/// pumpAndSettle can't tell "still legitimately loading" from "stuck
/// forever" — a bounded pump loop fails fast instead (same reasoning as
/// test/widget_test.dart's `_pumpBounded`).
Future<void> _pumpBounded(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// The icon grid + color swatches push the submit/delete buttons below the
/// test viewport, so they're not built until scrolled into view — the
/// sliver list only builds visible (+cache-extent) children, same reasoning
/// as the analogous helper in transaction_form_page_test.dart.
/// `scrollUntilVisible` alone stops as soon as any sliver of the target is
/// on screen, which can still leave its center outside the viewport (and so
/// un-tappable) — `ensureVisible` afterward settles it fully into view.
Future<void> _scrollToFinder(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pump();
}

/// `flutter_test`'s default 800x600 surface is unrealistically small/wide
/// for a phone-only app (CLAUDE.md: Android only, real devices) — on this
/// form specifically, it's short enough that scrolling far down to reach
/// the submit button can carry nameField clean out of the `ListView`'s
/// cache extent, unmounting its `TextFormField` and — since a disposed
/// `FormFieldState` deregisters from its ancestor `Form` — making
/// `_formKey.currentState!.validate()` silently skip it entirely. A
/// realistic phone-height viewport is enough for the whole form (or at
/// least name + submit) to coexist without that, matching what an actual
/// device would do.
void _usePhoneSizedViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  late _FakeCategoriesRepository fakeCategories;

  setUp(() {
    fakeCategories = _FakeCategoriesRepository();
  });

  // A real Navigator stack beneath the form — `MaterialApp(home:
  // CategoryFormPage())` alone has nothing to pop back to, so a successful
  // submit's `Navigator.pop()` would be a no-op.
  Widget buildApp({Category? initial, CategoryType? initialType}) =>
      ProviderScope(
        overrides: [
          categoriesRepositoryProvider.overrideWithValue(fakeCategories),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CategoryFormPage(
                      initial: initial,
                      initialType: initialType,
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

  Set<IconData?> gridIcons(WidgetTester tester) => tester
      .widgetList<Icon>(
        find.descendant(of: find.byType(GridView), matching: find.byType(Icon)),
      )
      .map((icon) => icon.icon)
      .toSet();

  testWidgets('a new expense category offers only expense icons', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(initialType: CategoryType.expense));
    await tester.tap(find.text('open'));
    await _pumpBounded(tester);

    final icons = gridIcons(tester);
    expect(icons.length, kExpenseCategoryIconChoices.length);
    for (final choice in kExpenseCategoryIconChoices) {
      expect(
        icons.contains(choice.$3),
        isTrue,
        reason: 'expected expense icon "${choice.$1}" in the grid',
      );
    }
    for (final choice in kIncomeCategoryIconChoices) {
      expect(
        icons.contains(choice.$3),
        isFalse,
        reason:
            'income icon "${choice.$1}" should not appear for an expense category',
      );
    }
  });

  testWidgets('a new income category offers only income icons', (tester) async {
    await tester.pumpWidget(buildApp(initialType: CategoryType.income));
    await tester.tap(find.text('open'));
    await _pumpBounded(tester);

    final icons = gridIcons(tester);
    expect(icons.length, kIncomeCategoryIconChoices.length);
    for (final choice in kIncomeCategoryIconChoices) {
      expect(
        icons.contains(choice.$3),
        isTrue,
        reason: 'expected income icon "${choice.$1}" in the grid',
      );
    }
    for (final choice in kExpenseCategoryIconChoices) {
      expect(
        icons.contains(choice.$3),
        isFalse,
        reason:
            'expense icon "${choice.$1}" should not appear for an income category',
      );
    }
  });

  testWidgets(
    'switching the type segmented control swaps the icon grid to match',
    (tester) async {
      await tester.pumpWidget(buildApp(initialType: CategoryType.expense));
      await tester.tap(find.text('open'));
      await _pumpBounded(tester);
      expect(gridIcons(tester).length, kExpenseCategoryIconChoices.length);

      await tester.tap(find.text('รายรับ'));
      await _pumpBounded(tester);

      final icons = gridIcons(tester);
      expect(icons.length, kIncomeCategoryIconChoices.length);
      for (final choice in kIncomeCategoryIconChoices) {
        expect(icons.contains(choice.$3), isTrue);
      }
    },
  );

  testWidgets(
    'editing an existing income category shows only income icons, with its own icon selected',
    (tester) async {
      final category = Category(
        id: 1,
        name: 'เงินเดือน',
        type: CategoryType.income,
        iconKey: 'wallet-3-fill',
        colorHex: '#3B82F6',
      );
      await tester.pumpWidget(buildApp(initial: category));
      await tester.tap(find.text('open'));
      await _pumpBounded(tester);

      final icons = gridIcons(tester);
      expect(icons.length, kIncomeCategoryIconChoices.length);
      expect(icons.contains(resolveCategoryIcon('wallet-3-fill')), isTrue);
    },
  );

  group('post-launch-polish-06: field/logic unchanged after restyle', () {
    testWidgets('an empty name is rejected — no create call', (tester) async {
      _usePhoneSizedViewport(tester);
      await tester.pumpWidget(buildApp(initialType: CategoryType.expense));
      await tester.tap(find.text('open'));
      await _pumpBounded(tester);

      await _scrollToFinder(tester, find.byKey(const Key('submitButton')));
      await tester.tap(find.byKey(const Key('submitButton')));
      await _pumpBounded(tester);

      expect(find.text('กรุณากรอกชื่อหมวดหมู่'), findsOneWidget);
      expect(fakeCategories.createCallCount, 0);
    });

    testWidgets(
      'submits the name with the default type/icon/color, then pops',
      (tester) async {
        _usePhoneSizedViewport(tester);
        await tester.pumpWidget(buildApp(initialType: CategoryType.expense));
        await tester.tap(find.text('open'));
        await _pumpBounded(tester);

        await tester.enterText(
          find.descendant(
            of: find.byKey(const Key('nameField')),
            matching: find.byType(TextFormField),
          ),
          'ค่ากาแฟ',
        );
        await _scrollToFinder(tester, find.byKey(const Key('submitButton')));
        await tester.tap(find.byKey(const Key('submitButton')));
        await _pumpBounded(tester);
        await tester.pumpAndSettle(
          const Duration(milliseconds: 50),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 5),
        );

        expect(fakeCategories.createCallCount, 1);
        expect(fakeCategories.lastCreateArgs?.name, 'ค่ากาแฟ');
        expect(fakeCategories.lastCreateArgs?.type, CategoryType.expense);
        expect(
          fakeCategories.lastCreateArgs?.iconKey,
          kExpenseCategoryIconChoices.first.$1,
        );
        expect(
          fakeCategories.lastCreateArgs?.colorHex,
          kCategoryColorChoices.first,
        );
        expect(find.byType(CategoryFormPage), findsNothing);
      },
    );

    testWidgets(
      'picking a different icon and color sends those in the create call',
      (tester) async {
        _usePhoneSizedViewport(tester);
        await tester.pumpWidget(buildApp(initialType: CategoryType.expense));
        await tester.tap(find.text('open'));
        await _pumpBounded(tester);

        await tester.enterText(
          find.descendant(
            of: find.byKey(const Key('nameField')),
            matching: find.byType(TextFormField),
          ),
          'ค่ากาแฟ',
        );

        final secondIconChoice = kExpenseCategoryIconChoices[1];
        await tester.tap(find.byIcon(secondIconChoice.$3));
        await _pumpBounded(tester);

        final secondColor = kCategoryColorChoices[1];
        final secondColorFinder = find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color ==
                  colorFromHex(secondColor),
        );
        await _scrollToFinder(tester, secondColorFinder);
        await tester.tap(secondColorFinder);
        await _pumpBounded(tester);

        await _scrollToFinder(tester, find.byKey(const Key('submitButton')));
        await tester.tap(find.byKey(const Key('submitButton')));
        await _pumpBounded(tester);

        expect(fakeCategories.lastCreateArgs?.iconKey, secondIconChoice.$1);
        expect(fakeCategories.lastCreateArgs?.colorHex, secondColor);
      },
    );

    testWidgets(
      'editing prefills the name and submits via update(), never create()',
      (tester) async {
        _usePhoneSizedViewport(tester);
        final existing = Category(
          id: 5,
          name: 'อาหาร',
          type: CategoryType.expense,
          iconKey: 'restaurant-fill',
          colorHex: kCategoryColorChoices[2],
        );
        await tester.pumpWidget(buildApp(initial: existing));
        await tester.tap(find.text('open'));
        await _pumpBounded(tester);

        expect(find.text('อาหาร'), findsOneWidget);

        await tester.enterText(
          find.descendant(
            of: find.byKey(const Key('nameField')),
            matching: find.byType(TextFormField),
          ),
          'อาหารกลางวัน',
        );
        await _scrollToFinder(tester, find.byKey(const Key('submitButton')));
        await tester.tap(find.byKey(const Key('submitButton')));
        await _pumpBounded(tester);

        expect(fakeCategories.createCallCount, 0);
        expect(fakeCategories.updateCallCount, 1);
        expect(fakeCategories.lastUpdateArgs?.id, 5);
        expect(fakeCategories.lastUpdateArgs?.name, 'อาหารกลางวัน');
        expect(fakeCategories.lastUpdateArgs?.iconKey, 'restaurant-fill');
        expect(
          fakeCategories.lastUpdateArgs?.colorHex,
          kCategoryColorChoices[2],
        );
      },
    );

    testWidgets('a failed submit shows the error and stays on the page', (
      tester,
    ) async {
      _usePhoneSizedViewport(tester);
      fakeCategories.nextResult = const Left(
        UnknownFailure(message: 'Could not save category'),
      );
      await tester.pumpWidget(buildApp(initialType: CategoryType.expense));
      await tester.tap(find.text('open'));
      await _pumpBounded(tester);

      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('nameField')),
          matching: find.byType(TextFormField),
        ),
        'ค่ากาแฟ',
      );
      await _scrollToFinder(tester, find.byKey(const Key('submitButton')));
      await tester.tap(find.byKey(const Key('submitButton')));
      await _pumpBounded(tester);

      expect(find.text('Could not save category'), findsOneWidget);
      expect(find.byType(CategoryFormPage), findsOneWidget);
    });

    testWidgets(
      'editing shows a delete button that counts linked transactions and confirms before deleting',
      (tester) async {
        _usePhoneSizedViewport(tester);
        final existing = Category(
          id: 5,
          name: 'อาหาร',
          type: CategoryType.expense,
          iconKey: 'restaurant-fill',
          colorHex: kCategoryColorChoices.first,
        );
        fakeCategories.linkedTransactionCount = 3;
        await tester.pumpWidget(buildApp(initial: existing));
        await tester.tap(find.text('open'));
        await _pumpBounded(tester);
        await _scrollToFinder(
          tester,
          find.byKey(const Key('deleteCategoryButton')),
        );

        expect(find.byKey(const Key('deleteCategoryButton')), findsOneWidget);

        await tester.tap(find.byKey(const Key('deleteCategoryButton')));
        await _pumpBounded(tester);

        expect(
          find.text(
            'มี 3 รายการที่ใช้หมวดหมู่นี้อยู่ — รายการเหล่านั้นจะกลายเป็น "ยังไม่ระบุหมวดหมู่" ยืนยันลบไหม',
          ),
          findsOneWidget,
        );

        await tester.tap(find.widgetWithText(FilledButton, 'ลบ'));
        await _pumpBounded(tester);

        expect(fakeCategories.deleteCallCount, 1);
      },
    );

    testWidgets('a new (non-editing) category shows no delete button', (
      tester,
    ) async {
      _usePhoneSizedViewport(tester);
      await tester.pumpWidget(buildApp(initialType: CategoryType.expense));
      await tester.tap(find.text('open'));
      await _pumpBounded(tester);

      expect(find.byKey(const Key('deleteCategoryButton')), findsNothing);
    });
  });
}

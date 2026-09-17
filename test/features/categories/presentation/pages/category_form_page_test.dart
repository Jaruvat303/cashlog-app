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

class _FakeCategoriesRepository implements CategoriesRepository {
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

Widget _buildApp({Category? initial, CategoryType? initialType}) => ProviderScope(
  overrides: [categoriesRepositoryProvider.overrideWithValue(_FakeCategoriesRepository())],
  child: MaterialApp(home: CategoryFormPage(initial: initial, initialType: initialType)),
);

Set<IconData?> _gridIcons(WidgetTester tester) => tester
    .widgetList<Icon>(find.descendant(of: find.byType(GridView), matching: find.byType(Icon)))
    .map((icon) => icon.icon)
    .toSet();

void main() {
  testWidgets('a new expense category offers only expense icons', (tester) async {
    await tester.pumpWidget(_buildApp(initialType: CategoryType.expense));
    await tester.pump();

    final gridIcons = _gridIcons(tester);
    expect(gridIcons.length, kExpenseCategoryIconChoices.length);
    for (final choice in kExpenseCategoryIconChoices) {
      expect(gridIcons.contains(choice.$3), isTrue, reason: 'expected expense icon "${choice.$1}" in the grid');
    }
    for (final choice in kIncomeCategoryIconChoices) {
      expect(gridIcons.contains(choice.$3), isFalse, reason: 'income icon "${choice.$1}" should not appear for an expense category');
    }
  });

  testWidgets('a new income category offers only income icons', (tester) async {
    await tester.pumpWidget(_buildApp(initialType: CategoryType.income));
    await tester.pump();

    final gridIcons = _gridIcons(tester);
    expect(gridIcons.length, kIncomeCategoryIconChoices.length);
    for (final choice in kIncomeCategoryIconChoices) {
      expect(gridIcons.contains(choice.$3), isTrue, reason: 'expected income icon "${choice.$1}" in the grid');
    }
    for (final choice in kExpenseCategoryIconChoices) {
      expect(gridIcons.contains(choice.$3), isFalse, reason: 'expense icon "${choice.$1}" should not appear for an income category');
    }
  });

  testWidgets('switching the type segmented control swaps the icon grid to match', (tester) async {
    await tester.pumpWidget(_buildApp(initialType: CategoryType.expense));
    await tester.pump();
    expect(_gridIcons(tester).length, kExpenseCategoryIconChoices.length);

    await tester.tap(find.text('รายรับ'));
    await tester.pump();

    final gridIcons = _gridIcons(tester);
    expect(gridIcons.length, kIncomeCategoryIconChoices.length);
    for (final choice in kIncomeCategoryIconChoices) {
      expect(gridIcons.contains(choice.$3), isTrue);
    }
  });

  testWidgets('editing an existing income category shows only income icons, with its own icon selected', (tester) async {
    final category = Category(id: 1, name: 'เงินเดือน', type: CategoryType.income, iconKey: 'wallet-3-fill', colorHex: '#3B82F6');
    await tester.pumpWidget(_buildApp(initial: category));
    await tester.pump();

    final gridIcons = _gridIcons(tester);
    expect(gridIcons.length, kIncomeCategoryIconChoices.length);
    expect(gridIcons.contains(resolveCategoryIcon('wallet-3-fill')), isTrue);
  });
}

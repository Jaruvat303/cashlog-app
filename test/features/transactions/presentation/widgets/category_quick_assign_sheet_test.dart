// T18/BR-9/FR-5.3: the quick category-assign bottom sheet reached by tapping
// `CategoryQuickAssignChip` on a feed row. Same fake-repository pattern as
// transaction_list_tile_test.dart — every repository the tile (or the sheet
// it opens) touches is overridden before any pumpWidget, so a real dio call
// never reaches Flutter's test HTTP stub (T4's hang).
import 'package:cashlog/core/cache/cache_invalidator.dart';
import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/accounts/data/accounts_repository.dart';
import 'package:cashlog/features/accounts/domain/account.dart';
import 'package:cashlog/features/categories/data/categories_repository.dart';
import 'package:cashlog/features/categories/domain/category.dart';
import 'package:cashlog/features/transactions/data/transactions_repository.dart';
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:cashlog/features/transactions/domain/transaction_page.dart';
import 'package:cashlog/features/transactions/presentation/widgets/transaction_list_tile.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAccountsRepository implements AccountsRepository {
  @override
  Stream<List<Account>> watchActiveAccounts() => Stream.value(const []);
  @override
  Stream<Account?> watchCached(int id) => Stream.value(null);
  @override
  Stream<double> watchCurrentBalance(int accountId) => Stream.value(0);
  @override
  Future<Either<Failure, void>> refreshFromApi() async => const Right(null);
  @override
  Future<Either<Failure, Account>> create({
    required String name,
    required AccountType accountType,
    required double openingBalance,
    required List<String> matchingKeywords,
    required String bankIcon,
  }) => throw UnimplementedError('not exercised by this test');
  @override
  Future<Either<Failure, Account>> update(
    int id, {
    required String name,
    required AccountType accountType,
    required List<String> matchingKeywords,
    required String bankIcon,
  }) => throw UnimplementedError('not exercised by this test');
  @override
  Future<Either<Failure, void>> close(int id) => throw UnimplementedError('not exercised by this test');
}

class _FakeCategoriesRepository implements CategoriesRepository {
  List<Category> categories = const [];

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

class _UpdateCall {
  const _UpdateCall(this.id, this.categoryId);
  final int id;
  final int? categoryId;
}

class _FakeTransactionsRepository implements TransactionsRepository {
  final List<_UpdateCall> updateCalls = [];
  Either<Failure, Transaction> Function(int id, int? categoryId)? updateResult;

  @override
  Stream<List<Transaction>> watchMonth({required int year, required int month}) =>
      throw UnimplementedError('not exercised by this test');
  @override
  Future<Either<Failure, TransactionPage>> fetchPage({required int year, required int month, required int page, int limit = 20}) =>
      throw UnimplementedError('not exercised by this test');
  @override
  Future<Either<Failure, Transaction>> create({
    required TransactionType type,
    required double amount,
    required DateTime date,
    String? note,
    int? accountId,
    int? fromAccountId,
    int? toAccountId,
    int? categoryId,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Future<Either<Failure, Transaction>> update(
    int id, {
    required TransactionType type,
    required double amount,
    required DateTime date,
    String? note,
    int? accountId,
    int? fromAccountId,
    int? toAccountId,
    int? categoryId,
  }) async {
    updateCalls.add(_UpdateCall(id, categoryId));
    return updateResult!(id, categoryId);
  }

  @override
  Future<Either<Failure, void>> delete(int id) => throw UnimplementedError('not exercised by this test');
}

class _RecordingCacheInvalidator implements CacheInvalidator {
  final List<(int, int)> invalidatedMonths = [];
  @override
  void invalidateMonth(int year, int month) => invalidatedMonths.add((year, month));
  @override
  void invalidateMonths(Set<(int, int)> months) => invalidatedMonths.addAll(months);
}

const _groceries = Category(id: 10, name: 'Groceries', type: CategoryType.expense, iconKey: 'restaurant-fill', colorHex: '#FF6B6B');
const _transport = Category(id: 11, name: 'Transport', type: CategoryType.expense, iconKey: 'car-fill', colorHex: '#4ECDC4');
const _salary = Category(id: 20, name: 'Salary', type: CategoryType.income, iconKey: 'money-fill', colorHex: '#22C55E');

final _expenseTransaction = Transaction(
  id: 42,
  amount: 150,
  type: TransactionType.expense,
  accountId: 1,
  source: 'slip',
  transactionDate: DateTime.utc(2026, 9, 5),
  categoryId: null,
);

/// pumpAndSettle can't tell "still legitimately loading" from "stuck
/// forever" — a bounded pump loop fails fast instead (same reasoning as
/// transaction_list_tile_test.dart's `_pumpBounded`).
Future<void> _pumpBounded(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late _FakeTransactionsRepository fakeTransactions;
  late _FakeCategoriesRepository fakeCategories;
  late _RecordingCacheInvalidator cacheInvalidator;

  setUp(() {
    fakeTransactions = _FakeTransactionsRepository();
    fakeCategories = _FakeCategoriesRepository()..categories = const [_groceries, _transport, _salary];
    cacheInvalidator = _RecordingCacheInvalidator();
  });

  Widget buildApp(Transaction transaction, {Map<int, Category> categoriesById = const {}}) => ProviderScope(
    overrides: [
      accountsRepositoryProvider.overrideWithValue(_FakeAccountsRepository()),
      categoriesRepositoryProvider.overrideWithValue(fakeCategories),
      transactionsRepositoryProvider.overrideWithValue(fakeTransactions),
      cacheInvalidatorProvider.overrideWithValue(cacheInvalidator),
    ],
    child: MaterialApp(
      home: Scaffold(body: TransactionListTile(transaction: transaction, categoriesById: categoriesById)),
    ),
  );

  testWidgets('tapping the chip opens the sheet with only categories matching the transaction type, plus Uncategorized', (tester) async {
    await tester.pumpWidget(buildApp(_expenseTransaction));
    await _pumpBounded(tester);

    await tester.tap(find.byKey(const Key('categoryQuickAssignChip')));
    await _pumpBounded(tester);

    expect(find.byKey(const Key('categoryOptionUncategorized')), findsOneWidget);
    expect(find.byKey(const Key('categoryOption_10')), findsOneWidget);
    expect(find.byKey(const Key('categoryOption_11')), findsOneWidget);
    // Salary is an income category — must not be offered for an expense.
    expect(find.byKey(const Key('categoryOption_20')), findsNothing);
  });

  testWidgets('picking a category PATCHes immediately and invalidates the transaction month on success', (tester) async {
    fakeTransactions.updateResult = (id, categoryId) => Right(
      Transaction(
        id: id,
        amount: _expenseTransaction.amount,
        type: _expenseTransaction.type,
        accountId: _expenseTransaction.accountId,
        source: _expenseTransaction.source,
        transactionDate: _expenseTransaction.transactionDate,
        categoryId: categoryId,
      ),
    );
    await tester.pumpWidget(buildApp(_expenseTransaction));
    await _pumpBounded(tester);

    await tester.tap(find.byKey(const Key('categoryQuickAssignChip')));
    await _pumpBounded(tester);
    await tester.tap(find.byKey(const Key('categoryOption_10')));
    await _pumpBounded(tester);

    expect(fakeTransactions.updateCalls, hasLength(1));
    expect(fakeTransactions.updateCalls.single.id, _expenseTransaction.id);
    expect(fakeTransactions.updateCalls.single.categoryId, 10);
    expect(cacheInvalidator.invalidatedMonths, [(2026, 9)]);
  });

  testWidgets('a failed PATCH shows an error and never invalidates any cache (no optimistic update left dangling)', (tester) async {
    fakeTransactions.updateResult = (id, categoryId) => const Left(UnknownFailure(message: 'Could not update category'));
    await tester.pumpWidget(buildApp(_expenseTransaction));
    await _pumpBounded(tester);

    await tester.tap(find.byKey(const Key('categoryQuickAssignChip')));
    await _pumpBounded(tester);
    await tester.tap(find.byKey(const Key('categoryOption_10')));
    await _pumpBounded(tester);

    expect(fakeTransactions.updateCalls, hasLength(1));
    expect(find.text('Could not update category'), findsOneWidget);
    expect(cacheInvalidator.invalidatedMonths, isEmpty);
  });

  testWidgets('re-picking the transaction\'s current category is a no-op — no PATCH, no cache invalidation', (tester) async {
    final alreadyGroceries = Transaction(
      id: _expenseTransaction.id,
      amount: _expenseTransaction.amount,
      type: _expenseTransaction.type,
      accountId: _expenseTransaction.accountId,
      source: _expenseTransaction.source,
      transactionDate: _expenseTransaction.transactionDate,
      categoryId: _groceries.id,
    );
    await tester.pumpWidget(buildApp(alreadyGroceries, categoriesById: const {10: _groceries}));
    await _pumpBounded(tester);

    await tester.tap(find.byKey(const Key('categoryQuickAssignChip')));
    await _pumpBounded(tester);
    // The currently-assigned category shows a checkmark — confirm the sheet
    // reflects the transaction's existing selection before tapping it again.
    expect(find.descendant(of: find.byKey(const Key('categoryOption_10')), matching: find.byIcon(Icons.check)), findsOneWidget);

    await tester.tap(find.byKey(const Key('categoryOption_10')));
    await _pumpBounded(tester);

    expect(fakeTransactions.updateCalls, isEmpty);
    expect(cacheInvalidator.invalidatedMonths, isEmpty);
  });

  testWidgets('an uncategorized transaction shows an "Add category" prompt as its tap target', (tester) async {
    await tester.pumpWidget(buildApp(_expenseTransaction));
    await _pumpBounded(tester);

    expect(find.text('Add category'), findsOneWidget);
  });
}

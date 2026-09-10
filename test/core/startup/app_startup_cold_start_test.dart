// Regression test for the bug found while verifying T7: a transaction with
// a real categoryId must show its category name on cold start, before the
// user ever visits the Categories tab. Boots the REAL MyApp/app_router (not
// just TransactionsPage in isolation) so appStartupProvider's real
// initState wiring in main.dart is what's under test, not a stand-in.
//
// The categories/accounts fakes deliberately start EMPTY and only populate
// after refreshFromApi() is called — mirroring an un-synced local drift
// cache — so this test can only pass if something actually calls that
// refresh before the Transactions/T6-form screens render, not because the
// fake happened to be pre-seeded.
import 'dart:async';

import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/accounts/data/accounts_repository.dart';
import 'package:cashlog/features/accounts/domain/account.dart';
import 'package:cashlog/features/categories/data/categories_repository.dart';
import 'package:cashlog/features/categories/domain/category.dart';
import 'package:cashlog/features/dashboard/data/dashboard_repository.dart';
import 'package:cashlog/features/dashboard/domain/dashboard_summary.dart';
import 'package:cashlog/features/transactions/data/transactions_repository.dart';
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:cashlog/features/transactions/domain/transaction_page.dart';
import 'package:cashlog/main.dart';
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

/// Starts empty; [refreshFromApi] is what populates it — the same shape a
/// real drift cache would have before its first successful sync.
class _FakeCategoriesRepository implements CategoriesRepository {
  List<Category> _current = [];
  final _controller = StreamController<List<Category>>.broadcast();

  @override
  Stream<List<Category>> watchAll() => Stream.multi((controller) {
    controller.add(_current);
    final sub = _controller.stream.listen(controller.add);
    controller.onCancel = sub.cancel;
  });

  @override
  Future<Either<Failure, void>> refreshFromApi() async {
    _current = const [Category(id: 42, name: 'Food', type: CategoryType.expense, iconKey: 'food', colorHex: '#EF4444')];
    _controller.add(_current);
    return const Right(null);
  }

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

/// A single un-scoped channel (ignores year/month) — this test is about
/// cold-start category sync, not month pagination (already covered by
/// transactions_page_test.dart).
class _FakeTransactionsRepository implements TransactionsRepository {
  List<Transaction> _current = [];
  final _controller = StreamController<List<Transaction>>.broadcast();

  @override
  Stream<List<Transaction>> watchMonth({required int year, required int month}) => Stream.multi((controller) {
    controller.add(_current);
    final sub = _controller.stream.listen(controller.add);
    controller.onCancel = sub.cancel;
  });

  @override
  Future<Either<Failure, TransactionPage>> fetchPage({required int year, required int month, required int page, int limit = 20}) async {
    _current = [
      Transaction(
        id: 1,
        amount: 120,
        type: TransactionType.expense,
        note: 'Groceries',
        categoryId: 42, // real, server-assigned category
        source: 'manual',
        transactionDate: DateTime.utc(year, month, 5),
      ),
    ];
    _controller.add(_current);
    return Right(TransactionPage(transactions: _current, currentPage: 1, totalPages: 1));
  }

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
  }) => throw UnimplementedError('not exercised by this test');
  @override
  Future<Either<Failure, void>> delete(int id) => throw UnimplementedError('not exercised by this test');
}

/// This test boots the real `MyApp`, which lands on the Dashboard tab by
/// default (T8) — that tab now fires a real network fetch on mount, so it
/// needs the same "fake the repository so no real dio call happens" fix as
/// every other repository here, even though this test's assertions are
/// about Transactions, not Dashboard.
class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<Either<Failure, DashboardSummary>> fetchSummary({required int year, required int month}) async => Right(
    DashboardSummary(totalIncome: 0, totalExpense: 0, totalTransfer: 0, year: year, month: month, income: const [], expense: const []),
  );
}

/// pumpAndSettle can't tell "still legitimately loading" from "stuck
/// forever" — a bounded pump loop fails fast instead (same reasoning as
/// test/widget_test.dart's `_pumpBounded`).
Future<void> _pumpBounded(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets(
    'a categorized transaction shows its category name on cold start, before the Categories tab is ever visited',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountsRepositoryProvider.overrideWithValue(_FakeAccountsRepository()),
            categoriesRepositoryProvider.overrideWithValue(_FakeCategoriesRepository()),
            transactionsRepositoryProvider.overrideWithValue(_FakeTransactionsRepository()),
            dashboardRepositoryProvider.overrideWithValue(_FakeDashboardRepository()),
          ],
          child: const MyApp(),
        ),
      );
      await _pumpBounded(tester);

      // Lands on Dashboard by default — go straight to Transactions,
      // deliberately never tapping Categories.
      await tester.tap(find.widgetWithText(NavigationDestination, 'Transactions'));
      await _pumpBounded(tester);

      expect(find.textContaining('Food'), findsOneWidget, reason: 'category name should be visible without ever visiting Categories tab');
    },
  );

  testWidgets("T6's create-transaction form category dropdown is populated on cold start too (same root cause/fix)", (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountsRepositoryProvider.overrideWithValue(_FakeAccountsRepository()),
          categoriesRepositoryProvider.overrideWithValue(_FakeCategoriesRepository()),
          transactionsRepositoryProvider.overrideWithValue(_FakeTransactionsRepository()),
          dashboardRepositoryProvider.overrideWithValue(_FakeDashboardRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await _pumpBounded(tester);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Transactions'));
    await _pumpBounded(tester);

    await tester.tap(find.byIcon(Icons.add));
    await _pumpBounded(tester);

    // The category dropdown is the only DropdownButtonFormField<int?> on
    // this form (account pickers are DropdownButtonFormField<int>) — a new
    // transaction defaults to type expense, so it's already visible.
    await tester.tap(find.byType(DropdownButtonFormField<int?>));
    await _pumpBounded(tester);

    expect(find.text('Food'), findsOneWidget, reason: 'category options should be populated without ever visiting Categories tab');
  });
}

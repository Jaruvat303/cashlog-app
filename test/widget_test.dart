// T3 nav shell smoke test: all 4 tabs are reachable without crashing.
//
// AccountsPage (T4) is a real page now, not a placeholder, so this test
// fakes AccountsRepository out entirely rather than letting it hit dio for
// real: Flutter's built-in "every HTTP request comes back 400" test stub is
// not a controlled fake response, it's a genuine round-trip through the
// real client/retry stack with unspecified timing — not something this
// nav-shell test should depend on.
import 'dart:async';

import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/accounts/data/accounts_repository.dart';
import 'package:cashlog/features/accounts/domain/account.dart';
import 'package:cashlog/features/categories/data/categories_repository.dart';
import 'package:cashlog/features/categories/domain/category.dart';
import 'package:cashlog/features/dashboard/data/dashboard_repository.dart';
import 'package:cashlog/features/dashboard/domain/dashboard_summary.dart';
import 'package:cashlog/features/transactions/data/pending_actions_repository.dart';
import 'package:cashlog/features/transactions/data/transactions_repository.dart';
import 'package:cashlog/features/transactions/domain/pending_action.dart';
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:cashlog/features/transactions/domain/transaction_page.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cashlog/main.dart';

/// Canned, instant results — no ApiClient, no AppDatabase, nothing async
/// for the test to ever get stuck waiting on.
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
  }) => throw UnimplementedError('not exercised by the nav-shell smoke test');

  @override
  Future<Either<Failure, Account>> update(
    int id, {
    required String name,
    required AccountType accountType,
    required List<String> matchingKeywords,
    required String bankIcon,
  }) => throw UnimplementedError('not exercised by the nav-shell smoke test');

  @override
  Future<Either<Failure, void>> close(int id) => throw UnimplementedError('not exercised by the nav-shell smoke test');
}

/// T5 replaced the Categories placeholder with a real page — same reasoning
/// as [_FakeAccountsRepository]: fake the repository entirely so this
/// nav-shell test never lets a real dio call hit Flutter's test HTTP stub.
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
  }) => throw UnimplementedError('not exercised by the nav-shell smoke test');

  @override
  Future<Either<Failure, Category>> update(
    int id, {
    required String name,
    required CategoryType type,
    required String iconKey,
    required String colorHex,
  }) => throw UnimplementedError('not exercised by the nav-shell smoke test');

  @override
  Future<int> countLinkedTransactions(int categoryId) => throw UnimplementedError('not exercised by the nav-shell smoke test');

  @override
  Future<Either<Failure, void>> delete(int id) => throw UnimplementedError('not exercised by the nav-shell smoke test');
}

/// T7 replaced the Transactions placeholder with a real page — same
/// reasoning as [_FakeAccountsRepository]: fake the repository entirely so
/// this nav-shell test never lets a real dio call hit Flutter's test HTTP
/// stub (the feed's initState kicks off a page-1 fetch as soon as the tab
/// mounts).
class _FakeTransactionsRepository implements TransactionsRepository {
  @override
  Stream<List<Transaction>> watchMonth({required int year, required int month}) => Stream.value(const []);

  @override
  Future<Either<Failure, TransactionPage>> fetchPage({required int year, required int month, required int page, int limit = 20}) async =>
      const Right(TransactionPage(transactions: [], currentPage: 1, totalPages: 1));

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
  }) => throw UnimplementedError('not exercised by the nav-shell smoke test');

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
  }) => throw UnimplementedError('not exercised by the nav-shell smoke test');

  @override
  Future<Either<Failure, void>> delete(int id) => throw UnimplementedError('not exercised by the nav-shell smoke test');
}

/// T8 replaced the Dashboard placeholder with a real page — same reasoning
/// as [_FakeAccountsRepository]: fake the repository entirely so this
/// nav-shell test never lets a real dio call hit Flutter's test HTTP stub
/// (the page's build kicks off a summary fetch as soon as it mounts).
class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<Either<Failure, DashboardSummary>> fetchSummary({required int year, required int month}) async => Right(
    DashboardSummary(totalIncome: 0, totalExpense: 0, totalTransfer: 0, year: year, month: month, income: const [], expense: const []),
  );
}

/// T13 replaced the Transactions placeholder's AppBar with a stuck-items
/// badge — fake the repository entirely (empty queue, always) rather than a
/// real drift-backed instance: a real one inside a testWidgets test hits a
/// known drift/flutter_test interaction (cancelling a live `.watch()`
/// stream during widget-tree disposal schedules a zero-duration Timer that
/// never fires before the test framework's post-test check, see
/// https://github.com/simolus3/drift/issues/3323 — confirmed during T13
/// verification).
class _FakePendingActionsRepository implements PendingActionsRepository {
  @override
  Stream<List<PendingAction>> watchAll() => Stream.value(const []);

  @override
  Future<bool> recordIfTransient({
    required Failure failure,
    required PendingActionType actionType,
    required Map<String, dynamic> payload,
    int? targetTransactionId,
  }) => throw UnimplementedError('not exercised by the nav-shell smoke test');

  @override
  Future<void> recordRetryFailure(int id, String? errorCode) => throw UnimplementedError('not exercised by the nav-shell smoke test');

  @override
  Future<void> remove(int id) => throw UnimplementedError('not exercised by the nav-shell smoke test');
}

/// pumpAndSettle can't tell "still legitimately loading" from "stuck
/// forever" — it just keeps pumping until nothing's scheduled, up to its
/// own 10-minute default timeout. A bounded pump loop fails fast instead of
/// hanging for the length of that default.
Future<void> _pumpBounded(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('switches between all 4 bottom nav tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountsRepositoryProvider.overrideWithValue(_FakeAccountsRepository()),
          categoriesRepositoryProvider.overrideWithValue(_FakeCategoriesRepository()),
          transactionsRepositoryProvider.overrideWithValue(_FakeTransactionsRepository()),
          dashboardRepositoryProvider.overrideWithValue(_FakeDashboardRepository()),
          // T13: TransactionsPage now watches this for its stuck-items badge
          // as soon as it's built (IndexedStack builds every tab up front,
          // not just the one currently selected).
          pendingActionsRepositoryProvider.overrideWithValue(_FakePendingActionsRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await _pumpBounded(tester);

    // T8 replaced the placeholder with the real dashboard feature — just
    // confirm the tab itself is reachable, per this smoke test's scope.
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Dashboard')), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Transactions'));
    await _pumpBounded(tester);
    // T7 replaced the placeholder with the real transaction feed — just
    // confirm the tab itself is reachable, per this smoke test's scope.
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Transactions')), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Accounts'));
    await _pumpBounded(tester);
    // T4 replaced the placeholder with the real accounts feature — just
    // confirm the tab itself is reachable, per this smoke test's scope.
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Accounts')), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Categories'));
    await _pumpBounded(tester);
    // T5 replaced the placeholder with the real categories feature — just
    // confirm the tab itself is reachable, per this smoke test's scope.
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Categories')), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Dashboard'));
    await _pumpBounded(tester);
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Dashboard')), findsOneWidget);
  });
}

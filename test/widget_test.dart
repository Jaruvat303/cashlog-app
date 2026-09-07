// T3 nav shell smoke test: all 4 tabs are reachable without crashing.
//
// AccountsPage (T4) is a real page now, not a placeholder, so this test
// fakes AccountsRepository out entirely rather than letting it hit dio for
// real: Flutter's built-in "every HTTP request comes back 400" test stub is
// not a controlled fake response, it's a genuine round-trip through the
// real client/retry stack with unspecified timing — not something this
// nav-shell test should depend on.
import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/accounts/data/accounts_repository.dart';
import 'package:cashlog/features/accounts/domain/account.dart';
import 'package:cashlog/features/categories/data/categories_repository.dart';
import 'package:cashlog/features/categories/domain/category.dart';
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
        ],
        child: const MyApp(),
      ),
    );
    await _pumpBounded(tester);

    expect(find.text('Dashboard — coming soon'), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Transactions'));
    await _pumpBounded(tester);
    expect(find.text('Transactions — coming soon'), findsOneWidget);

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
    expect(find.text('Dashboard — coming soon'), findsOneWidget);
  });
}

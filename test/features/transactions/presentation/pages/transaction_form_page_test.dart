// Before any pumpWidget/pumpAndSettle, every repository this form touches
// is overridden with a hand-written fake (same pattern as
// _FakeAccountsRepository in test/widget_test.dart) — this is what keeps a
// real dio call from ever reaching Flutter's test HTTP stub, the exact
// thing that caused a hang in T4.
import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/accounts/data/accounts_repository.dart';
import 'package:cashlog/features/accounts/domain/account.dart';
import 'package:cashlog/features/categories/data/categories_repository.dart';
import 'package:cashlog/features/categories/domain/category.dart';
import 'package:cashlog/features/transactions/data/transactions_repository.dart';
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:cashlog/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAccountsRepository implements AccountsRepository {
  @override
  Stream<List<Account>> watchActiveAccounts() => Stream.value(const [
    Account(id: 1, name: 'Cash', accountType: AccountType.cash, openingBalance: 0, matchingKeywords: [], bankIcon: 'cash', isActive: true),
    Account(id: 2, name: 'SCB', accountType: AccountType.bank, openingBalance: 0, matchingKeywords: [], bankIcon: 'scb', isActive: true),
  ]);

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
  }) => throw UnimplementedError('not exercised by this form test');

  @override
  Future<Either<Failure, Account>> update(
    int id, {
    required String name,
    required AccountType accountType,
    required List<String> matchingKeywords,
    required String bankIcon,
  }) => throw UnimplementedError('not exercised by this form test');

  @override
  Future<Either<Failure, void>> close(int id) => throw UnimplementedError('not exercised by this form test');
}

class _FakeCategoriesRepository implements CategoriesRepository {
  @override
  Stream<List<Category>> watchAll() => Stream.value(const [
    Category(id: 10, name: 'Food', type: CategoryType.expense, iconKey: 'food', colorHex: '#EF4444'),
    Category(id: 20, name: 'Salary', type: CategoryType.income, iconKey: 'salary', colorHex: '#22C55E'),
  ]);

  @override
  Future<Either<Failure, void>> refreshFromApi() async => const Right(null);

  @override
  Future<Either<Failure, Category>> create({
    required String name,
    required CategoryType type,
    required String iconKey,
    required String colorHex,
  }) => throw UnimplementedError('not exercised by this form test');

  @override
  Future<Either<Failure, Category>> update(
    int id, {
    required String name,
    required CategoryType type,
    required String iconKey,
    required String colorHex,
  }) => throw UnimplementedError('not exercised by this form test');

  @override
  Future<int> countLinkedTransactions(int categoryId) => throw UnimplementedError('not exercised by this form test');

  @override
  Future<Either<Failure, void>> delete(int id) => throw UnimplementedError('not exercised by this form test');
}

class _FakeTransactionsRepository implements TransactionsRepository {
  int createCallCount = 0;

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
  }) async {
    createCallCount++;
    return Right(
      Transaction(
        id: 1,
        amount: amount,
        type: type,
        accountId: accountId,
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        categoryId: categoryId,
        source: 'manual',
        transactionDate: date,
      ),
    );
  }

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
  }) => throw UnimplementedError('not exercised by this form test');
}

/// pumpAndSettle can't tell "still legitimately loading" from "stuck
/// forever" — a bounded pump loop fails fast instead (same reasoning as
/// test/widget_test.dart's `_pumpBounded`).
Future<void> _pumpBounded(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late _FakeTransactionsRepository fakeTransactions;

  setUp(() {
    fakeTransactions = _FakeTransactionsRepository();
  });

  Widget buildApp() => ProviderScope(
    overrides: [
      accountsRepositoryProvider.overrideWithValue(_FakeAccountsRepository()),
      categoriesRepositoryProvider.overrideWithValue(_FakeCategoriesRepository()),
      transactionsRepositoryProvider.overrideWithValue(fakeTransactions),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TransactionFormPage())),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  testWidgets('a transfer with the same account on both sides is blocked before any create call', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('open'));
    await _pumpBounded(tester);

    await tester.tap(find.byKey(const Key('transactionTypeDropdown')));
    await _pumpBounded(tester);
    await tester.tap(find.text('Transfer').last);
    await _pumpBounded(tester);

    await tester.tap(find.byKey(const Key('fromAccountDropdown')));
    await _pumpBounded(tester);
    await tester.tap(find.text('Cash').last);
    await _pumpBounded(tester);

    await tester.tap(find.byKey(const Key('toAccountDropdown')));
    await _pumpBounded(tester);
    await tester.tap(find.text('Cash').last);
    await _pumpBounded(tester);

    await tester.enterText(find.byKey(const Key('amountField')), '100');
    await tester.tap(find.byKey(const Key('submitButton')));
    await _pumpBounded(tester);

    expect(find.text('Source and destination account must be different'), findsOneWidget);
    expect(fakeTransactions.createCallCount, 0);
    // Still on the form — a blocked submit never pops.
    expect(find.byType(TransactionFormPage), findsOneWidget);
  });

  testWidgets('creating a valid income transaction calls create and pops the form', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('open'));
    await _pumpBounded(tester);

    await tester.tap(find.byKey(const Key('transactionTypeDropdown')));
    await _pumpBounded(tester);
    await tester.tap(find.text('Income').last);
    await _pumpBounded(tester);

    await tester.tap(find.byKey(const Key('accountDropdown')));
    await _pumpBounded(tester);
    await tester.tap(find.text('Cash').last);
    await _pumpBounded(tester);

    await tester.enterText(find.byKey(const Key('amountField')), '5000');
    await tester.tap(find.byKey(const Key('submitButton')));
    await _pumpBounded(tester);
    // A successful submit pops the route, which then runs a reverse page
    // transition — the plain bounded pump loop above isn't enough to flush
    // that animation to completion, so settle explicitly (still bounded:
    // nothing here is waiting on real I/O, so this can't hang the way an
    // unmocked dio call would).
    await tester.pumpAndSettle(const Duration(milliseconds: 50), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));

    expect(fakeTransactions.createCallCount, 1);
    // A successful submit pops back to the launcher screen.
    expect(find.byType(TransactionFormPage), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}

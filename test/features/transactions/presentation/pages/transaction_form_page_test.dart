// Before any pumpWidget/pumpAndSettle, every repository this form touches
// is overridden with a hand-written fake (same pattern as
// _FakeAccountsRepository in test/widget_test.dart) — this is what keeps a
// real dio call from ever reaching Flutter's test HTTP stub, the exact
// thing that caused a hang in T4.
import 'dart:async';

import 'package:cashlog/core/cache/cache_invalidator.dart';
import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/accounts/data/accounts_repository.dart';
import 'package:cashlog/features/accounts/domain/account.dart';
import 'package:cashlog/features/categories/data/categories_repository.dart';
import 'package:cashlog/features/categories/domain/category.dart';
import 'package:cashlog/features/transactions/data/pending_action_mapper.dart';
import 'package:cashlog/features/transactions/data/pending_actions_repository.dart';
import 'package:cashlog/features/transactions/data/transactions_repository.dart';
import 'package:cashlog/features/transactions/domain/pending_action.dart';
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:cashlog/features/transactions/domain/transaction_page.dart';
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
  // T13: when set, [create] returns this instead of its default success —
  // lets a test drive a real failure through the actual submit path.
  Either<Failure, Transaction>? nextCreateResult;

  @override
  Stream<List<Transaction>> watchMonth({required int year, required int month}) =>
      throw UnimplementedError('not exercised by this form test');

  @override
  Future<Either<Failure, TransactionPage>> fetchPage({required int year, required int month, required int page, int limit = 20}) =>
      throw UnimplementedError('not exercised by this form test');

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
    final forced = nextCreateResult;
    if (forced != null) return forced;
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

  int updateCallCount = 0;
  Either<Failure, Transaction>? nextUpdateResult;

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
    updateCallCount++;
    final forced = nextUpdateResult;
    if (forced != null) return forced;
    return Right(
      Transaction(
        id: id,
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
  Future<Either<Failure, void>> delete(int id) => throw UnimplementedError('not exercised by this form test');
}

/// T14: records exactly which months this form's mutation asked to
/// invalidate, without needing the real `monthTransactionsProvider`/
/// `dashboardSummaryProvider` families (and their repositories) wired up —
/// the actual invalidation mechanics are covered by
/// test/core/cache/cache_invalidator_test.dart.
class _RecordingCacheInvalidator implements CacheInvalidator {
  final List<Set<(int, int)>> invalidatedMonthSets = [];

  @override
  void invalidateMonth(int year, int month) => invalidatedMonthSets.add({(year, month)});

  @override
  void invalidateMonths(Set<(int, int)> months) => invalidatedMonthSets.add(months);
}

/// In-memory stand-in, not a real drift-backed repository — a real one
/// inside a testWidgets test hits a known drift/flutter_test interaction
/// (cancelling a live `.watch()` stream during widget-tree disposal
/// schedules a zero-duration Timer that never fires before the test
/// framework's post-test check, see
/// https://github.com/simolus3/drift/issues/3323 — confirmed during T13
/// verification). Reuses the real `recordIfTransient` policy check inline so
/// this fake's queue-or-not behavior matches production exactly; the
/// dedicated pending_actions_repository_test.dart (plain test(), unaffected
/// by the FakeAsync interaction above) covers this against a real drift db.
class _FakePendingActionsRepository implements PendingActionsRepository {
  final List<PendingAction> _items = [];
  int _nextId = 1;
  final _controller = StreamController<List<PendingAction>>.broadcast();

  @override
  Stream<List<PendingAction>> watchAll() async* {
    yield List.unmodifiable(_items);
    yield* _controller.stream;
  }

  @override
  Future<bool> recordIfTransient({
    required Failure failure,
    required PendingActionType actionType,
    required Map<String, dynamic> payload,
    int? targetTransactionId,
  }) async {
    if (failure.retryPolicy != RetryPolicy.transient) return false;
    _items.add(
      PendingAction(
        id: _nextId++,
        actionType: actionType,
        payload: payload,
        targetTransactionId: targetTransactionId,
        createdAt: DateTime.now(),
        lastErrorCode: errorTagForFailure(failure),
      ),
    );
    _controller.add(List.unmodifiable(_items));
    return true;
  }

  @override
  Future<void> recordRetryFailure(int id, String? errorCode) => throw UnimplementedError('not exercised by this form test');

  @override
  Future<void> remove(int id) => throw UnimplementedError('not exercised by this form test');
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
  late _FakePendingActionsRepository pendingActions;
  late _RecordingCacheInvalidator cacheInvalidator;

  setUp(() {
    fakeTransactions = _FakeTransactionsRepository();
    // T13's tests below assert against this repository's own state after
    // driving a failure through the actual submit path, not a pre-seeded
    // stand-in.
    pendingActions = _FakePendingActionsRepository();
    cacheInvalidator = _RecordingCacheInvalidator();
  });

  Widget buildApp() => ProviderScope(
    overrides: [
      accountsRepositoryProvider.overrideWithValue(_FakeAccountsRepository()),
      categoriesRepositoryProvider.overrideWithValue(_FakeCategoriesRepository()),
      transactionsRepositoryProvider.overrideWithValue(fakeTransactions),
      pendingActionsRepositoryProvider.overrideWithValue(pendingActions),
      cacheInvalidatorProvider.overrideWithValue(cacheInvalidator),
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

  Widget buildEditApp(Transaction initial) => ProviderScope(
    overrides: [
      accountsRepositoryProvider.overrideWithValue(_FakeAccountsRepository()),
      categoriesRepositoryProvider.overrideWithValue(_FakeCategoriesRepository()),
      transactionsRepositoryProvider.overrideWithValue(fakeTransactions),
      pendingActionsRepositoryProvider.overrideWithValue(pendingActions),
      cacheInvalidatorProvider.overrideWithValue(cacheInvalidator),
    ],
    child: MaterialApp(home: TransactionFormPage(initial: initial)),
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

    // T14: a create invalidates only the new transaction's own month —
    // defaults to today since no date was explicitly picked in this test.
    final today = DateTime.now();
    expect(cacheInvalidator.invalidatedMonthSets, [
      {(today.year, today.month)},
    ]);
  });

  group('T14 cache invalidation', () {
    testWidgets('editing a transaction without changing its date invalidates only that one month', (tester) async {
      final original = Transaction(
        id: 42,
        amount: 100,
        type: TransactionType.expense,
        source: 'manual',
        transactionDate: DateTime(2026, 9, 15),
      );
      await tester.pumpWidget(buildEditApp(original));
      await _pumpBounded(tester);

      await tester.tap(find.byKey(const Key('accountDropdown')));
      await _pumpBounded(tester);
      await tester.tap(find.text('Cash').last);
      await _pumpBounded(tester);

      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pumpAndSettle(const Duration(milliseconds: 50), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));

      expect(fakeTransactions.updateCallCount, 1);
      expect(cacheInvalidator.invalidatedMonthSets, [
        {(2026, 9)},
      ]);
    });
  });

  group('T13 pending-actions queue', () {
    Future<void> fillAndSubmitIncome(WidgetTester tester) async {
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
    }

    testWidgets('a transient create failure gets queued and shows the retry-queue snackbar', (tester) async {
      fakeTransactions.nextCreateResult = const Left(TimeoutFailure());
      await fillAndSubmitIncome(tester);

      expect(find.text('No connection — saved to the retry queue'), findsOneWidget);
      // A blocked/failed submit never pops — the form stays open with the
      // typed data still visible, same as any other failed submit today.
      expect(find.byType(TransactionFormPage), findsOneWidget);

      final queued = await pendingActions.watchAll().first;
      expect(queued, hasLength(1));
      expect(queued.single.actionType, PendingActionType.createTransaction);
      expect(queued.single.targetTransactionId, isNull);
    });

    testWidgets('a permanent create failure is not queued — snackbar only, same as before this ticket', (tester) async {
      fakeTransactions.nextCreateResult = const Left(InvalidInputFailure(message: 'Invalid input'));
      await fillAndSubmitIncome(tester);

      expect(find.text('Invalid input'), findsOneWidget);
      expect(await pendingActions.watchAll().first, isEmpty);
    });
  });
}

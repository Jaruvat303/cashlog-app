// Before any pumpWidget, every repository the tile (or the edit form it can
// push) touches is overridden with a hand-written fake — same pattern as
// _FakeAccountsRepository/_FakeCategoriesRepository/_FakeTransactionsRepository
// in transaction_form_page_test.dart/transactions_page_test.dart — so a real
// dio call never reaches Flutter's test HTTP stub (T4's hang).
import 'dart:async';

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
  Future<Either<Failure, void>> refreshFromApi() async => const Right(null);

  @override
  Future<Either<Failure, Account>> create({
    required String name,
    required AccountType accountType,
    required double openingBalance,
    required List<String> matchingKeywords,
    required String bankIcon,
  }) => throw UnimplementedError('not exercised by this tile test');

  @override
  Future<Either<Failure, Account>> update(
    int id, {
    required String name,
    required AccountType accountType,
    required List<String> matchingKeywords,
    required String bankIcon,
  }) => throw UnimplementedError('not exercised by this tile test');

  @override
  Future<Either<Failure, void>> close(int id) => throw UnimplementedError('not exercised by this tile test');
}

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
  }) => throw UnimplementedError('not exercised by this tile test');

  @override
  Future<Either<Failure, Category>> update(
    int id, {
    required String name,
    required CategoryType type,
    required String iconKey,
    required String colorHex,
  }) => throw UnimplementedError('not exercised by this tile test');

  @override
  Future<int> countLinkedTransactions(int categoryId) => throw UnimplementedError('not exercised by this tile test');

  @override
  Future<Either<Failure, void>> delete(int id) => throw UnimplementedError('not exercised by this tile test');
}

class _FakeTransactionsRepository implements TransactionsRepository {
  final List<int> deleteCalls = [];
  Either<Failure, void> deleteResult = const Right(null);

  @override
  Stream<List<Transaction>> watchMonth({required int year, required int month}) =>
      throw UnimplementedError('not exercised by this tile test');

  @override
  Future<Either<Failure, TransactionPage>> fetchPage({required int year, required int month, required int page, int limit = 20}) =>
      throw UnimplementedError('not exercised by this tile test');

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
  }) => throw UnimplementedError('not exercised by this tile test');

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
  }) => throw UnimplementedError('not exercised by this tile test');

  @override
  Future<Either<Failure, void>> delete(int id) async {
    deleteCalls.add(id);
    return deleteResult;
  }
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
  Future<void> recordRetryFailure(int id, String? errorCode) => throw UnimplementedError('not exercised by this tile test');

  @override
  Future<void> remove(int id) => throw UnimplementedError('not exercised by this tile test');
}

final _junkTransaction = Transaction(
  id: 7,
  amount: 0,
  type: TransactionType.expense,
  source: 'slip',
  transactionDate: DateTime.utc(2026, 9, 5),
  isJunk: true,
);

/// Same fields, but as they'd look right after a manual edit fixed the
/// amount (spec §7.7 — T12's DoD: "after manual edit, the badge
/// disappears"). `isJunk` is computed by `transactionFromJson`, not set by
/// hand in real code, but the tile only ever reads the stored flag, so
/// asserting against a `false`-flagged Transaction is exactly what the tile
/// sees once the PATCH response comes back through the mapper.
final _editedTransaction = Transaction(
  id: 7,
  amount: 500,
  type: TransactionType.expense,
  source: 'slip',
  transactionDate: DateTime.utc(2026, 9, 5),
  isJunk: false,
);

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

  setUp(() {
    fakeTransactions = _FakeTransactionsRepository();
    // T13's tests below assert against this repository's own state after
    // driving a failure through the actual delete path, not a pre-seeded
    // stand-in.
    pendingActions = _FakePendingActionsRepository();
  });

  Widget buildApp(Transaction transaction) => ProviderScope(
    overrides: [
      accountsRepositoryProvider.overrideWithValue(_FakeAccountsRepository()),
      categoriesRepositoryProvider.overrideWithValue(_FakeCategoriesRepository()),
      transactionsRepositoryProvider.overrideWithValue(fakeTransactions),
      pendingActionsRepositoryProvider.overrideWithValue(pendingActions),
    ],
    child: MaterialApp(
      home: Scaffold(body: TransactionListTile(transaction: transaction, categoriesById: const {})),
    ),
  );

  testWidgets('a junk transaction shows the warning badge and edit/delete actions', (tester) async {
    await tester.pumpWidget(buildApp(_junkTransaction));
    await _pumpBounded(tester);

    expect(find.text("Couldn't read slip data"), findsOneWidget);
    expect(find.byKey(const Key('junkEditButton')), findsOneWidget);
    expect(find.byKey(const Key('junkDeleteButton')), findsOneWidget);
  });

  testWidgets('a normal (non-junk) transaction shows neither the badge nor the junk actions', (tester) async {
    await tester.pumpWidget(buildApp(_editedTransaction));
    await _pumpBounded(tester);

    expect(find.text("Couldn't read slip data"), findsNothing);
    expect(find.byKey(const Key('junkEditButton')), findsNothing);
    expect(find.byKey(const Key('junkDeleteButton')), findsNothing);
  });

  testWidgets('tapping the edit action opens T6\'s full edit form prefilled with this transaction', (tester) async {
    await tester.pumpWidget(buildApp(_junkTransaction));
    await _pumpBounded(tester);

    await tester.tap(find.byKey(const Key('junkEditButton')));
    await _pumpBounded(tester);

    final formFinder = find.byType(TransactionFormPage);
    expect(formFinder, findsOneWidget);
    final form = tester.widget<TransactionFormPage>(formFinder);
    expect(form.initial?.id, _junkTransaction.id);
    expect(form.isEditing, isTrue);
  });

  testWidgets('tapping delete then confirming calls the repository; canceling does not', (tester) async {
    await tester.pumpWidget(buildApp(_junkTransaction));
    await _pumpBounded(tester);

    await tester.tap(find.byKey(const Key('junkDeleteButton')));
    await _pumpBounded(tester);
    expect(find.text('Delete transaction?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await _pumpBounded(tester);
    expect(fakeTransactions.deleteCalls, isEmpty);

    await tester.tap(find.byKey(const Key('junkDeleteButton')));
    await _pumpBounded(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await _pumpBounded(tester);

    expect(fakeTransactions.deleteCalls, [_junkTransaction.id]);
  });

  testWidgets('a failed delete shows an error and never crashes the tile', (tester) async {
    fakeTransactions.deleteResult = const Left(UnknownFailure(message: 'Could not delete transaction'));
    await tester.pumpWidget(buildApp(_junkTransaction));
    await _pumpBounded(tester);

    await tester.tap(find.byKey(const Key('junkDeleteButton')));
    await _pumpBounded(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await _pumpBounded(tester);

    expect(fakeTransactions.deleteCalls, [_junkTransaction.id]);
    expect(find.text('Could not delete transaction'), findsOneWidget);
    // Still junk (delete failed) — badge stays visible.
    expect(find.text("Couldn't read slip data"), findsOneWidget);
  });

  group('T13 pending-actions queue', () {
    testWidgets('a transient delete failure gets queued and shows the retry-queue snackbar', (tester) async {
      fakeTransactions.deleteResult = const Left(TimeoutFailure());
      await tester.pumpWidget(buildApp(_junkTransaction));
      await _pumpBounded(tester);

      await tester.tap(find.byKey(const Key('junkDeleteButton')));
      await _pumpBounded(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await _pumpBounded(tester);

      expect(find.text('No connection — saved to the retry queue'), findsOneWidget);
      final queued = await pendingActions.watchAll().first;
      expect(queued, hasLength(1));
      expect(queued.single.actionType, PendingActionType.deleteTransaction);
      expect(queued.single.targetTransactionId, _junkTransaction.id);
    });

    testWidgets('a permanent delete failure is not queued — snackbar only, same as before this ticket', (tester) async {
      fakeTransactions.deleteResult = const Left(UnknownFailure(message: 'Could not delete transaction'));
      await tester.pumpWidget(buildApp(_junkTransaction));
      await _pumpBounded(tester);

      await tester.tap(find.byKey(const Key('junkDeleteButton')));
      await _pumpBounded(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await _pumpBounded(tester);

      expect(find.text('Could not delete transaction'), findsOneWidget);
      expect(await pendingActions.watchAll().first, isEmpty);
    });
  });
}

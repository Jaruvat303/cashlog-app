// Both repositories this page touches are faked (per CLAUDE.md's testing
// rule) — TransactionsRepository so a real dio call never reaches Flutter's
// test HTTP stub, and PendingActionsRepository because a *real* drift-backed
// instance inside a testWidgets test hits a known drift/flutter_test
// interaction: cancelling a live `.watch()` stream subscription during
// widget-tree disposal schedules a zero-duration Timer
// (`StreamQueryStore.markAsClosed`) that never gets a chance to fire before
// the test framework's post-test "no pending timers" check runs, hanging or
// failing every such test (see https://github.com/simolus3/drift/issues/3323
// — confirmed against this exact failure during T13 verification). Every
// other repository fake in this codebase already avoids real drift/dio for
// the same reason; this fake keeps PendingActionsRepository consistent with
// that convention rather than being the one exception.
import 'dart:async';

import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/transactions/data/pending_action_mapper.dart';
import 'package:cashlog/features/transactions/data/pending_actions_repository.dart';
import 'package:cashlog/features/transactions/data/transactions_repository.dart';
import 'package:cashlog/features/transactions/domain/pending_action.dart';
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:cashlog/features/transactions/domain/transaction_page.dart';
import 'package:cashlog/features/transactions/presentation/pages/pending_actions_page.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTransactionsRepository implements TransactionsRepository {
  final List<int> deleteCalls = [];
  Either<Failure, void> deleteResult = const Right(null);

  @override
  Stream<List<Transaction>> watchMonth({required int year, required int month}) => throw UnimplementedError('not exercised by this page test');

  @override
  Future<Either<Failure, TransactionPage>> fetchPage({required int year, required int month, required int page, int limit = 20}) =>
      throw UnimplementedError('not exercised by this page test');

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
  }) => throw UnimplementedError('not exercised by this page test');

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
  }) => throw UnimplementedError('not exercised by this page test');

  @override
  Future<Either<Failure, void>> delete(int id) async {
    deleteCalls.add(id);
    return deleteResult;
  }
}

/// In-memory stand-in with the same public behavior as the real repository
/// (including the real transient-vs-permanent policy check, which the real
/// `recordIfTransient` also enforces — covered independently and against a
/// real drift db by pending_actions_repository_test.dart, a plain test()
/// file unaffected by the FakeAsync/drift interaction above).
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
  Future<void> recordRetryFailure(int id, String? errorCode) async {
    final index = _items.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final existing = _items[index];
    _items[index] = PendingAction(
      id: existing.id,
      actionType: existing.actionType,
      payload: existing.payload,
      targetTransactionId: existing.targetTransactionId,
      createdAt: existing.createdAt,
      retryCount: existing.retryCount + 1,
      lastErrorCode: errorCode,
    );
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Future<void> remove(int id) async {
    _items.removeWhere((a) => a.id == id);
    _controller.add(List.unmodifiable(_items));
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

void main() {
  late _FakeTransactionsRepository fakeTransactions;
  late _FakePendingActionsRepository pendingActions;

  setUp(() {
    fakeTransactions = _FakeTransactionsRepository();
    pendingActions = _FakePendingActionsRepository();
  });

  Future<int> seedDeleteAction() async {
    await pendingActions.recordIfTransient(
      failure: const TimeoutFailure(),
      actionType: PendingActionType.deleteTransaction,
      payload: deleteTransactionPayload(date: DateTime.utc(2026, 9, 5)),
      targetTransactionId: 42,
    );
    return (await pendingActions.watchAll().first).single.id;
  }

  Widget buildApp() => ProviderScope(
    overrides: [
      transactionsRepositoryProvider.overrideWithValue(fakeTransactions),
      pendingActionsRepositoryProvider.overrideWithValue(pendingActions),
    ],
    child: const MaterialApp(home: PendingActionsPage()),
  );

  testWidgets('renders a queued row with its action label and retry count', (tester) async {
    await seedDeleteAction();

    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);

    expect(find.text('Delete transaction'), findsOneWidget);
    expect(find.textContaining('Retries: 0'), findsOneWidget);
    expect(find.textContaining('Last error: DATABASE_TIMEOUT'), findsOneWidget);
  });

  testWidgets('shows the empty state once the queue is empty', (tester) async {
    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);

    expect(find.text('No stuck items'), findsOneWidget);
  });

  testWidgets('tapping retry on a row that now succeeds removes it from the queue', (tester) async {
    final id = await seedDeleteAction();
    fakeTransactions.deleteResult = const Right(null);

    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);

    await tester.tap(find.byKey(Key('retryButton_$id')));
    await _pumpBounded(tester);

    expect(fakeTransactions.deleteCalls, [42]);
    expect(find.text('Retried successfully'), findsOneWidget);
    expect(find.text('No stuck items'), findsOneWidget);
    expect(await pendingActions.watchAll().first, isEmpty);
  });

  testWidgets('tapping retry on a row that fails again keeps it queued with an updated retry count', (tester) async {
    final id = await seedDeleteAction();
    fakeTransactions.deleteResult = const Left(AccountInactiveFailure(message: 'Account is inactive'));

    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);

    await tester.tap(find.byKey(Key('retryButton_$id')));
    await _pumpBounded(tester);

    expect(fakeTransactions.deleteCalls, [42]);
    expect(find.text('Account is inactive'), findsOneWidget);
    final rows = await pendingActions.watchAll().first;
    expect(rows, hasLength(1));
    expect(rows.single.retryCount, 1);
    expect(rows.single.lastErrorCode, 'ACCOUNT_INACTIVE');
  });

  testWidgets('dismiss removes the row without ever calling the repository', (tester) async {
    final id = await seedDeleteAction();

    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);

    await tester.tap(find.byKey(Key('dismissButton_$id')));
    await _pumpBounded(tester);
    expect(find.text('Discard this item?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await _pumpBounded(tester);
    expect(await pendingActions.watchAll().first, hasLength(1), reason: 'canceling the dialog must not discard the row');

    await tester.tap(find.byKey(Key('dismissButton_$id')));
    await _pumpBounded(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Discard'));
    await _pumpBounded(tester);

    expect(fakeTransactions.deleteCalls, isEmpty);
    expect(await pendingActions.watchAll().first, isEmpty);
    expect(find.text('No stuck items'), findsOneWidget);
  });
}

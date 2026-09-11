// This file exists to close a gap: every other T13 test exercises either the
// queue mechanics (pending_actions_repository_test.dart — a real drift db,
// but a plain test(), never through the actual form/tile widgets) or the UI
// (transaction_form_page_test.dart/transaction_list_tile_test.dart/
// pending_actions_page_test.dart — the actual widgets, but always against
// _FakePendingActionsRepository, never a real drift-backed one). Nothing
// before this file drove a real transient TransactionsRepository failure
// through the real TransactionFormPage/TransactionListTile call sites into a
// real pending_manual_actions row, rendered that real row back out through
// the real PendingActionsPage, or retried it against a real
// TransactionsRepository.
//
// The PendingActionsPage groups below mount it against a real, drift-backed
// PendingActionsRepository — i.e. with a live `ref.watch(pendingActionsProvider)`
// subscription, the exact shape CLAUDE.md's Stream.multi() note and this
// file's earlier revision both document as fatal under plain testWidgets
// (drift/testWidgets#3323: a zero-duration Timer scheduled on stream-watcher
// cancellation never gets flushed inside the FakeAsync zone testWidgets
// wraps the test body in, hanging silently until the 10-minute per-test
// timeout). Wrapping the mount/interact/dispose sequence in
// `tester.runAsync()` — including an explicit `pumpWidget(SizedBox.shrink())`
// before the callback returns, so disposal happens inside runAsync's real
// zone rather than being left to the framework's automatic post-test
// teardown — resolved it. Confirmed non-vacuous by deliberately breaking
// each assertion once and checking it actually fails (not just always
// passing regardless of real state).
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cashlog/core/db/app_database.dart';
import 'package:cashlog/core/network/api_client.dart';
import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/accounts/data/accounts_repository.dart';
import 'package:cashlog/features/accounts/domain/account.dart';
import 'package:cashlog/features/categories/data/categories_repository.dart';
import 'package:cashlog/features/categories/domain/category.dart';
import 'package:cashlog/features/transactions/data/pending_actions_repository.dart';
import 'package:cashlog/features/transactions/data/transactions_repository.dart';
import 'package:cashlog/features/transactions/domain/pending_action.dart';
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:cashlog/features/transactions/domain/transaction_page.dart';
import 'package:cashlog/features/transactions/presentation/pages/pending_actions_page.dart';
import 'package:cashlog/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:cashlog/features/transactions/presentation/widgets/transaction_list_tile.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAccountsRepository implements AccountsRepository {
  @override
  Stream<List<Account>> watchActiveAccounts() => Stream.value(const [
    Account(id: 1, name: 'Cash', accountType: AccountType.cash, openingBalance: 0, matchingKeywords: [], bankIcon: 'cash', isActive: true),
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
  }) => throw UnimplementedError('not exercised by this wiring test');

  @override
  Future<Either<Failure, Account>> update(
    int id, {
    required String name,
    required AccountType accountType,
    required List<String> matchingKeywords,
    required String bankIcon,
  }) => throw UnimplementedError('not exercised by this wiring test');

  @override
  Future<Either<Failure, void>> close(int id) => throw UnimplementedError('not exercised by this wiring test');
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
  }) => throw UnimplementedError('not exercised by this wiring test');

  @override
  Future<Either<Failure, Category>> update(
    int id, {
    required String name,
    required CategoryType type,
    required String iconKey,
    required String colorHex,
  }) => throw UnimplementedError('not exercised by this wiring test');

  @override
  Future<int> countLinkedTransactions(int categoryId) => throw UnimplementedError('not exercised by this wiring test');

  @override
  Future<Either<Failure, void>> delete(int id) => throw UnimplementedError('not exercised by this wiring test');
}

/// [nextCreateResult]/[nextDeleteResult] force a real `Left` through the
/// real form/tile submit paths — same technique as
/// transaction_form_page_test.dart's `nextCreateResult`/
/// transaction_list_tile_test.dart's `deleteResult`, just consolidated into
/// one fake since this file drives both call sites.
class _FakeTransactionsRepository implements TransactionsRepository {
  Either<Failure, Transaction>? nextCreateResult;
  Either<Failure, void>? nextDeleteResult;

  @override
  Stream<List<Transaction>> watchMonth({required int year, required int month}) =>
      throw UnimplementedError('not exercised by this wiring test');

  @override
  Future<Either<Failure, TransactionPage>> fetchPage({required int year, required int month, required int page, int limit = 20}) =>
      throw UnimplementedError('not exercised by this wiring test');

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
  }) async =>
      nextCreateResult ??
      Right(
        Transaction(
          id: 1,
          amount: amount,
          type: type,
          accountId: accountId,
          source: 'manual',
          transactionDate: date,
        ),
      );

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
  }) => throw UnimplementedError('not exercised by this wiring test');

  @override
  Future<Either<Failure, void>> delete(int id) async => nextDeleteResult ?? const Right(null);
}

/// Same shape as pending_actions_repository_test.dart's `_FakeSuccessAdapter`
/// — only the transport is faked; `ApiClient`/`TransactionsRepository`'s own
/// request-building, response-parsing, and drift upsert all run for real.
class _FakeSuccessHttpAdapter implements HttpClientAdapter {
  _FakeSuccessHttpAdapter(this._nextId);
  int _nextId;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final sentBody = options.data is Map ? Map<String, dynamic>.from(options.data as Map) : <String, dynamic>{};
    return ResponseBody.fromString(
      jsonEncode({
        'data': {'id': _nextId++, 'transaction_type': sentBody['transaction_type'], ...sentBody, 'category': null},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

final _junkTransaction = Transaction(
  id: 7,
  amount: 0,
  type: TransactionType.expense,
  source: 'slip',
  transactionDate: DateTime.utc(2026, 9, 5),
  isJunk: true,
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
  late AppDatabase db;
  late PendingActionsRepository realPendingActions;
  late _FakeTransactionsRepository fakeTransactions;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    realPendingActions = PendingActionsRepository(db);
    fakeTransactions = _FakeTransactionsRepository();
  });

  tearDown(() async {
    await db.close();
  });

  group('form/tile call sites against a real PendingActionsRepository (one-shot insert only — no live .watch(), so the drift/testWidgets teardown hang this codebase avoids elsewhere does not apply)', () {
    testWidgets('a real transient create failure lands a real row in pending_manual_actions', (tester) async {
      fakeTransactions.nextCreateResult = const Left(TimeoutFailure());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountsRepositoryProvider.overrideWithValue(_FakeAccountsRepository()),
            categoriesRepositoryProvider.overrideWithValue(_FakeCategoriesRepository()),
            transactionsRepositoryProvider.overrideWithValue(fakeTransactions),
            pendingActionsRepositoryProvider.overrideWithValue(realPendingActions),
          ],
          child: const MaterialApp(home: TransactionFormPage()),
        ),
      );
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

      expect(find.text('No connection — saved to the retry queue'), findsOneWidget);
      // A blocked/failed submit never pops.
      expect(find.byType(TransactionFormPage), findsOneWidget);

      final rows = await db.select(db.pendingManualActions).get();
      expect(rows, hasLength(1), reason: 'expected exactly one real row inserted via the real repository, found: $rows');
      expect(rows.single.actionType, 'create_transaction');
      expect(rows.single.lastErrorCode, 'DATABASE_TIMEOUT');
    });

    testWidgets('a real transient delete failure lands a real row in pending_manual_actions', (tester) async {
      fakeTransactions.nextDeleteResult = const Left(TimeoutFailure());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountsRepositoryProvider.overrideWithValue(_FakeAccountsRepository()),
            categoriesRepositoryProvider.overrideWithValue(_FakeCategoriesRepository()),
            transactionsRepositoryProvider.overrideWithValue(fakeTransactions),
            pendingActionsRepositoryProvider.overrideWithValue(realPendingActions),
          ],
          child: MaterialApp(home: Scaffold(body: TransactionListTile(transaction: _junkTransaction, categoriesById: const {}))),
        ),
      );
      await _pumpBounded(tester);

      await tester.tap(find.byKey(const Key('junkDeleteButton')));
      await _pumpBounded(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await _pumpBounded(tester);

      expect(find.text('No connection — saved to the retry queue'), findsOneWidget);

      final rows = await db.select(db.pendingManualActions).get();
      expect(rows, hasLength(1), reason: 'expected exactly one real row inserted via the real repository, found: $rows');
      expect(rows.single.actionType, 'delete_transaction');
      expect(rows.single.targetTransactionId, 7);
    });
  });

  group('PendingActionsPage against a real PendingActionsRepository (live .watch() — the exact case CLAUDE.md documents as a drift/testWidgets teardown hang, avoided everywhere else in this codebase)', () {
    // Attempt: run the whole real-DB mount/interact/dispose sequence inside
    // tester.runAsync() so the live .watch() subscription's real Timers
    // (including whatever fires on cancellation at teardown) run against the
    // real event loop instead of being captured, unflushed, by the
    // FakeAsync zone testWidgets normally wraps the test body in.
    testWidgets('a real queued row renders in the real page and a working retry clears it', (tester) async {
      await realPendingActions.recordIfTransient(
        failure: const TimeoutFailure(),
        actionType: PendingActionType.deleteTransaction,
        payload: deleteTransactionPayload(date: DateTime.utc(2026, 9, 5)),
        targetTransactionId: 7,
      );
      // The retry itself should now succeed, so this also exercises the
      // remove-on-success path against the real db.
      fakeTransactions.nextDeleteResult = const Right(null);

      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              transactionsRepositoryProvider.overrideWithValue(fakeTransactions),
              pendingActionsRepositoryProvider.overrideWithValue(realPendingActions),
            ],
            child: const MaterialApp(home: PendingActionsPage()),
          ),
        );
        await _pumpBounded(tester);

        expect(find.text('Delete transaction'), findsOneWidget);
        final row = (await db.select(db.pendingManualActions).get()).single;

        await tester.tap(find.byKey(Key('retryButton_${row.id}')));
        await _pumpBounded(tester);

        expect(find.text('Retried successfully'), findsOneWidget);
        expect(await db.select(db.pendingManualActions).get(), isEmpty);

        // Force disposal (and therefore stream-subscription cancellation)
        // to happen here, inside runAsync's real zone, rather than leaving
        // it to the test framework's automatic post-test teardown — which
        // runs back in the FakeAsync zone this runAsync block is trying to
        // avoid.
        await tester.pumpWidget(const SizedBox.shrink());
      });
    });
  });

  group('PendingActionsPage retry against a real TransactionsRepository (not just a hand-written fake acknowledging success)', () {
    testWidgets('tapping retry actually calls through ApiClient/TransactionsRepository and upserts a real cached_transactions row', (
      tester,
    ) async {
      final realTransactions = TransactionsRepository(ApiClient(Dio()..httpClientAdapter = _FakeSuccessHttpAdapter(1)), db);
      await realPendingActions.recordIfTransient(
        failure: const TimeoutFailure(),
        actionType: PendingActionType.createTransaction,
        payload: createTransactionPayload(type: TransactionType.income, amount: 100, date: DateTime.utc(2026, 9, 5), accountId: 3),
      );

      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              transactionsRepositoryProvider.overrideWithValue(realTransactions),
              pendingActionsRepositoryProvider.overrideWithValue(realPendingActions),
            ],
            child: const MaterialApp(home: PendingActionsPage()),
          ),
        );
        await _pumpBounded(tester);

        expect(find.text('Create transaction'), findsOneWidget);
        final row = (await db.select(db.pendingManualActions).get()).single;

        await tester.tap(find.byKey(Key('retryButton_${row.id}')));
        await _pumpBounded(tester);
        // Dio 5's BackgroundTransformer decodes JSON via compute() — a real
        // isolate spawn — so this retry (unlike the fake-repository retry
        // above) needs real wall-clock time to finish, not just pumped
        // frames. _pumpBounded's 500ms budget alone left the row
        // unretried (confirmed by instrumenting this during T13 follow-up
        // verification); a real delay closes that gap.
        await Future<void>.delayed(const Duration(seconds: 2));
        await _pumpBounded(tester);

        expect(find.text('Retried successfully'), findsOneWidget);
        expect(await db.select(db.pendingManualActions).get(), isEmpty, reason: 'a real successful retry must remove the queued row');

        final cached = await db.select(db.cachedTransactions).get();
        expect(cached, hasLength(1), reason: 'proves the retry went through the real TransactionsRepository.create, not a stand-in');
        expect(cached.single.transactionType, 'income');

        await tester.pumpWidget(const SizedBox.shrink());
      });
    });
  });
}

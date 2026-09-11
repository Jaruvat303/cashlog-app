// Same fake-HttpClientAdapter + in-memory drift pattern as
// transactions_repository_test.dart — used here only for [retryPendingAction]'s
// tests, which need a real TransactionsRepository to re-call.
import 'dart:convert';
import 'dart:typed_data';

import 'package:cashlog/core/db/app_database.dart';
import 'package:cashlog/core/network/api_client.dart';
import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/transactions/data/pending_actions_repository.dart';
import 'package:cashlog/features/transactions/data/transactions_repository.dart';
import 'package:cashlog/features/transactions/domain/pending_action.dart';
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSuccessAdapter implements HttpClientAdapter {
  _FakeSuccessAdapter(this._nextId);
  int _nextId;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (options.method == 'DELETE') {
      return ResponseBody.fromString(
        jsonEncode({'success': true}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    final sentBody = options.data is Map ? Map<String, dynamic>.from(options.data as Map) : <String, dynamic>{};
    final isTransfer = options.path.endsWith('/transfer');
    return ResponseBody.fromString(
      jsonEncode({
        'data': {
          'id': _nextId++,
          'transaction_type': isTransfer ? 'transfer' : sentBody['transaction_type'],
          ...sentBody,
          'category': null,
        },
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

class _FakeFailingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    return ResponseBody.fromString(jsonEncode({'success': false, 'message': 'account inactive'}), 400);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late AppDatabase db;
  late PendingActionsRepository repository;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    repository = PendingActionsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('recordIfTransient', () {
    test('a transient failure queues a row with the given actionType/payload/targetTransactionId', () async {
      final queued = await repository.recordIfTransient(
        failure: const TimeoutFailure(),
        actionType: PendingActionType.deleteTransaction,
        payload: deleteTransactionPayload(date: DateTime.utc(2026, 9, 5)),
        targetTransactionId: 42,
      );

      expect(queued, isTrue);
      final rows = await repository.watchAll().first;
      expect(rows, hasLength(1));
      expect(rows.single.actionType, PendingActionType.deleteTransaction);
      expect(rows.single.targetTransactionId, 42);
      expect(rows.single.retryCount, 0);
      expect(rows.single.lastErrorCode, 'DATABASE_TIMEOUT');
      expect(readDeleteTransactionPayload(rows.single.payload).date, DateTime.utc(2026, 9, 5));
    });

    test('a permanent failure queues nothing', () async {
      final queued = await repository.recordIfTransient(
        failure: const InvalidInputFailure(),
        actionType: PendingActionType.deleteTransaction,
        payload: deleteTransactionPayload(date: DateTime.utc(2026, 9, 5)),
        targetTransactionId: 42,
      );

      expect(queued, isFalse);
      expect(await repository.watchAll().first, isEmpty);
    });
  });

  test('recordRetryFailure bumps retryCount/lastErrorCode on the same row, never a new insert', () async {
    await repository.recordIfTransient(
      failure: const TimeoutFailure(),
      actionType: PendingActionType.deleteTransaction,
      payload: deleteTransactionPayload(date: DateTime.utc(2026, 9, 5)),
      targetTransactionId: 42,
    );
    final originalId = (await repository.watchAll().first).single.id;

    await repository.recordRetryFailure(originalId, 'ACCOUNT_INACTIVE');

    final rows = await repository.watchAll().first;
    expect(rows, hasLength(1), reason: 'a retry failure must update the existing row, never insert a second one');
    expect(rows.single.id, originalId, reason: 'bound to the same stable id through repeated retries — never rebound to a new row');
    expect(rows.single.retryCount, 1);
    expect(rows.single.lastErrorCode, 'ACCOUNT_INACTIVE');
  });

  test('remove deletes the row', () async {
    await repository.recordIfTransient(
      failure: const TimeoutFailure(),
      actionType: PendingActionType.deleteTransaction,
      payload: deleteTransactionPayload(date: DateTime.utc(2026, 9, 5)),
      targetTransactionId: 42,
    );
    final id = (await repository.watchAll().first).single.id;

    await repository.remove(id);

    expect(await repository.watchAll().first, isEmpty);
  });

  test('watchAll orders oldest-stuck-first', () async {
    await db
        .into(db.pendingManualActions)
        .insert(
          PendingManualActionsCompanion.insert(
            actionType: 'delete_transaction',
            payloadJson: jsonEncode(deleteTransactionPayload(date: DateTime.utc(2026, 9, 5))),
            targetTransactionId: const Value(2),
            createdAt: DateTime.utc(2026, 9, 5, 12),
          ),
        );
    await db
        .into(db.pendingManualActions)
        .insert(
          PendingManualActionsCompanion.insert(
            actionType: 'delete_transaction',
            payloadJson: jsonEncode(deleteTransactionPayload(date: DateTime.utc(2026, 9, 1))),
            targetTransactionId: const Value(1),
            createdAt: DateTime.utc(2026, 9, 5, 8),
          ),
        );

    final rows = await repository.watchAll().first;
    expect(rows.map((r) => r.targetTransactionId).toList(), [1, 2]);
  });

  group('retryPendingAction', () {
    test('on success, removes the row and upserts into cached_transactions via the real repository call', () async {
      final adapter = _FakeSuccessAdapter(1);
      final transactionsRepo = TransactionsRepository(ApiClient(Dio()..httpClientAdapter = adapter), db);
      await repository.recordIfTransient(
        failure: const TimeoutFailure(),
        actionType: PendingActionType.createTransaction,
        payload: createTransactionPayload(type: TransactionType.income, amount: 100, date: DateTime.utc(2026, 9, 5), accountId: 3),
      );
      final action = (await repository.watchAll().first).single;

      final result = await retryPendingAction(transactionsRepo, repository, action);

      expect(result.isRight(), isTrue, reason: 'expected success, got: ${result.fold((f) => f, (_) => null)}');
      expect(await repository.watchAll().first, isEmpty);
      final cached = await db.select(db.cachedTransactions).get();
      expect(cached, hasLength(1));
      expect(cached.single.transactionType, 'income');
    });

    test('on failure, keeps the row and bumps retryCount/lastErrorCode with the new failure', () async {
      final adapter = _FakeFailingAdapter();
      final transactionsRepo = TransactionsRepository(ApiClient(Dio()..httpClientAdapter = adapter), db);
      await repository.recordIfTransient(
        failure: const TimeoutFailure(),
        actionType: PendingActionType.deleteTransaction,
        payload: deleteTransactionPayload(date: DateTime.utc(2026, 9, 5)),
        targetTransactionId: 42,
      );
      final action = (await repository.watchAll().first).single;

      final result = await retryPendingAction(transactionsRepo, repository, action);

      expect(result.isLeft(), isTrue);
      final rows = await repository.watchAll().first;
      expect(rows, hasLength(1));
      expect(rows.single.id, action.id);
      expect(rows.single.retryCount, 1);
    });
  });
}

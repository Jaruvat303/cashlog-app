import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/failure.dart';
import '../domain/pending_action.dart';
import '../domain/transaction.dart';
import 'pending_action_mapper.dart';
import 'transactions_repository.dart';

part 'pending_actions_repository.g.dart';

/// T13's retry queue — a lightweight "stuck, tap to retry" safety net for a
/// T6 create/update/delete that failed transiently (CLAUDE.md/spec §9),
/// explicitly not a full sync engine: no background retry, no
/// reconnect-triggered retry, user-initiated only.
class PendingActionsRepository {
  PendingActionsRepository(this._db);

  final AppDatabase _db;

  /// Oldest-stuck-first, so the queue reads top-to-bottom in the order these
  /// attempts were originally made.
  Stream<List<PendingAction>> watchAll() =>
      (_db.select(_db.pendingManualActions)..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch()
          .map((rows) => rows.map(pendingActionFromRow).toList());

  /// The single decision point for "does this failure get queued at all" —
  /// only `RetryPolicy.transient` failures do (permanent ones would just fail
  /// the same way again on an identical-payload retry, so queuing them would
  /// only be clutter). Both `TransactionFormPage` and `TransactionListTile`
  /// call this same method so the policy can never drift out of sync between
  /// the two call sites. Returns whether it queued, so the caller knows which
  /// snackbar copy to show.
  Future<bool> recordIfTransient({
    required Failure failure,
    required PendingActionType actionType,
    required Map<String, dynamic> payload,
    int? targetTransactionId,
  }) async {
    if (failure.retryPolicy != RetryPolicy.transient) return false;
    await _db
        .into(_db.pendingManualActions)
        .insert(
          PendingManualActionsCompanion.insert(
            actionType: actionType.toWire(),
            payloadJson: jsonEncode(payload),
            targetTransactionId: Value(targetTransactionId),
            createdAt: DateTime.now(),
            lastErrorCode: Value(errorTagForFailure(failure)),
          ),
        );
    return true;
  }

  /// Bumps `retryCount`/`lastErrorCode` on the *same* row — never a new
  /// insert. This is what keeps a queued item bound to one stable id through
  /// repeated retries, the same discipline T12 already applies to junk-row
  /// edit/delete (bind to the real record, never to list position).
  Future<void> recordRetryFailure(int id, String? errorCode) async {
    final row = await (_db.select(_db.pendingManualActions)..where((t) => t.id.equals(id))).getSingle();
    await (_db.update(_db.pendingManualActions)..where(
      (t) => t.id.equals(id),
    )).write(PendingManualActionsCompanion(retryCount: Value(row.retryCount + 1), lastErrorCode: Value(errorCode)));
  }

  /// Used both after a successful retry and for the user-initiated dismiss
  /// action.
  Future<void> remove(int id) async {
    await (_db.delete(_db.pendingManualActions)..where((t) => t.id.equals(id))).go();
  }
}

@riverpod
PendingActionsRepository pendingActionsRepository(Ref ref) => PendingActionsRepository(ref.watch(appDatabaseProvider));

/// Decodes [action]'s payload per its `actionType` and re-calls the matching
/// `TransactionsRepository` method with the exact args snapshotted at the
/// moment of the original failure — never re-derived from live form state.
Future<Either<Failure, void>> retryPendingAction(
  TransactionsRepository transactionsRepo,
  PendingActionsRepository pendingRepo,
  PendingAction action,
) {
  return switch (action.actionType) {
    PendingActionType.createTransaction => _retryCreateTransaction(transactionsRepo, pendingRepo, action),
    PendingActionType.createTransfer => _retryCreateTransfer(transactionsRepo, pendingRepo, action),
    PendingActionType.updateTransaction => _retryUpdateTransaction(transactionsRepo, pendingRepo, action),
    PendingActionType.deleteTransaction => _retryDelete(transactionsRepo, pendingRepo, action),
  };
}

Future<Either<Failure, void>> _retryCreateTransaction(
  TransactionsRepository transactionsRepo,
  PendingActionsRepository pendingRepo,
  PendingAction action,
) async {
  final args = readCreateTransactionPayload(action.payload);
  final result = await transactionsRepo.create(
    type: args.type,
    amount: args.amount,
    date: args.date,
    note: args.note,
    accountId: args.accountId,
    categoryId: args.categoryId,
  );
  return _finish(pendingRepo, action, result);
}

Future<Either<Failure, void>> _retryCreateTransfer(
  TransactionsRepository transactionsRepo,
  PendingActionsRepository pendingRepo,
  PendingAction action,
) async {
  final args = readCreateTransferPayload(action.payload);
  final result = await transactionsRepo.create(
    type: TransactionType.transfer,
    amount: args.amount,
    date: args.date,
    note: args.note,
    fromAccountId: args.fromAccountId,
    toAccountId: args.toAccountId,
    categoryId: args.categoryId,
  );
  return _finish(pendingRepo, action, result);
}

Future<Either<Failure, void>> _retryUpdateTransaction(
  TransactionsRepository transactionsRepo,
  PendingActionsRepository pendingRepo,
  PendingAction action,
) async {
  final args = readUpdateTransactionPayload(action.payload);
  final result = await transactionsRepo.update(
    action.targetTransactionId!,
    type: args.type,
    amount: args.amount,
    date: args.date,
    note: args.note,
    accountId: args.accountId,
    fromAccountId: args.fromAccountId,
    toAccountId: args.toAccountId,
    categoryId: args.categoryId,
  );
  return _finish(pendingRepo, action, result);
}

Future<Either<Failure, void>> _retryDelete(
  TransactionsRepository transactionsRepo,
  PendingActionsRepository pendingRepo,
  PendingAction action,
) async {
  final result = await transactionsRepo.delete(action.targetTransactionId!);
  return _finish(pendingRepo, action, result);
}

/// Shared success/failure bookkeeping for every retry path above, regardless
/// of what `T` the underlying repository call returns (`Transaction` for
/// create/update, `void` for delete): on success the row is deleted from the
/// queue; on failure — transient again, or a *different* permanent error if
/// something changed server-side since queuing (e.g. the account got
/// deactivated in the meantime) — `retryCount`/`lastErrorCode` are updated in
/// place and the row stays queued, unconditionally. This stays this simple
/// deliberately: retry is user-initiated only (no background process needs a
/// "stop retrying" signal), and the already-separate dismiss action is the
/// user's own way to declare a row dead and remove it — adding an automatic
/// "permanent failure → different state" transition would be a second,
/// redundant way to reach the same outcome.
Future<Either<Failure, void>> _finish<T>(PendingActionsRepository pendingRepo, PendingAction action, Either<Failure, T> result) async {
  final failure = result.fold<Failure?>((l) => l, (_) => null);
  if (failure != null) {
    await pendingRepo.recordRetryFailure(action.id, errorTagForFailure(failure));
    return Left(failure);
  }
  await pendingRepo.remove(action.id);
  return const Right(null);
}

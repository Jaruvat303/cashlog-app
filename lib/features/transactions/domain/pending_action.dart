import 'transaction.dart';

/// Spec §8's exact documented wire strings for `PendingManualActions.actionType`
/// — create is split into two values (matching `TransactionsRepository.create`
/// itself branching by type into two backend endpoints), not one generic
/// "create" value.
enum PendingActionType { createTransaction, createTransfer, updateTransaction, deleteTransaction }

extension PendingActionTypeWire on PendingActionType {
  String toWire() => switch (this) {
    PendingActionType.createTransaction => 'create_transaction',
    PendingActionType.createTransfer => 'create_transfer',
    PendingActionType.updateTransaction => 'update_transaction',
    PendingActionType.deleteTransaction => 'delete_transaction',
  };
}

/// Unlike `transactionTypeFromWire` (which defends against an unfamiliar
/// *backend* value with a fallback), this has none — `payloadJson`/`actionType`
/// are 100% client-written and client-read, never off the wire, so a decode
/// mismatch here would be a real local bug, not something to silently paper
/// over.
PendingActionType pendingActionTypeFromWire(String value) => PendingActionType.values.firstWhere((type) => type.toWire() == value);

/// One row from `pending_manual_actions` — a T6 create/update/delete that
/// failed with a transient error (CLAUDE.md/spec §9) and is now waiting for a
/// user-initiated retry. [payload] is decoded per [actionType] at retry time,
/// same loosely-typed-map style `transaction_mapper.dart` already uses for
/// backend JSON.
///
/// Named `PendingAction`, not `PendingManualAction` — the latter is drift's
/// own generated row class for the `PendingManualActions` table
/// (`app_database.g.dart`), and this repository/domain layer needs both types
/// in scope at once, same "drop the table-name prefix" convention
/// `CachedTransactions` → `Transaction` already uses.
class PendingAction {
  const PendingAction({
    required this.id,
    required this.actionType,
    required this.payload,
    this.targetTransactionId,
    required this.createdAt,
    this.retryCount = 0,
    this.lastErrorCode,
  });

  final int id;
  final PendingActionType actionType;
  final Map<String, dynamic> payload;
  final int? targetTransactionId;
  final DateTime createdAt;
  final int retryCount;
  final String? lastErrorCode;
}

/// Deliberately camelCase, matching `Transaction`/repository-method field
/// names 1:1 — this JSON never touches HTTP (it only round-trips through
/// `payloadJson` back into a `TransactionsRepository.create/update/delete`
/// call), so mirroring the backend's snake_case wire format would just be a
/// confusing red herring when reading raw rows during debugging.
Map<String, dynamic> createTransactionPayload({
  required TransactionType type,
  required double amount,
  required DateTime date,
  String? note,
  required int accountId,
  int? categoryId,
}) => {
  'type': type.name,
  'amount': amount,
  'date': date.toUtc().toIso8601String(),
  'note': ?note,
  'accountId': accountId,
  'categoryId': ?categoryId,
};

Map<String, dynamic> createTransferPayload({
  required double amount,
  required DateTime date,
  String? note,
  required int fromAccountId,
  required int toAccountId,
  int? categoryId,
}) => {
  'amount': amount,
  'date': date.toUtc().toIso8601String(),
  'note': ?note,
  'fromAccountId': fromAccountId,
  'toAccountId': toAccountId,
  'categoryId': ?categoryId,
};

/// `originalDate` is the transaction's date *before* this edit — needed so a
/// retried edit that crossed a month boundary can still invalidate both
/// months on retry, mirroring `TransactionFormPage._invalidateAffectedDashboardMonths`.
Map<String, dynamic> updateTransactionPayload({
  required TransactionType type,
  required double amount,
  required DateTime date,
  String? note,
  int? accountId,
  int? fromAccountId,
  int? toAccountId,
  int? categoryId,
  required DateTime originalDate,
}) => {
  'type': type.name,
  'amount': amount,
  'date': date.toUtc().toIso8601String(),
  'note': ?note,
  'accountId': ?accountId,
  'fromAccountId': ?fromAccountId,
  'toAccountId': ?toAccountId,
  'categoryId': ?categoryId,
  'originalDate': originalDate.toUtc().toIso8601String(),
};

/// The id being deleted lives in `PendingAction.targetTransactionId`, never
/// duplicated into the payload — this only carries what's needed for cache
/// invalidation and row display on retry.
Map<String, dynamic> deleteTransactionPayload({required DateTime date}) => {'date': date.toUtc().toIso8601String()};

// ── Decode — the inverse of the four builders above, used by retry to turn a
// stored payload back into `TransactionsRepository.create/update/delete` call
// args. Never reads live form state — only what was snapshotted at the
// moment of the original failure.

typedef CreateTransactionArgs = ({TransactionType type, double amount, DateTime date, String? note, int accountId, int? categoryId});

CreateTransactionArgs readCreateTransactionPayload(Map<String, dynamic> payload) => (
  type: transactionTypeFromWire(payload['type'] as String),
  amount: (payload['amount'] as num).toDouble(),
  date: DateTime.parse(payload['date'] as String),
  note: payload['note'] as String?,
  accountId: payload['accountId'] as int,
  categoryId: payload['categoryId'] as int?,
);

typedef CreateTransferArgs = ({double amount, DateTime date, String? note, int fromAccountId, int toAccountId, int? categoryId});

CreateTransferArgs readCreateTransferPayload(Map<String, dynamic> payload) => (
  amount: (payload['amount'] as num).toDouble(),
  date: DateTime.parse(payload['date'] as String),
  note: payload['note'] as String?,
  fromAccountId: payload['fromAccountId'] as int,
  toAccountId: payload['toAccountId'] as int,
  categoryId: payload['categoryId'] as int?,
);

typedef UpdateTransactionArgs = ({
  TransactionType type,
  double amount,
  DateTime date,
  String? note,
  int? accountId,
  int? fromAccountId,
  int? toAccountId,
  int? categoryId,
  DateTime originalDate,
});

UpdateTransactionArgs readUpdateTransactionPayload(Map<String, dynamic> payload) => (
  type: transactionTypeFromWire(payload['type'] as String),
  amount: (payload['amount'] as num).toDouble(),
  date: DateTime.parse(payload['date'] as String),
  note: payload['note'] as String?,
  accountId: payload['accountId'] as int?,
  fromAccountId: payload['fromAccountId'] as int?,
  toAccountId: payload['toAccountId'] as int?,
  categoryId: payload['categoryId'] as int?,
  originalDate: DateTime.parse(payload['originalDate'] as String),
);

typedef DeleteTransactionArgs = ({DateTime date});

DeleteTransactionArgs readDeleteTransactionPayload(Map<String, dynamic> payload) => (date: DateTime.parse(payload['date'] as String));

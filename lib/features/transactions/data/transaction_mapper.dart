import 'package:drift/drift.dart' show Value;

import '../../../core/db/app_database.dart';
import '../domain/transaction.dart';

/// Wire field names mirror the `CachedTransactions` drift columns exactly,
/// same snake_case convention already confirmed for accounts
/// (`account_type`) — confirmed against the live dev API's swagger doc
/// (`/swagger/doc.json`) and a real response.
///
/// One exception: the response never carries a flat `category_id` — it
/// nests category info as `category: {id, name, type, icon_key,
/// color_hex}` (or `null`), confirmed against a live `TransactionResponse`.
Transaction transactionFromJson(Map<String, dynamic> json) {
  final categoryJson = json['category'] as Map<String, dynamic>?;
  return Transaction(
    id: json['id'] as int,
    amount: (json['amount'] as num).toDouble(),
    type: transactionTypeFromWire(json['transaction_type'] as String),
    senderName: json['sender_name'] as String? ?? '',
    receiverName: json['receiver_name'] as String? ?? '',
    note: json['note'] as String? ?? '',
    accountId: json['account_id'] as int?,
    fromAccountId: json['from_account_id'] as int?,
    toAccountId: json['to_account_id'] as int?,
    source: json['source'] as String? ?? 'manual',
    localImageName: json['local_image_name'] as String?,
    transactionDate: DateTime.parse(json['transaction_date'] as String),
    categoryId: categoryJson?['id'] as int?,
    isJunk: json['is_junk'] as bool? ?? false,
  );
}

/// Used by [updateTransactionBody] only (`PATCH /transactions/:id` is one
/// unified endpoint for every type — unlike create, which splits by type
/// into two endpoints below). Whether a `transaction_type` key belongs in
/// a PATCH body at all is a separate, already-tracked issue — not touched
/// here. Only ever carries `account_id` (+ optional `category_id`) for
/// income/expense, or `from_account_id`/`to_account_id` for transfer — a
/// transfer body never contains a `category_id` key no matter what a caller
/// passes in.
Map<String, dynamic> _transactionBody({
  required TransactionType type,
  required double amount,
  required DateTime date,
  String? note,
  int? accountId,
  int? fromAccountId,
  int? toAccountId,
  int? categoryId,
}) {
  final body = <String, dynamic>{
    'transaction_type': type.name,
    'amount': amount,
    'transaction_date': date.toUtc().toIso8601String(),
    'note': note ?? '',
  };
  if (type == TransactionType.transfer) {
    body['from_account_id'] = fromAccountId;
    body['to_account_id'] = toAccountId;
  } else {
    body['account_id'] = accountId;
    if (categoryId != null) body['category_id'] = categoryId;
  }
  return body;
}

/// `POST /api/v1/transactions` (`CreateTransactionInput`, confirmed against
/// the live swagger doc) — income/expense only. This DTO requires
/// `account_id` and has no `transaction_type: "transfer"` value and no
/// `from_account_id`/`to_account_id` at all; a transfer must go through
/// [createTransferBody]/`POST /api/v1/transactions/transfer` instead.
Map<String, dynamic> createTransactionBody({
  required TransactionType type,
  required double amount,
  required DateTime date,
  String? note,
  required int accountId,
  int? categoryId,
}) {
  assert(type != TransactionType.transfer, 'createTransactionBody is income/expense only — use createTransferBody for a transfer');
  final body = <String, dynamic>{
    'transaction_type': type.name,
    'amount': amount,
    'transaction_date': date.toUtc().toIso8601String(),
    'note': note ?? '',
    'account_id': accountId,
  };
  if (categoryId != null) body['category_id'] = categoryId;
  return body;
}

/// `POST /api/v1/transactions/transfer` (`CreateTransferInput`, confirmed
/// against the live swagger doc) — a dedicated endpoint with its own DTO,
/// separate from [createTransactionBody]'s income/expense shape. This DTO
/// has no `transaction_type` field at all.
Map<String, dynamic> createTransferBody({
  required double amount,
  required DateTime date,
  required int fromAccountId,
  required int toAccountId,
  String? note,
  int? categoryId,
}) {
  final body = <String, dynamic>{
    'amount': amount,
    'transaction_date': date.toUtc().toIso8601String(),
    'note': note ?? '',
    'from_account_id': fromAccountId,
    'to_account_id': toAccountId,
  };
  if (categoryId != null) body['category_id'] = categoryId;
  return body;
}

Map<String, dynamic> updateTransactionBody({
  required TransactionType type,
  required double amount,
  required DateTime date,
  String? note,
  int? accountId,
  int? fromAccountId,
  int? toAccountId,
  int? categoryId,
}) => _transactionBody(
  type: type,
  amount: amount,
  date: date,
  note: note,
  accountId: accountId,
  fromAccountId: fromAccountId,
  toAccountId: toAccountId,
  categoryId: categoryId,
);

CachedTransactionsCompanion transactionToCompanion(Transaction transaction) => CachedTransactionsCompanion.insert(
  id: Value(transaction.id),
  amount: transaction.amount,
  transactionType: transaction.type.name,
  senderName: Value(transaction.senderName),
  receiverName: Value(transaction.receiverName),
  note: Value(transaction.note),
  accountId: Value(transaction.accountId),
  fromAccountId: Value(transaction.fromAccountId),
  toAccountId: Value(transaction.toAccountId),
  source: transaction.source,
  localImageName: Value(transaction.localImageName),
  transactionDate: transaction.transactionDate,
  categoryId: Value(transaction.categoryId),
  isJunk: Value(transaction.isJunk),
);

Transaction transactionFromCached(CachedTransaction row) => Transaction(
  id: row.id,
  amount: row.amount,
  type: transactionTypeFromWire(row.transactionType),
  senderName: row.senderName,
  receiverName: row.receiverName,
  note: row.note,
  accountId: row.accountId,
  fromAccountId: row.fromAccountId,
  toAccountId: row.toAccountId,
  source: row.source,
  localImageName: row.localImageName,
  transactionDate: row.transactionDate,
  categoryId: row.categoryId,
  isJunk: row.isJunk,
);

/// transaction_type per SRS — a transfer moves money between two of the
/// user's own accounts and never takes a category (see
/// `transaction_validation.dart`/`transaction_mapper.dart`).
enum TransactionType { income, expense, transfer }

extension TransactionTypeLabel on TransactionType {
  String get label => switch (this) {
    TransactionType.income => 'Income',
    TransactionType.expense => 'Expense',
    TransactionType.transfer => 'Transfer',
  };
}

/// Falls back to [TransactionType.expense] for any wire value this build
/// doesn't recognize yet, so an unfamiliar/future enum value never crashes
/// the app — mirrors `accountTypeFromWire`/`categoryTypeFromWire`.
TransactionType transactionTypeFromWire(String value) => TransactionType.values.firstWhere(
  (type) => type.name == value,
  orElse: () => TransactionType.expense,
);

/// Spec §7.7: the backend never sends a junk flag — Gemini is prompted to
/// answer empty/zero rather than error when a slip image can't be read, so
/// a non-slip photo that slipped into the scanned album creates an
/// otherwise-normal transaction with no usable data. The client detects
/// that shape itself and flags it for the feed badge (see
/// `TransactionListTile`).
bool computeIsJunk({required double amount, required String senderName, required String receiverName}) =>
    amount == 0 && senderName.isEmpty && receiverName.isEmpty;

/// Mirrors `CachedTransactions` (spec §8) field-for-field so this doubles
/// as T7's future feed read model with no rework.
class Transaction {
  const Transaction({
    required this.id,
    required this.amount,
    required this.type,
    this.senderName = '',
    this.receiverName = '',
    this.note = '',
    this.accountId,
    this.fromAccountId,
    this.toAccountId,
    required this.source,
    this.localImageName,
    required this.transactionDate,
    this.categoryId,
    this.isJunk = false,
  });

  final int id;
  final double amount;
  final TransactionType type;
  final String senderName;
  final String receiverName;
  final String note;
  final int? accountId;
  final int? fromAccountId;
  final int? toAccountId;
  final String source;
  final String? localImageName;
  final DateTime transactionDate;
  final int? categoryId;
  final bool isJunk;
}

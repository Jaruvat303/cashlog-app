/// The backend's own sentinel `category_id` for its "Uncategorized" bucket
/// in `GET /api/v1/transactions/summary`'s per-category breakdown
/// (confirmed against a live response: `{"category_id": 0, "category_name":
/// "Uncategorized", ...}`) — never a real category id (those start well
/// above it, e.g. 2703+ in the current seed data), so it's safe to reuse
/// verbatim as the frontend's own sentinel rather than inventing a second
/// one.
///
/// Post-launch UI polish ticket 12: an actual uncategorized [Transaction]
/// carries [Transaction.categoryId] `null` (see `transactionFromJson`'s
/// `categoryJson?['id']`), not `0` — a different representation from the
/// summary breakdown's `0`, because they come from two different backend
/// endpoints with their own independent conventions. `categoryId: 0`
/// reaching [TransactionsRepository.watchMonth] (e.g. from tapping the
/// "Uncategorized" row in the ticket 10 drill-through, which just forwards
/// whatever `categoryId` that `CategoryBreakdown` row carries) must
/// therefore be translated to a `WHERE category_id IS NULL` query, not a
/// literal `WHERE category_id = 0` — the ticket 12 bug was exactly this
/// translation being missing, silently returning zero rows for a category
/// that, from the data's own perspective, doesn't have that id at all.
const int kUncategorizedCategoryId = 0;

/// transaction_type per SRS — a transfer moves money between two of the
/// user's own accounts and never takes a category (see
/// `transaction_validation.dart`/`transaction_mapper.dart`).
enum TransactionType { income, expense, transfer }

extension TransactionTypeLabel on TransactionType {
  String get label => switch (this) {
    TransactionType.income => 'รายรับ',
    TransactionType.expense => 'รายจ่าย',
    TransactionType.transfer => 'ย้ายเงิน',
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

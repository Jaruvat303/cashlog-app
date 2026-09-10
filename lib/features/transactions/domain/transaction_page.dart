import 'transaction.dart';

/// One page of `GET /transactions` (spec §10 — pagination is per month,
/// default page size 20, confirmed against the live dev swagger doc's
/// `PaginationMeta`: `current_page`/`total_pages`).
class TransactionPage {
  const TransactionPage({
    required this.transactions,
    required this.currentPage,
    required this.totalPages,
  });

  final List<Transaction> transactions;
  final int currentPage;
  final int totalPages;

  bool get hasMore => currentPage < totalPages;
}

/// One entry of `DashboardSummaryResponse.income`/`.expense`
/// (`CategoryBreakdownDTO`) — `iconKey`/`colorHex` follow the exact same
/// vocabulary as `Category.iconKey`/`colorHex` (resolved via
/// `shared/widgets/category_icon.dart`'s `resolveCategoryIcon`/
/// `colorFromHex`), since the backend defaults a missing/null pair to
/// `"folder"`/`"#CCCCCC"` itself.
class CategoryBreakdown {
  const CategoryBreakdown({
    required this.categoryId,
    required this.categoryName,
    required this.iconKey,
    required this.colorHex,
    required this.totalAmount,
  });

  final int categoryId;
  final String categoryName;
  final String iconKey;
  final String colorHex;
  final double totalAmount;
}

/// `GET /api/v1/transactions/summary`'s `DashboardSummaryResponse` (spec §11 — monthly
/// scope only in v1). No `cached_dashboard_summary` drift table exists on
/// purpose (spec §8): this is never persisted to disk, only held in-memory
/// by `dashboardSummaryProvider`.
class DashboardSummary {
  const DashboardSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.totalTransfer,
    required this.year,
    required this.month,
    required this.income,
    required this.expense,
  });

  final double totalIncome;
  final double totalExpense;
  final double totalTransfer;
  final int year;
  final int month;
  final List<CategoryBreakdown> income;
  final List<CategoryBreakdown> expense;

  /// `totalTransfer` is deliberately excluded (DoD: never shown in the main
  /// summary — a transfer moves money between the user's own accounts, it's
  /// neither income nor expense).
  double get net => totalIncome - totalExpense;
}

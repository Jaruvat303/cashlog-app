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

/// Sentinel `categoryId` for the synthetic "อื่นๆ" bucket [topCategoriesWithOther]
/// folds the remainder into — never a real backend category id (those are
/// always positive).
const int kOtherCategoryId = -1;

/// Reduces a per-category breakdown to at most [maxSegments] entries by
/// `totalAmount` descending, folding whatever's left over into one synthetic
/// [kOtherCategoryId] ("อื่นๆ") entry — omitted entirely when there's nothing
/// left over, so a breakdown with [maxSegments] or fewer categories never
/// grows a zero-amount "อื่นๆ". Pure/stateless so Home's category-spend bar
/// and its legend can share one source of truth and a plain unit test can
/// cover the aggregation without mounting any widget.
List<CategoryBreakdown> topCategoriesWithOther(List<CategoryBreakdown> breakdown, {int maxSegments = 8}) {
  final sorted = [...breakdown]..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
  final top = sorted.take(maxSegments).toList();
  final otherAmount = sorted.skip(maxSegments).fold(0.0, (sum, b) => sum + b.totalAmount);
  if (otherAmount <= 0) return top;
  return [
    ...top,
    CategoryBreakdown(categoryId: kOtherCategoryId, categoryName: 'อื่นๆ', iconKey: '', colorHex: '', totalAmount: otherAmount),
  ];
}

import '../domain/dashboard_summary.dart';

/// Wire field names mirror the `DashboardSummaryResponse`/`CategoryBreakdownDTO`
/// shapes given in the T8 ticket. No live swagger doc was available locally
/// to confirm the envelope (same disclosure `category_mapper.dart` already
/// carries) — assumed to be `{"data": {...}}`, the same single-object
/// convention already confirmed for every other GET-single/POST/PATCH
/// endpoint in this codebase (accounts, categories, transaction create/
/// update). Spot-check against a live dev response if this differs.
///
/// `icon_key`/`color_hex` on each breakdown entry default to `''` when
/// absent, same as `categoryFromJson` — the backend is documented to send
/// `"folder"`/`"#CCCCCC"` itself rather than omitting them, but
/// `resolveCategoryIcon`/`colorFromHex` already tolerate an empty string
/// gracefully either way.
DashboardSummary dashboardSummaryFromJson(Map<String, dynamic> json) => DashboardSummary(
  totalIncome: (json['total_income'] as num).toDouble(),
  totalExpense: (json['total_expense'] as num).toDouble(),
  totalTransfer: (json['total_transfer'] as num).toDouble(),
  year: json['year'] as int,
  month: json['month'] as int,
  income: _breakdownListFromJson(json['income']),
  expense: _breakdownListFromJson(json['expense']),
);

List<CategoryBreakdown> _breakdownListFromJson(dynamic value) =>
    (value as List? ?? const []).map((e) => _breakdownFromJson(e as Map<String, dynamic>)).toList();

CategoryBreakdown _breakdownFromJson(Map<String, dynamic> json) => CategoryBreakdown(
  categoryId: json['category_id'] as int,
  categoryName: json['category_name'] as String? ?? '',
  iconKey: json['icon_key'] as String? ?? '',
  colorHex: json['color_hex'] as String? ?? '',
  totalAmount: (json['total_amount'] as num).toDouble(),
);

import 'dashboard_summary.dart';
import 'trend_summary.dart';

class YearlySummary {
  const YearlySummary.empty(this.year) : trend = null, summary = null;

  const YearlySummary({
    required this.year,
    required this.trend,
    required this.summary,
  });

  final int year;
  final TrendSummary? trend;
  final DashboardSummary? summary;

  bool get hasTransactions => trend != null && summary != null;
}

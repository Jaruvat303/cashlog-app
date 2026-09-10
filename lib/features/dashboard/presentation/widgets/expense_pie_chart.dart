import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/category_icon.dart';
import '../../domain/dashboard_summary.dart';

/// One slice per `expense[]` entry, sorted descending by [CategoryBreakdown.totalAmount]
/// (DoD requirement) — the caller (`DashboardPage`) is expected to only
/// build this when `expense` is non-empty; the empty-state message is a
/// page-level concern (same split as `TransactionsPage`'s own empty check),
/// not this widget's.
class ExpensePieChart extends StatelessWidget {
  const ExpensePieChart({super.key, required this.expense});

  final List<CategoryBreakdown> expense;

  @override
  Widget build(BuildContext context) {
    final sorted = [...expense]..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: sorted
                  .map(
                    (entry) => PieChartSectionData(
                      value: entry.totalAmount,
                      color: colorFromHex(entry.colorHex),
                      title: '',
                      radius: 60,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...sorted.map(
          (entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(resolveCategoryIcon(entry.iconKey), size: 18, color: colorFromHex(entry.colorHex)),
                const SizedBox(width: 8),
                Expanded(child: Text(entry.categoryName)),
                Text(entry.totalAmount.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

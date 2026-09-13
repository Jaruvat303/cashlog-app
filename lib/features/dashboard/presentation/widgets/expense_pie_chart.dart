import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/format/money.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../../domain/dashboard_summary.dart';

/// Mockup 1a's donut + legend. One slice per `expense[]` entry, sorted
/// descending by [CategoryBreakdown.totalAmount] (DoD requirement) — the
/// caller (`DashboardPage`) is expected to only build this when `expense`
/// is non-empty; the empty-state message is a page-level concern (same
/// split as `TransactionsPage`'s own empty check), not this widget's.
class ExpensePieChart extends StatelessWidget {
  const ExpensePieChart({super.key, required this.expense, required this.total});

  final List<CategoryBreakdown> expense;
  final double total;

  @override
  Widget build(BuildContext context) {
    final sorted = [...expense]..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 34,
                  sections: sorted
                      .map(
                        (entry) => PieChartSectionData(
                          value: entry.totalAmount,
                          color: colorFromHex(entry.colorHex),
                          title: '',
                          radius: 14,
                        ),
                      )
                      .toList(),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('รวม', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                  Text(
                    formatAmount(total, withSymbol: false),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: sorted.map((entry) {
              final pct = total == 0 ? 0 : (entry.totalAmount / total * 100).round();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.5),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: colorFromHex(entry.colorHex), borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(entry.categoryName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    ),
                    Text('$pct%', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

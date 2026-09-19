import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/format/money.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../../domain/dashboard_summary.dart';

/// Mockup 1a's donut, enlarged (post-launch UI polish ticket 03: "ขยายขนาดให้
/// ใหญ่ขึ้นชัดเจน") with each slice's percentage floating around the ring at
/// its own angular midpoint, rather than the previous side-by-side dot+name
/// legend list — no leader lines, matching the mockup. One slice per
/// `expense`/`income` entry (generic despite the name — ticket 03 reinstates
/// it on both the Income and Expense summary tabs), sorted descending by
/// [CategoryBreakdown.totalAmount] (DoD requirement) — the caller
/// (`TransactionsPage`) is expected to only build this when the breakdown is
/// non-empty; the empty-state message is a page-level concern (same split as
/// `TransactionsPage`'s own empty check), not this widget's. Category
/// names/amounts stay fully available just below this, in the unchanged
/// `_CategoryTotalsList` — this widget is purely the visual chart now.
class ExpensePieChart extends StatelessWidget {
  const ExpensePieChart({super.key, required this.expense, required this.total});

  final List<CategoryBreakdown> expense;
  final double total;

  /// Pie starts at 12 o'clock (mockup), sweeping clockwise — matches
  /// `PieChartData.startDegreeOffset` below, so the percentage labels'
  /// angles agree with where `fl_chart` actually draws each slice.
  static const double _startDegreeOffset = -90;

  /// Caps how large the chart grows on wide screens — still a large jump
  /// from the previous fixed 110px, without letting the ring or its
  /// floating labels run off a wide tablet-ish viewport.
  static const double _maxChartSize = 190;

  @override
  Widget build(BuildContext context) {
    final sorted = [...expense]..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    if (total <= 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : _maxChartSize;
        final chartSize = math.min(availableWidth * 0.72, _maxChartSize);
        final centerSpaceRadius = chartSize * 0.34;
        final sectionRadius = chartSize * 0.16;
        final ringRadius = centerSpaceRadius + sectionRadius;
        final labelRadius = ringRadius + 24;
        // Enough room around the ring for labels floating outside it,
        // regardless of the ring's own (responsive) size.
        final stackSize = ringRadius * 2 + 68;

        final labels = <Widget>[];
        var cumulativeDegrees = _startDegreeOffset;
        for (final entry in sorted) {
          final sweepDegrees = 360 * (entry.totalAmount / total);
          final midAngle = cumulativeDegrees + sweepDegrees / 2;
          cumulativeDegrees += sweepDegrees;

          final pct = (entry.totalAmount / total * 100).round();
          if (pct <= 0) continue;

          final radians = midAngle * math.pi / 180;
          final center = Offset(stackSize / 2, stackSize / 2);
          final labelCenter = center + Offset(math.cos(radians), math.sin(radians)) * labelRadius;
          const labelBoxSize = Size(36, 16);
          labels.add(
            Positioned(
              key: ValueKey('pieChartPercentLabel-${entry.categoryId}'),
              left: labelCenter.dx - labelBoxSize.width / 2,
              top: labelCenter.dy - labelBoxSize.height / 2,
              width: labelBoxSize.width,
              height: labelBoxSize.height,
              child: Text(
                '$pct%',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
          );
        }

        return Center(
          child: SizedBox(
            width: stackSize,
            height: stackSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  key: const Key('pieChartCircle'),
                  width: chartSize,
                  height: chartSize,
                  child: PieChart(
                    PieChartData(
                      startDegreeOffset: _startDegreeOffset,
                      sectionsSpace: 2,
                      centerSpaceRadius: centerSpaceRadius,
                      sections: sorted
                          .map(
                            (entry) => PieChartSectionData(
                              value: entry.totalAmount,
                              color: colorFromHex(entry.colorHex),
                              title: '',
                              radius: sectionRadius,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('รวม', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text(
                      formatAmount(total, withSymbol: false),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                ...labels,
              ],
            ),
          ),
        );
      },
    );
  }
}

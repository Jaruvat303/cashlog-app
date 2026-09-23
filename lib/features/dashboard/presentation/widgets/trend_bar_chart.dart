import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/month/selected_month_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/finance_colors.dart';
import '../../../../shared/format/money.dart';
import '../../domain/trend_summary.dart';

/// Grouped income/expense bar chart for a [TrendSummary] — one group per
/// bucket, income/expense as side-by-side rods. Month mode always gets 12
/// groups (backend zero-fills, F2); year mode gets however many years the
/// backend has data for (currently 1 — spec's Further Notes).
///
/// Rod width is computed from the actually available width
/// (`LayoutBuilder`, same responsive-sizing approach `ExpensePieChart`
/// already uses) rather than a fixed constant — a fixed ~8px rod times 12
/// month-mode groups, plus inter-rod/inter-group spacing and the left axis's
/// reserved width, comfortably overflows a ~350px phone. `BarChartAlignment
/// .spaceAround` then distributes whatever width remains around the
/// (now correctly-sized) groups automatically.
class TrendBarChart extends StatelessWidget {
  const TrendBarChart({super.key, required this.summary});

  final TrendSummary summary;

  static const double _leftAxisReservedWidth = 44;
  static const double _chartHeight = 220;
  static const double _minRodWidth = 3;
  static const double _maxRodWidth = 14;
  static const double _rodGap = 3;

  bool _isFutureBucket(TrendBucket bucket) {
    if (summary.granularity != TrendGranularity.month) return false;
    final now = DateTime.now();
    final month = bucket.month;
    return bucket.year == now.year && month != null && month > now.month;
  }

  String _tooltipHeader(TrendBucket bucket) =>
      summary.granularity == TrendGranularity.month
      ? '${monthAbbreviationTh(bucket.month!)} ${buddhistYear(bucket.year)}'
      : '${buddhistYear(bucket.year)}';

  String _tooltipText(TrendBucket bucket) =>
      '${_tooltipHeader(bucket)}\n'
      'รายรับ ${formatAmount(bucket.totalIncome)}\n'
      'รายจ่าย ${formatAmount(bucket.totalExpense)}\n'
      'สุทธิ ${formatAmount(bucket.net)}';

  String _bottomLabel(TrendBucket bucket) =>
      summary.granularity == TrendGranularity.month
      ? monthAbbreviationTh(bucket.month!)
      : buddhistYear(bucket.year).toString();

  @override
  Widget build(BuildContext context) {
    final buckets = summary.buckets;
    final colors = context.financeColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Legend(incomeColor: colors.income, expenseColor: colors.expense),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : 320.0;
            final chartAreaWidth = math.max(
              availableWidth - _leftAxisReservedWidth,
              80.0,
            );
            final perGroupWidth = buckets.isEmpty
                ? chartAreaWidth
                : chartAreaWidth / buckets.length;
            final rodWidth = ((perGroupWidth * 0.6 - _rodGap) / 2).clamp(
              _minRodWidth,
              _maxRodWidth,
            );

            return SizedBox(
              height: _chartHeight,
              child: BarChart(
                key: const Key('trendBarChart'),
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: [
                    for (var i = 0; i < buckets.length; i++)
                      BarChartGroupData(
                        x: i,
                        barsSpace: _rodGap,
                        barRods: _isFutureBucket(buckets[i])
                            ? const []
                            : [
                                BarChartRodData(
                                  toY: buckets[i].totalIncome,
                                  color: colors.income,
                                  width: rodWidth,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                BarChartRodData(
                                  toY: buckets[i].totalExpense,
                                  color: colors.expense,
                                  width: rodWidth,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ],
                      ),
                  ],
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: _leftAxisReservedWidth,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            formatCompactAmount(value),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= buckets.length) {
                            return const SizedBox.shrink();
                          }
                          final bucket = buckets[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _bottomLabel(bucket),
                              style: TextStyle(
                                fontSize: 10,
                                color: _isFutureBucket(bucket)
                                    ? AppColors.textFaint
                                    : AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        if (groupIndex < 0 || groupIndex >= buckets.length) {
                          return null;
                        }
                        return BarTooltipItem(
                          _tooltipText(buckets[groupIndex]),
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  gridData: const FlGridData(drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Y-axis label abbreviation — no existing K/M formatter in the app
/// (`shared/format/money.dart`'s `formatAmount` is always full-precision).
/// Public (unlike this file's other helpers) for the same reason
/// `formatAmount`/`monthAbbreviationTh` are: directly unit-testable without
/// reaching into a private closure.
String formatCompactAmount(double value) {
  final sign = value < 0 ? '-' : '';
  final abs = value.abs();
  if (abs >= 1000000) return '$sign${_scaled(abs, 1000000)}M';
  if (abs >= 1000) {
    // toStringAsFixed(1) rounds — 999999 / 1000 is 999.999, which rounds to
    // "1000.0" here, not "999.9" (e.g. 999999 would render as the
    // misleading "1000K" instead of just rolling over to "1M" like it
    // should). Re-scale to M whenever that rounding pushes the K value up
    // to a full 1000, rather than ever showing a 4-digit "K".
    final scaledK = _scaled(abs, 1000);
    if (scaledK == '1000') return '$sign${_scaled(abs, 1000000)}M';
    return '$sign${scaledK}K';
  }
  return '$sign${abs.toStringAsFixed(0)}';
}

String _scaled(double abs, int divisor) {
  final fixed = (abs / divisor).toStringAsFixed(1);
  return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.incomeColor, required this.expenseColor});

  final Color incomeColor;
  final Color expenseColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: incomeColor, label: 'รายรับ'),
        const SizedBox(width: 16),
        _LegendDot(color: expenseColor, label: 'รายจ่าย'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

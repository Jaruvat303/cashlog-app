import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/month/selected_month_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/trend_summary.dart';

class TrendLineChart extends StatelessWidget {
  const TrendLineChart({super.key, required this.summary});

  final TrendSummary summary;

  bool _isFutureBucket(TrendBucket bucket) {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final month = bucket.month;
    return bucket.year == now.year && month != null && month > now.month;
  }

  @override
  Widget build(BuildContext context) {
    assert(summary.granularity == TrendGranularity.month);
    final buckets = summary.buckets;
    final candidateEntries = buckets
        .asMap()
        .entries
        .where((entry) => !_isFutureBucket(entry.value))
        .toList();
    final lastDataIndex = candidateEntries.lastIndexWhere(
      (entry) => entry.value.totalIncome != 0 || entry.value.totalExpense != 0,
    );
    final visibleEntries = lastDataIndex < 0
        ? <MapEntry<int, TrendBucket>>[]
        : candidateEntries.take(lastDataIndex + 1).toList();

    final incomeSpots = visibleEntries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.totalIncome.toDouble());
    }).toList();

    final expenseSpots = visibleEntries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.totalExpense.toDouble());
    }).toList();

    final lastIndex = visibleEntries.isEmpty ? 0 : visibleEntries.last.key;

    return Card(
      key: const Key('trendLineChartCard'),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.cardLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
        child: Column(
          children: [
            _Legend(
              incomeColor: AppColors.income,
              expenseColor: AppColors.expense,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: LineChart(
                key: const Key('trendLineChart'),
                LineChartData(
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.asMap().entries.map((entry) {
                          if (entry.key > 0) return null;
                          final touchedSpot = entry.value;
                          final index = touchedSpot.x.toInt();
                          if (index < 0 || index >= buckets.length) {
                            return null;
                          }

                          final bucket = buckets[index];

                          return LineTooltipItem(
                            '${monthAbbreviationTh(bucket.month!)}\n'
                            'รายรับ: ${formatCompactAmount(bucket.totalIncome)}\n'
                            'รายจ่าย: ${formatCompactAmount(bucket.totalExpense)}\n'
                            'สุทธิ: ${formatCompactAmount(bucket.net)}',
                            TextStyle(
                              color: touchedSpot.bar.color ?? Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  minX: 0,
                  maxX: lastIndex > 0 ? lastIndex.toDouble() : 1,
                  minY: 0,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: false,
                    drawVerticalLine: true,
                    verticalInterval: 1,
                    checkToShowVerticalLine: (value) {
                      final i = value.toInt();
                      if (i < 0 || i >= buckets.length) {
                        return false;
                      }
                      final m = buckets[i].month;
                      return m != null && m % 3 == 0;
                    },
                    getDrawingVerticalLine: (_) => FlLine(
                      color: AppColors.textDisabled.withValues(alpha: 60),
                      strokeWidth: 1,
                    ),
                  ),
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
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              formatCompactAmount(value),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= summary.buckets.length) {
                            return const SizedBox.shrink();
                          }

                          final bucket = summary.buckets[index];
                          if (bucket.month == null || bucket.month! % 3 != 0) {
                            return const SizedBox.shrink();
                          }

                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              monthAbbreviationTh(bucket.month!),
                              style: TextStyle(
                                color: _isFutureBucket(bucket)
                                    ? AppColors.textDisabled
                                    : Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
                                fontSize: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.fontSize,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: incomeSpots.isEmpty && expenseSpots.isEmpty
                      ? const []
                      : [
                          _bar(incomeSpots, AppColors.income),
                          _bar(expenseSpots, AppColors.expense),
                        ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatCompactAmount(double value) {
  final sign = value < 0 ? '-' : '';
  final absValue = value.abs();

  if (absValue >= 1000000) {
    return '$sign${_scaled(absValue, 1000000)}M';
  }

  if (absValue >= 1000) {
    final scaledK = _scaled(absValue, 1000);

    if (scaledK == '1000') {
      return '$sign${_scaled(absValue, 1000000)}M'; // Special case for 1,000K which should be displayed as 1M
    }

    return '$sign${scaledK}K';
  }

  return '$sign${absValue.toStringAsFixed(0)}';
}

String _scaled(double value, double divisor) {
  final scaled = value / divisor;
  return scaled.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
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
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

LineChartBarData _bar(List<FlSpot> spots, Color color) {
  return LineChartBarData(
    spots: spots,
    color: color,
    barWidth: 2.5,
    isCurved: true,
    curveSmoothness: 0.3,
    preventCurveOverShooting: true, // แก้เส้นทะลุต่ำกว่า 0
    // โชว์เฉพาะจุดสุดท้าย
    dotData: FlDotData(
      show: true,
      checkToShowDot: (spot, barData) => spot.x == barData.spots.last.x,
      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
        radius: 4,
        color: color,
        strokeWidth: 2,
        strokeColor: Colors.white,
      ),
    ),
    // gradient จางลงไปข้างล่าง
    belowBarData: BarAreaData(
      show: true,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withAlpha(70), color.withAlpha(0)],
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../../../core/month/selected_month_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/dashboard_summary.dart';
import '../../domain/trend_summary.dart';
import '../providers/yearly_summary_provider.dart';
import '../widgets/trend_line_chart.dart';
import '../../../../shared/widgets/category_icon.dart';

/// Annual dashboard, opened from the existing "ดูสรุป" entry point.
class TrendPage extends ConsumerStatefulWidget {
  const TrendPage({super.key});

  @override
  ConsumerState<TrendPage> createState() => _TrendPageState();
}

class _TrendPageState extends ConsumerState<TrendPage> {
  late int _year = _bangkokNow().year;
  bool _showExpenses = true;

  @override
  Widget build(BuildContext context) {
    final earliestYear = ref.watch(earliestTrendYearProvider);
    final summaryAsync = ref.watch(yearlySummaryProvider(_year));
    final currentYear = _bangkokNow().year;

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('สรุปรายปี')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            summaryAsync.when(
              loading: () => _LoadingSummary(year: _year),
              error: (error, _) => _ErrorSummary(error: error, onRetry: _retry),
              data: (summary) {
                if (!summary.hasTransactions) {
                  return _EmptySummary(year: currentYear);
                }

                return Column(
                  children: [
                    _YearSwitcher(
                      year: _year,
                      canGoBack:
                          earliestYear.value != null &&
                          _year > earliestYear.value!,
                      canGoForward: _year < currentYear,
                      onBack: () => setState(() => _year -= 1),
                      onForward: () => setState(() => _year += 1),
                    ),
                    const SizedBox(height: 16),
                    _KpiCards(summary: summary.summary!, trend: summary.trend!),
                    const SizedBox(height: 16),
                    TrendLineChart(summary: summary.trend!),
                    const SizedBox(height: 16),
                    _CategoryBreakdownTabs(
                      summary: summary.summary!,
                      showExpenses: _showExpenses,
                      onChanged: (showExpenses) =>
                          setState(() => _showExpenses = showExpenses),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _retry() {
    ref.invalidate(earliestTrendYearProvider);
    ref.invalidate(yearlySummaryProvider(_year));
  }

  Future<void> _refresh() {
    ref.invalidate(earliestTrendYearProvider);
    ref.invalidate(yearlySummaryProvider(_year));
    return ref.read(yearlySummaryProvider(_year).future);
  }
}

DateTime _bangkokNow() => DateTime.now().toUtc().add(const Duration(hours: 7));

class _LoadingSummary extends StatelessWidget {
  const _LoadingSummary({required this.year});

  final int year;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _YearSwitcher(
        year: year,
        canGoBack: false,
        canGoForward: false,
        onBack: () {},
        onForward: () {},
      ),
      const SizedBox(height: 16),
      GridView.count(
        key: const Key('yearlyKpiSkeleton'),
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.48,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(4, (_) => const _SkeletonCard(height: 104)),
      ),
      const SizedBox(height: 16),
      const _SkeletonCard(key: Key('trendChartSkeleton'), height: 220),
    ],
  );
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.cardLarge),
    ),
    padding: const EdgeInsets.all(20),
    child: height < 150
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _skeletonBlock(width: 90, height: 14),
              _skeletonBlock(width: 112, height: 22),
              _skeletonBlock(width: 80, height: 10),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _skeletonBlock(width: 110, height: 16),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    6,
                    (index) => _skeletonBlock(
                      width: 22,
                      height: 34 + (index % 3) * 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
  );

  Widget _skeletonBlock({required double width, required double height}) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
        ),
      );
}

class _ErrorSummary extends StatelessWidget {
  const _ErrorSummary({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 16),
    child: Column(
      children: [
        const Icon(Icons.error_outline, size: 42, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text('โหลดสรุปรายปีไม่สำเร็จ: $error', textAlign: TextAlign.center),
        const SizedBox(height: 12),
        TextButton(
          key: const Key('yearlySummaryRetryButton'),
          onPressed: onRetry,
          child: const Text('ลองอีกครั้ง'),
        ),
      ],
    ),
  );
}

class _EmptySummary extends StatelessWidget {
  const _EmptySummary({required this.year});

  final int year;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 72),
    child: Column(
      children: [
        Text(
          '${buddhistYear(year)}',
          key: const Key('yearlySummaryYear'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        const SizedBox(height: 32),
        const Icon(
          RemixIcon.fileList3Line,
          size: 56,
          color: AppColors.textDisabled,
        ),
        const SizedBox(height: 12),
        const Text(
          'ยังไม่มีรายการ',
          key: Key('yearlySummaryEmpty'),
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _KpiCards extends StatelessWidget {
  const _KpiCards({required this.summary, required this.trend});

  final DashboardSummary summary;
  final TrendSummary trend;

  @override
  Widget build(BuildContext context) {
    final savingsRate = summary.totalIncome == 0
        ? null
        : summary.net / summary.totalIncome * 100;
    final monthCount = _activeMonthCount(trend);

    return GridView.count(
      key: const Key('yearlySummaryKpiGrid'),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.48,
      children: [
        _KpiCard(
          key: const Key('yearlyIncomeKpi'),
          label: 'รายรับรวม',
          amount: summary.totalIncome,
          average: _average(summary.totalIncome, monthCount),
          color: AppColors.income,
          icon: RemixIcon.arrowDownLine,
        ),
        _KpiCard(
          key: const Key('yearlyExpenseKpi'),
          label: 'รายจ่ายรวม',
          amount: summary.totalExpense,
          average: _average(summary.totalExpense, monthCount),
          color: AppColors.expense,
          icon: RemixIcon.arrowUpLine,
        ),
        _KpiCard(
          key: const Key('yearlyNetKpi'),
          label: 'เงินเหลือสุทธิ',
          amount: summary.net,
          average: _average(summary.net, monthCount),
          color: AppColors.primary,
          icon: summary.net < 0
              ? RemixIcon.arrowDownLine
              : RemixIcon.wallet3Line,
        ),
        _KpiCard(
          key: const Key('yearlySavingsRateKpi'),
          label: 'อัตราการออม',
          value: savingsRate == null
              ? '—'
              : '${savingsRate.toStringAsFixed(1)}%',
          color: AppColors.primary,
          icon: RemixIcon.pieChartLine,
        ),
      ],
    );
  }

  int _activeMonthCount(TrendSummary trend) {
    final activeMonths = trend.buckets
        .where((bucket) => bucket.totalIncome != 0 || bucket.totalExpense != 0)
        .map((bucket) => bucket.month)
        .whereType<int>()
        .toList();
    if (activeMonths.isEmpty) return 0;
    final firstMonth = activeMonths.reduce((a, b) => a < b ? a : b);
    final now = _bangkokNow();
    final endMonth = trend.year == now.year ? now.month : 12;
    return endMonth - firstMonth + 1;
  }

  String _average(double value, int monthCount) => monthCount == 0
      ? '—'
      : 'เฉลี่ย ${formatYearlyAmount(value / monthCount)} / เดือน';
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    this.amount,
    this.average,
    this.value,
  });

  final String label;
  final double? amount;
  final String? average;
  final String? value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.card),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          value ?? formatYearlyAmount(amount!),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (average != null) ...[
          const SizedBox(height: 4),
          Text(
            average!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ],
    ),
  );
}

String formatYearlyAmount(double amount) {
  final fixed = amount.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts.first;
  final formatted = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) formatted.write(',');
    formatted.write(digits[i]);
  }
  final decimals = parts.last == '00' ? '' : '.${parts.last}';
  return '${amount < 0 ? '-' : ''}฿$formatted$decimals';
}

class _CategoryBreakdownTabs extends StatelessWidget {
  const _CategoryBreakdownTabs({
    required this.summary,
    required this.showExpenses,
    required this.onChanged,
  });

  final DashboardSummary summary;
  final bool showExpenses;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final categories = showExpenses ? summary.expense : summary.income;
    final total = showExpenses ? summary.totalExpense : summary.totalIncome;
    final sorted = [...categories]
      ..sort((a, b) {
        if (a.categoryId == 0) return b.categoryId == 0 ? 0 : 1;
        if (b.categoryId == 0) return -1;
        return b.totalAmount.compareTo(a.totalAmount);
      });

    return Card(
      key: const Key('yearlyCategoryCard'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _CategoryTab(
                    key: const Key('yearlyExpenseTab'),
                    label: 'รายจ่าย',
                    total: summary.totalExpense,
                    selected: showExpenses,
                    onTap: () => onChanged(true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CategoryTab(
                    key: const Key('yearlyIncomeTab'),
                    label: 'รายรับ',
                    total: summary.totalIncome,
                    selected: !showExpenses,
                    onTap: () => onChanged(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (sorted.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  showExpenses ? 'ไม่มีรายจ่ายในปีนี้' : 'ไม่มีรายรับในปีนี้',
                  key: const Key('yearlyCategoryEmpty'),
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              )
            else
              for (var i = 0; i < sorted.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _CategoryRow(
                  category: sorted[i],
                  total: total,
                  isUncategorized: sorted[i].categoryId == 0,
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    super.key,
    required this.label,
    required this.total,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final double total;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: selected ? null : AppColors.surfaceMuted,
      gradient: selected ? AppColors.primaryGradient : null,
      borderRadius: BorderRadius.circular(AppRadii.control),
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.control),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.control),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textBody,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatYearlyAmount(total),
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textBody,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.total,
    required this.isUncategorized,
  });

  final CategoryBreakdown category;
  final double total;
  final bool isUncategorized;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(category.colorHex);
    final percentage = total == 0 ? 0.0 : category.totalAmount / total * 100;
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                resolveCategoryIcon(category.iconKey),
                color: color,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isUncategorized ? 'ไม่ระบุหมวด' : category.categoryName,
                key: Key('yearlyCategoryName${category.categoryId}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatYearlyAmount(category.totalAmount),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _YearSwitcher extends StatelessWidget {
  const _YearSwitcher({
    required this.year,
    required this.canGoForward,
    required this.canGoBack,
    required this.onBack,
    required this.onForward,
  });

  final int year;
  final bool canGoForward;
  final bool canGoBack;
  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _YearArrow(
          key: const Key('trendYearBack'),
          icon: RemixIcon.arrowLeftSLine,
          onTap: canGoBack ? onBack : null,
        ),
        const SizedBox(width: 16),
        Text(
          '${buddhistYear(year)}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(width: 16),
        _YearArrow(
          key: const Key('trendYearForward'),
          icon: RemixIcon.arrowRightSLine,
          onTap: canGoForward ? onForward : null,
        ),
      ],
    );
  }
}

class _YearArrow extends StatelessWidget {
  const _YearArrow({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? AppColors.textDisabled : AppColors.textMuted,
        ),
      ),
    );
  }
}

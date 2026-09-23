import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../../../core/month/selected_month_provider.dart';
import '../../../../shared/format/money.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../../../../shared/widgets/gradient_hero_card.dart';
import '../../domain/dashboard_summary.dart';
import '../providers/dashboard_providers.dart';
import 'auto_scan_status_text.dart';

/// The Home gradient hero card: a static (read-only) month label, this
/// month's total expense (with a month-over-month % delta), a shortcut into
/// the Summary tab, the last-successful-auto-scan timestamp, and a category
/// spend bar + legend — sourced from [dashboardSummaryProvider] (current +
/// previous month), no new endpoints.
///
/// Post-launch UI polish ticket 02: month switching moved out of this widget
/// entirely — a month dropdown here duplicated the one on the Summary page's
/// Topbar and confused which one was authoritative (spec: "so that month
/// switching only happens in one place"). This widget only ever reads the
/// shared `selectedMonthProvider`; [DashboardPage] listens for changes made
/// elsewhere (Summary's own switcher) to keep its list in sync.
class ExpenseTotalWidget extends ConsumerWidget {
  const ExpenseTotalWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final summaryAsync = ref.watch(
      dashboardSummaryProvider(month.year, month.month),
    );
    final previous = DateTime.utc(month.year, month.month - 1);
    final previousSummary = ref
        .watch(dashboardSummaryProvider(previous.year, previous.month))
        .value;

    return GradientHeroCard(
      key: const Key('expenseTotalWidget'),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  RemixIcon.calendar2Line,
                  size: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ค่าใช้จ่ายเดือนนี้',
                  style: TextStyle(fontSize: 13, color: Color(0xD9FFFFFF)),
                ),
              ),
              // Static, read-only — month switching only happens from the
              // Summary page's Topbar now (ticket 02).
              Text(
                monthYearLabel(month),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          summaryAsync.when(
            loading: () => const SizedBox(
              height: 40,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            error: (error, _) => const Text(
              'โหลดยอดใช้จ่ายไม่สำเร็จ',
              style: TextStyle(fontSize: 13, color: Colors.white),
            ),
            data: (summary) {
              final delta =
                  previousSummary == null || previousSummary.totalExpense == 0
                  ? null
                  : ((summary.totalExpense - previousSummary.totalExpense) /
                            previousSummary.totalExpense) *
                        100;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    key: const Key('expenseTotalAmount'),
                    formatAmount(summary.totalExpense),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (delta != null) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            delta <= 0
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${delta.abs().toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: AutoScanStatusText()),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.go('/transactions'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        RemixIcon.barChart2Line,
                        size: 13,
                        color: Colors.white,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'ดูสรุป',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          summaryAsync.maybeWhen(
            data: (summary) => summary.expense.isEmpty
                ? const SizedBox.shrink()
                : _CategorySpendBar(breakdown: summary.expense),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// The Home banner's category-spend bar + legend (spec: "top 8 spending
/// categories for the month plus an 'อื่นๆ' bucket for the rest ... stays
/// informative even when I have many categories"). [topCategoriesWithOther]
/// (pure/unit-tested on its own) supplies the up-to-9 segments; this widget
/// only lays them out.
class _CategorySpendBar extends StatelessWidget {
  const _CategorySpendBar({required this.breakdown});

  final List<CategoryBreakdown> breakdown;

  static const int _maxSegments = 8;

  /// Guarantees a small-percentage segment still reads as a visible sliver
  /// of color, rather than shrinking below a visible width (spec: "a
  /// minimum-width per segment ... prevent[s] a segment from being too thin
  /// to see its color when its % is small").
  static const double _minSegmentWidth = 6;

  @override
  Widget build(BuildContext context) {
    final segments = topCategoriesWithOther(
      breakdown,
      maxSegments: _maxSegments,
    );
    final total = segments.fold(0.0, (sum, b) => sum + b.totalAmount);
    if (total <= 0) return const SizedBox.shrink();

    Color colorOf(CategoryBreakdown b) => b.categoryId == kOtherCategoryId
        ? Colors.white.withValues(alpha: 0.5)
        : colorFromHex(b.colorHex);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: Color(0x2EFFFFFF)),
          const SizedBox(height: 12),
          const Text(
            'ใช้จ่ายตามหมวดหมู่',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 8,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final amounts = [for (final b in segments) b.totalAmount];
                  final widths = _segmentWidths(
                    amounts,
                    total,
                    constraints.maxWidth,
                  );
                  return Row(
                    key: const Key('categorySpendBarSegments'),
                    children: [
                      for (var i = 0; i < segments.length; i++)
                        SizedBox(
                          width: widths[i],
                          child: Container(color: colorOf(segments[i])),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              for (final b in segments)
                SizedBox(
                  width: 96,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colorOf(b),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          b.categoryName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Distributes [availableWidth] across [amounts] proportionally, except
  /// any segment whose proportional share would fall under
  /// [_minSegmentWidth] is clamped up to it — the width that frees up is
  /// taken back out of the remaining (non-clamped) segments, which are then
  /// re-distributed among themselves so the total still exactly fills
  /// [availableWidth].
  List<double> _segmentWidths(
    List<double> amounts,
    double total,
    double availableWidth,
  ) {
    final isSmall = [
      for (final amount in amounts)
        amount / total * availableWidth < _minSegmentWidth,
    ];
    final reserved = isSmall.where((small) => small).length * _minSegmentWidth;
    final remainingWidth = (availableWidth - reserved)
        .clamp(0, availableWidth)
        .toDouble();
    final remainingTotal = [
      for (var i = 0; i < amounts.length; i++)
        if (!isSmall[i]) amounts[i],
    ].fold(0.0, (sum, a) => sum + a);
    return [
      for (var i = 0; i < amounts.length; i++)
        if (isSmall[i])
          _minSegmentWidth
        else if (remainingTotal <= 0)
          0.0
        else
          amounts[i] / remainingTotal * remainingWidth,
    ];
  }
}

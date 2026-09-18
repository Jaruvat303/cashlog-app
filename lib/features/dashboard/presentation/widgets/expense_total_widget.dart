import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../../../core/month/selected_month_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/format/money.dart';
import '../providers/dashboard_providers.dart';

/// Ticket 07: folds Home's month switcher (previously the AppBar title,
/// same slot `TransactionsPage`'s own switcher used before ticket 04 moved
/// it into that page's AppBar) into the same widget that shows this
/// month's total expense as a plain number — spec: "fold the month
/// switcher ... into this widget" so switching months and seeing the total
/// live in one place.
///
/// Reads/drives the shared `selectedMonthProvider` directly, same as
/// `DashboardPage`'s list and `TransactionsPage` already do — this is not a
/// second, independent month selector. [onMonthChanged] fires *after* the
/// selection changes, purely so the caller can perform the side effects
/// `DashboardPage._onMonthChanged` needs on top of that shared state (reset
/// scroll position, kick off the new month's paged fetch) — the same
/// side-effect split ticket 06's list already relies on.
///
/// The total itself comes from `dashboardSummaryProvider` — the exact
/// provider `TransactionsPage`'s expense summary tab already calls (spec:
/// "reuse the app's existing month-total / expense-sum calculation logic"),
/// not a new aggregation written from scratch.
class ExpenseTotalWidget extends ConsumerWidget {
  const ExpenseTotalWidget({super.key, required this.onMonthChanged});

  final VoidCallback onMonthChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider(month.year, month.month));

    return Container(
      key: const Key('expenseTotalWidget'),
      decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _monthArrow(
                icon: RemixIcon.arrowLeftSLine,
                onTap: () => _switchMonth(ref, () => ref.read(selectedMonthProvider.notifier).previous()),
              ),
              const SizedBox(width: 10),
              Text(monthYearLabel(month), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(width: 10),
              _monthArrow(
                icon: RemixIcon.arrowRightSLine,
                onTap: () => _switchMonth(ref, () => ref.read(selectedMonthProvider.notifier).next()),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('ยอดใช้จ่ายเดือนนี้', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          summaryAsync.when(
            loading: () => const SizedBox(
              height: 30,
              child: Align(alignment: Alignment.centerLeft, child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
            error: (error, _) => const Text('โหลดยอดใช้จ่ายไม่สำเร็จ', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            data: (summary) => Text(
              key: const Key('expenseTotalAmount'),
              formatAmount(summary.totalExpense),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _switchMonth(WidgetRef ref, void Function() mutateSelection) {
    mutateSelection();
    onMonthChanged();
  }

  Widget _monthArrow({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: AppColors.screenBackground, borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

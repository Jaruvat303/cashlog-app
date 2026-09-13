import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../../../core/month/selected_month_provider.dart';
import '../../../../core/network/failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/format/money.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/domain/bank_icon.dart';
import '../../../accounts/presentation/providers/accounts_providers.dart';
import '../../../accounts/presentation/widgets/current_balance_text.dart';
import '../../../categories/presentation/providers/categories_providers.dart';
import '../../../transactions/presentation/providers/transactions_feed_providers.dart';
import '../../../transactions/presentation/widgets/transaction_list_tile.dart';
import '../../domain/dashboard_summary.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/expense_pie_chart.dart';

/// Mockup screen 1a. Deliberately does NOT render `DashboardSummary.
/// totalTransfer` anywhere (CLAUDE.md/DoD: a transfer moves money between
/// the user's own accounts, so it must never appear in the main summary —
/// see that field's doc comment) even though the mockup's own "transfer
/// this month" strip implies otherwise; the stricter, tested rule wins per
/// CLAUDE.md's "flag conflicts, don't silently override" instruction — this
/// is that flag.
///
/// Reads/drives the same `selectedMonthProvider` as `TransactionsPage` (DoD:
/// "shared state, not a second independent selector").
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  Future<void> _refresh(WidgetRef ref, int year, int month) async {
    ref.invalidate(dashboardSummaryProvider(year, month));
    await ref.read(dashboardSummaryProvider(year, month).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final year = month.year;
    final monthNum = month.month;
    final summaryAsync = ref.watch(dashboardSummaryProvider(year, monthNum));
    final accountsAsync = ref.watch(activeAccountsProvider);
    final recentTransactions = ref.watch(monthTransactionsProvider(year, monthNum)).value ?? const [];
    final categories = ref.watch(allCategoriesProvider).value ?? const [];
    final categoriesById = {for (final c in categories) c.id: c};

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _monthArrow(icon: RemixIcon.arrowLeftSLine, onTap: () => ref.read(selectedMonthProvider.notifier).previous()),
            const SizedBox(width: 10),
            Text(monthYearLabel(month), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(width: 10),
            _monthArrow(icon: RemixIcon.arrowRightSLine, onTap: () => ref.read(selectedMonthProvider.notifier).next()),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref, year, monthNum),
        child: summaryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text('โหลดสรุปไม่สำเร็จ: ${_errorMessage(error)}')),
              ),
            ],
          ),
          data: (summary) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TotalsCard(summary: summary),
              const SizedBox(height: 12),
              const Text('บัญชี', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 9),
              accountsAsync.when(
                loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                error: (error, _) => Text('โหลดบัญชีไม่สำเร็จ: $error'),
                data: (accounts) => accounts.isEmpty
                    ? const Text('ยังไม่มีบัญชี', style: TextStyle(color: AppColors.textMuted))
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [for (final a in accounts) Expanded(child: _AccountMiniCard(account: a))]
                            .expand((w) => [w, const SizedBox(width: 8)])
                            .take(accounts.length * 2 - 1)
                            .toList(),
                      ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('รายจ่ายตามหมวดหมู่', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    if (summary.expense.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('ไม่มีรายจ่ายในเดือนนี้', style: TextStyle(color: AppColors.textMuted))),
                      )
                    else
                      ExpensePieChart(expense: summary.expense, total: summary.totalExpense),
                  ],
                ),
              ),
              if (recentTransactions.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('ธุรกรรมล่าสุด', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                const SizedBox(height: 9),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < recentTransactions.length.clamp(0, 5); i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.divider),
                        TransactionListTile(transaction: recentTransactions[i], categoriesById: categoriesById),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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

  // dashboardSummaryProvider surfaces a Left(Failure) as a thrown value (see
  // dashboard_providers.dart) purely so AsyncValue can carry it — unwrap
  // back to its message here rather than printing a raw Dart object.
  String _errorMessage(Object error) => error is Failure ? (error.message ?? 'โหลดสรุปไม่สำเร็จ') : error.toString();
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: _TotalColumn(label: 'รายรับ', icon: RemixIcon.arrowDownLine, amount: summary.totalIncome, color: AppColors.income),
          ),
          Container(width: 1, height: 40, color: AppColors.divider),
          const SizedBox(width: 16),
          Expanded(
            child: _TotalColumn(label: 'รายจ่าย', icon: RemixIcon.arrowUpLine, amount: summary.totalExpense, color: AppColors.expense),
          ),
        ],
      ),
    );
  }
}

class _TotalColumn extends StatelessWidget {
  const _TotalColumn({required this.label, required this.icon, required this.amount, required this.color});

  final String label;
  final IconData icon;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: color)),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          formatAmount(amount),
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24, color: color),
        ),
      ],
    );
  }
}

class _AccountMiniCard extends ConsumerWidget {
  const _AccountMiniCard({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bankIcon = resolveBankIcon(account.bankIcon);
    final name = account.name;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: bankIcon.color, borderRadius: BorderRadius.circular(6)),
                child: Center(child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600))),
              ),
              const SizedBox(width: 7),
              Expanded(child: Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
            ],
          ),
          const SizedBox(height: 9),
          CurrentBalanceText(accountId: account.id, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ],
      ),
    );
  }
}

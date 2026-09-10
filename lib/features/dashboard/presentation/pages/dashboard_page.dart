import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/month/selected_month_provider.dart';
import '../../../../core/network/failure.dart';
import '../../domain/dashboard_summary.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/expense_pie_chart.dart';

/// Reads/drives the same `selectedMonthProvider` as `TransactionsPage` (DoD:
/// "shared state, not a second independent selector") — no local scroll
/// state or pagination needed here (unlike the feed), so a plain
/// `ConsumerWidget` is enough.
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => ref.read(selectedMonthProvider.notifier).previous(),
              ),
              Text(monthYearLabel(month), style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => ref.read(selectedMonthProvider.notifier).next(),
              ),
            ],
          ),
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
                child: Center(child: Text('Failed to load summary: ${_errorMessage(error)}')),
              ),
            ],
          ),
          data: (summary) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TotalsCard(summary: summary),
              const SizedBox(height: 24),
              Text('Expenses by category', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (summary.expense.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('No expenses this month')),
                )
              else
                ExpensePieChart(expense: summary.expense),
            ],
          ),
        ),
      ),
    );
  }

  // dashboardSummaryProvider surfaces a Left(Failure) as a thrown value (see
  // dashboard_providers.dart) purely so AsyncValue can carry it — unwrap
  // back to its message here rather than printing a raw Dart object.
  String _errorMessage(Object error) => error is Failure ? (error.message ?? 'Failed to load summary') : error.toString();
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _TotalColumn(label: 'Income', amount: summary.totalIncome, color: const Color(0xFF16A34A)),
            _TotalColumn(label: 'Expense', amount: summary.totalExpense, color: const Color(0xFFDC2626)),
            _TotalColumn(label: 'Net', amount: summary.net, color: Theme.of(context).colorScheme.onSurface),
          ],
        ),
      ),
    );
  }
}

class _TotalColumn extends StatelessWidget {
  const _TotalColumn({required this.label, required this.amount, required this.color});

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(amount.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

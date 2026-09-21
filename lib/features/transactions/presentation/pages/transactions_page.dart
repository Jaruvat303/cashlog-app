import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../../../core/month/selected_month_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/format/money.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../../../../shared/widgets/gradient_hero_card.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/providers/accounts_providers.dart';
import '../../../accounts/presentation/widgets/current_balance_text.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/categories_providers.dart';
import '../../../dashboard/domain/dashboard_summary.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../dashboard/presentation/widgets/expense_pie_chart.dart';
import '../../domain/transaction.dart';
import '../providers/pending_actions_providers.dart';
import '../providers/transactions_feed_providers.dart';
import '../widgets/transaction_list_tile.dart';
import 'pending_actions_page.dart';

/// How close to the bottom (in pixels) triggers the next page fetch.
const double _kLoadMoreThreshold = 300;

/// Ticket 07's summary tabs — Transfer's real content (a flat, ungrouped
/// list) is ticket 08, blocked on this one; `_SummarySection` below only
/// renders a placeholder for it here.
enum _SummaryTab { income, expense, transfer }

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final _scrollController = ScrollController();
  _SummaryTab _summaryTab = _SummaryTab.expense;

  /// Ticket 10: which category (if any) the transaction list below the
  /// summary card is currently narrowed to — `null` means "no filter".
  /// Cleared automatically on every month switch (`_switchMonth`) and every
  /// summary-tab change (`_onSummaryTabChanged`) so it never silently
  /// carries over into a context it wasn't set for (the exact "leftover
  /// filter state" bug ticket 08 removed the whole feature over — this time
  /// the clear is unconditional and structural, not a UI affordance the
  /// user has to remember to use).
  int? _categoryFilterId;

  /// Ticket 12: the transaction type to scope [_categoryFilterId] by, so an
  /// active filter never leaks rows from an unrelated type into the list —
  /// most visibly, [kUncategorizedCategoryId] on its own matches every
  /// transfer too (transfers never carry a category), which used to show up
  /// under an Uncategorized filter opened from the Expense tab. `null` while
  /// no filter is active, matching [_categoryFilterId]'s own null-means-
  /// unfiltered convention — category rows only ever render on the
  /// Income/Expense tabs (never Transfer), so this never needs a transfer
  /// case.
  TransactionType? get _categoryFilterType {
    if (_categoryFilterId == null) return null;
    return switch (_summaryTab) {
      _SummaryTab.income => TransactionType.income,
      _SummaryTab.expense => TransactionType.expense,
      _SummaryTab.transfer => null,
    };
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Cache paints first via monthTransactionsProvider's drift watch; this
    // kicks off the paged API sync for the currently selected month
    // (CLAUDE.md: online-only + read cache). Silent, same as
    // Accounts/CategoriesPage's initial load — the cached list is already
    // on screen either way.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final month = ref.read(selectedMonthProvider);
      _loadFirstPage(month.year, month.month, showErrorSnackBar: false);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels < _scrollController.position.maxScrollExtent - _kLoadMoreThreshold) return;
    final month = ref.read(selectedMonthProvider);
    ref.read(transactionsFeedSyncProvider(month.year, month.month).notifier).loadNextPage();
  }

  Future<void> _loadFirstPage(int year, int month, {bool showErrorSnackBar = true}) async {
    final result = await ref.read(transactionsFeedSyncProvider(year, month).notifier).loadFirstPage();
    if (!mounted || !showErrorSnackBar) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message ?? 'รีเฟรชรายการไม่สำเร็จ'))),
      (_) {},
    );
  }

  void _switchMonth(void Function() mutateSelection) {
    mutateSelection();
    final month = ref.read(selectedMonthProvider);
    // A new month's data is a different list entirely — jump back to the
    // top rather than leaving the scroll offset wherever it was.
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    // Ticket 10: a category filter scoped to the old month makes no sense
    // once the month itself has changed — clear it unconditionally rather
    // than leaving a stale, invisible-until-you-notice-the-list-is-short
    // filter active.
    setState(() => _categoryFilterId = null);
    _loadFirstPage(month.year, month.month, showErrorSnackBar: false);
  }

  void _onSummaryTabChanged(_SummaryTab tab) {
    setState(() {
      _summaryTab = tab;
      // Ticket 10: same reasoning as `_switchMonth` — a category filter
      // picked while looking at Expense totals doesn't mean anything once
      // the tab switches to Income (different categories entirely) or
      // Transfer (no categories at all), so it's cleared unconditionally
      // rather than left to silently narrow a list it was never meant to.
      _categoryFilterId = null;
    });
  }

  void _toggleCategoryFilter(int categoryId) {
    setState(() => _categoryFilterId = _categoryFilterId == categoryId ? null : categoryId);
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedMonthProvider);
    final year = month.year;
    final monthNum = month.month;

    final transactionsAsync = ref.watch(
      monthTransactionsProvider(year, monthNum, categoryId: _categoryFilterId, type: _categoryFilterType),
    );
    final feedMeta = ref.watch(transactionsFeedSyncProvider(year, monthNum));
    final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
    final categoriesById = {for (final category in categories) category.id: category};
    final isLoadingMore = feedMeta?.isLoadingMore ?? false;
    // T13's entry point: a badge count off the same drift-backed stream
    // PendingActionsPage itself watches, so it always reflects the queue
    // exactly, never a stale snapshot.
    final pendingCount = ref.watch(pendingActionsProvider).value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        // Post-launch redesign ticket 04: the month switcher moves out of
        // the secondary row below and into the title slot, matching how
        // `DashboardPage`'s own month switcher is already positioned.
        // Post-launch UI polish ticket 02: explicit `centerTitle: true`
        // (the app theme's `AppBarTheme.centerTitle` default is `false`,
        // left-aligning the title) so this is the dead-center primary
        // navigation control the spec calls for, not tucked to one side.
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _monthArrow(
              icon: RemixIcon.arrowLeftSLine,
              onTap: () => _switchMonth(() => ref.read(selectedMonthProvider.notifier).previous()),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () => _openMonthYearPicker(month),
              borderRadius: BorderRadius.circular(11),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(11)),
                child: Text(monthYearShortLabel(month), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 10),
            _monthArrow(
              icon: RemixIcon.arrowRightSLine,
              onTap: () => _switchMonth(() => ref.read(selectedMonthProvider.notifier).next()),
            ),
          ],
        ),
        actions: [
          // Ticket 04: the page-level manual-entry "+" button is removed —
          // the same action is now reachable from the global FAB (ticket 05).
          IconButton(
            key: const Key('pendingActionsButton'),
            icon: Badge(label: Text('$pendingCount'), isLabelVisible: pendingCount > 0, child: const Icon(RemixIcon.errorWarningLine)),
            tooltip: 'รายการค้าง',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PendingActionsPage())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadFirstPage(year, monthNum),
        child: transactionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('โหลดรายการไม่สำเร็จ: $error')),
          data: (transactions) {
            final summarySection = _SummarySection(
              year: year,
              month: monthNum,
              tab: _summaryTab,
              onTabChanged: _onSummaryTabChanged,
              selectedCategoryId: _categoryFilterId,
              onCategoryTap: _toggleCategoryFilter,
              categoriesById: categoriesById,
            );

            if (transactions.isEmpty) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  const _AccountInfoStrip(),
                  const SizedBox(height: 16),
                  summarySection,
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(_categoryFilterId == null ? 'ไม่มีรายการในเดือนนี้' : 'ไม่มีรายการในหมวดหมู่นี้'),
                    ),
                  ),
                ],
              );
            }

            final groups = _groupByDay(transactions);
            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              // +2 for the account-info strip and summary section header at
              // indices 0/1 — everything else keeps its previous index math
              // shifted accordingly.
              itemCount: 2 + groups.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(padding: EdgeInsets.only(bottom: 16), child: _AccountInfoStrip());
                }
                if (index == 1) {
                  return Padding(padding: const EdgeInsets.only(bottom: 14), child: summarySection);
                }
                final groupIndex = index - 2;
                if (groupIndex >= groups.length) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator()));
                }
                final group = groups[groupIndex];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              relativeDayLabel(group.date),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                            Text(
                              _formatSignedTotal(group.total),
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadii.cardLarge),
                          boxShadow: const [AppShadows.card],
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < group.transactions.length; i++) ...[
                              if (i > 0) const Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.divider),
                              TransactionListTile(transaction: group.transactions[i], categoriesById: categoriesById),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Ticket 07: the month arrows only step one month at a time, so tapping
  /// the label itself opens a picker that can jump to any month/year —
  /// a bottom sheet with its own transient year (the sheet's `pickerYear`)
  /// so browsing years doesn't move [SelectedMonth] until a month is
  /// actually tapped.
  void _openMonthYearPicker(DateTime currentMonth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet))),
      builder: (sheetContext) {
        var pickerYear = currentMonth.year;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _monthArrow(icon: RemixIcon.arrowLeftSLine, onTap: () => setSheetState(() => pickerYear--)),
                      const SizedBox(width: 20),
                      Text('${buddhistYear(pickerYear)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(width: 20),
                      _monthArrow(icon: RemixIcon.arrowRightSLine, onTap: () => setSheetState(() => pickerYear++)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.6,
                    children: List.generate(12, (i) {
                      final m = i + 1;
                      final selected = pickerYear == currentMonth.year && m == currentMonth.month;
                      return InkWell(
                        borderRadius: BorderRadius.circular(AppRadii.control),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _switchMonth(() => ref.read(selectedMonthProvider.notifier).set(pickerYear, m));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary : AppColors.background,
                            borderRadius: BorderRadius.circular(AppRadii.control),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            monthAbbreviationTh(m),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: selected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _monthArrow({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }

  List<_DayGroup> _groupByDay(List<Transaction> transactions) {
    final groups = <DateTime, List<Transaction>>{};
    for (final t in transactions) {
      final day = DateTime(t.transactionDate.year, t.transactionDate.month, t.transactionDate.day);
      groups.putIfAbsent(day, () => []).add(t);
    }
    return groups.entries
        .map(
          (entry) => _DayGroup(
            date: entry.key,
            transactions: entry.value,
            // Transfers are deliberately excluded from the day total, same
            // as the monthly summary (CLAUDE.md/DoD: a transfer moves money
            // between the user's own accounts, neither income nor expense).
            total: entry.value.fold(
              0.0,
              (sum, t) => switch (t.type) {
                TransactionType.income => sum + t.amount,
                TransactionType.expense => sum - t.amount,
                TransactionType.transfer => sum,
              },
            ),
          ),
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  String _formatSignedTotal(double total) => formatAmount(total, sign: total > 0 ? '+' : '');
}

class _DayGroup {
  const _DayGroup({required this.date, required this.transactions, required this.total});
  final DateTime date;
  final List<Transaction> transactions;
  final double total;
}

/// Post-launch redesign ticket 04: the accounts strip (mini balance cards)
/// moved here from `DashboardPage` — this page is the single place it
/// renders now, not a second copy. `current_balance` is a derived stream
/// (`AccountsRepository.watchCurrentBalance`), so it stays correct across a
/// month switch on its own without needing to watch `selectedMonthProvider`
/// itself.
class _AccountInfoStrip extends ConsumerWidget {
  const _AccountInfoStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(activeAccountsProvider);
    return Column(
      key: const Key('accountInfoStrip'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('บัญชี', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
        const SizedBox(height: 9),
        accountsAsync.when(
          loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
          error: (error, _) => Text('โหลดบัญชีไม่สำเร็จ: $error'),
          data: (accounts) => accounts.isEmpty
              ? const Text('ยังไม่มีบัญชี', style: TextStyle(color: AppColors.textSecondary))
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [for (final a in accounts) Expanded(child: _AccountMiniCard(account: a))]
                      .expand((w) => [w, const SizedBox(width: 8)])
                      .take(accounts.length * 2 - 1)
                      .toList(),
                ),
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
    final name = account.name;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return GradientHeroCard(
      borderRadius: AppRadii.cardLarge,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(6)),
                child: Center(child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))),
              ),
              const SizedBox(width: 7),
              Expanded(child: Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white))),
            ],
          ),
          const SizedBox(height: 10),
          CurrentBalanceText(
            accountId: account.id,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white),
            // Post-launch UI polish ticket 03: this card's subtitle shows the
            // account's own `matching_keywords` (already fetched, no new
            // endpoint) instead of the generic BR-7 balance disclaimer every
            // other `CurrentBalanceText` caller still shows.
            subtitle: account.matchingKeywords.isEmpty ? '—' : account.matchingKeywords.join(', '),
            subtitleStyle: const TextStyle(fontSize: 11, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Ticket 07 (Design 3, summary half): the category/amount summary that
/// ticket 06 detached from the Home page, relocated here as a tabbed
/// section above the transaction list. Income/Expense source the exact same
/// `dashboardSummaryProvider(year, month)` the old Dashboard pie chart used
/// — no new backend call, per spec — and render a `{category_name,
/// total_amount}` list; ticket 03 puts the pie chart itself back above that
/// list (see `_CategoryBreakdownSection`). Ticket 08: Transfer instead sources
/// `monthTransactionsProvider` directly (transfers carry no `category_id`,
/// so the dashboard summary's per-category breakdown has nothing to offer
/// it) and renders a flat, ungrouped list of transfer transactions.
class _SummarySection extends ConsumerWidget {
  const _SummarySection({
    required this.year,
    required this.month,
    required this.tab,
    required this.onTabChanged,
    required this.selectedCategoryId,
    required this.onCategoryTap,
    required this.categoriesById,
  });

  final int year;
  final int month;
  final _SummaryTab tab;
  final ValueChanged<_SummaryTab> onTabChanged;
  final int? selectedCategoryId;
  final ValueChanged<int> onCategoryTap;
  final Map<int, Category> categoriesById;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      key: const Key('transactionsSummarySection'),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.cardLarge), boxShadow: const [AppShadows.card]),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _tabButton('รายรับ', _SummaryTab.income),
              const SizedBox(width: 8),
              _tabButton('รายจ่าย', _SummaryTab.expense),
              const SizedBox(width: 8),
              _tabButton('ย้ายเงิน', _SummaryTab.transfer),
            ],
          ),
          const SizedBox(height: 12),
          // Ticket 08: Transfer is built outside the dashboard-summary
          // `.when` below — it has its own independent data source
          // (`monthTransactionsProvider`, not `dashboardSummaryProvider`),
          // so a loading/error state on the dashboard summary must never
          // block or blank out the Transfer tab.
          if (tab == _SummaryTab.transfer)
            _TransferList(year: year, month: month, categoriesById: categoriesById)
          else
            Consumer(
              builder: (context, ref, _) {
                final summaryAsync = ref.watch(dashboardSummaryProvider(year, month));
                return summaryAsync.when(
                  loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator())),
                  error: (error, _) =>
                      Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text('โหลดสรุปไม่สำเร็จ: $error')),
                  data: (summary) => switch (tab) {
                    _SummaryTab.income => _CategoryBreakdownSection(
                      breakdown: summary.income,
                      total: summary.totalIncome,
                      selectedCategoryId: selectedCategoryId,
                      onTap: onCategoryTap,
                      emptyMessage: 'ไม่มีรายรับในเดือนนี้',
                    ),
                    _SummaryTab.expense => _CategoryBreakdownSection(
                      breakdown: summary.expense,
                      total: summary.totalExpense,
                      selectedCategoryId: selectedCategoryId,
                      onTap: onCategoryTap,
                      emptyMessage: 'ไม่มีรายจ่ายในเดือนนี้',
                    ),
                    _SummaryTab.transfer => const SizedBox.shrink(),
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, _SummaryTab value) {
    final selected = tab == value;
    return Expanded(
      child: InkWell(
        key: Key('summaryTab-${value.name}'),
        onTap: () => onTabChanged(value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.chipSelectedBg : AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ticket 03: the restored `ExpensePieChart` (already built, previously
/// unused — see its own file) sits above the existing `_CategoryTotalsList`
/// text list for the Income/Expense tabs. The chart is only built when
/// there's a breakdown to show it for — an empty breakdown falls straight
/// through to `_CategoryTotalsList`'s own empty-state message, same as
/// before this ticket.
///
/// Ticket 10: tap-to-filter is back (ticket 08 removed it along with the
/// AppBar chip row it used to display/clear the filter) — this time the
/// filter is toggled by tapping the same row again, and cleared
/// automatically on month/tab changes (see `TransactionsPage._switchMonth`/
/// `_onSummaryTabChanged`), so there's no separate "clear" affordance to
/// leave behind.
class _CategoryBreakdownSection extends StatelessWidget {
  const _CategoryBreakdownSection({
    required this.breakdown,
    required this.total,
    required this.selectedCategoryId,
    required this.onTap,
    required this.emptyMessage,
  });

  final List<CategoryBreakdown> breakdown;
  final double total;
  final int? selectedCategoryId;
  final ValueChanged<int> onTap;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (breakdown.isNotEmpty) ...[
          ExpensePieChart(expense: breakdown, total: total),
          const SizedBox(height: 14),
        ],
        _CategoryTotalsList(breakdown: breakdown, selectedCategoryId: selectedCategoryId, onTap: onTap, emptyMessage: emptyMessage),
      ],
    );
  }
}

/// Plain text rows (spec: "category names shown in the list, not on the
/// chart itself"), sorted descending by amount — restored above by
/// `_CategoryBreakdownSection`'s `ExpensePieChart` (ticket 03), unchanged
/// itself.
class _CategoryTotalsList extends StatelessWidget {
  const _CategoryTotalsList({
    required this.breakdown,
    required this.selectedCategoryId,
    required this.onTap,
    required this.emptyMessage,
  });

  final List<CategoryBreakdown> breakdown;
  final int? selectedCategoryId;
  final ValueChanged<int> onTap;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text(emptyMessage, style: const TextStyle(color: AppColors.textSecondary))),
      );
    }

    final sorted = [...breakdown]..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return Column(
      children: [
        for (var i = 0; i < sorted.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.divider),
          _CategoryTotalRow(
            breakdown: sorted[i],
            selected: sorted[i].categoryId == selectedCategoryId,
            onTap: () => onTap(sorted[i].categoryId),
          ),
        ],
      ],
    );
  }
}

class _CategoryTotalRow extends StatelessWidget {
  const _CategoryTotalRow({required this.breakdown, required this.selected, required this.onTap});

  final CategoryBreakdown breakdown;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('categoryTotalRow-${breakdown.categoryId}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : null,
          borderRadius: BorderRadius.circular(10),
          border: selected ? Border.all(color: AppColors.primarySurfaceBorder) : null,
        ),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: colorFromHex(breakdown.colorHex), borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Expanded(
              child: Text(breakdown.categoryName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
            ),
            Text(formatAmount(breakdown.totalAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

/// Ticket 08: a flat, ungrouped list of the current scope's transfer
/// transactions — deliberately sourced from `monthTransactionsProvider`
/// directly (never with a `categoryId` argument) rather than
/// `dashboardSummaryProvider`, since transfers carry no `category_id` for
/// that endpoint's per-category breakdown to report. Reusing the plain,
/// non-`categoryId` call also keeps this tab's content independent of
/// whatever category drill-through (ticket 07) is active on the Income/
/// Expense tabs — switching to Transfer and back never loses or corrupts
/// that filter, and the Transfer tab is never emptied by it either. No
/// grouping by account pair or any other dimension (spec: Design 3) — same
/// `TransactionListTile` row used by the plain feed below, just without the
/// day-grouping headers that list applies.
class _TransferList extends ConsumerWidget {
  const _TransferList({required this.year, required this.month, required this.categoriesById});

  final int year;
  final int month;
  final Map<int, Category> categoriesById;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(monthTransactionsProvider(year, month));

    return transactionsAsync.when(
      loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text('โหลดรายการย้ายเงินไม่สำเร็จ: $error')),
      data: (transactions) {
        final transfers = transactions.where((t) => t.type == TransactionType.transfer).toList();
        if (transfers.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('ไม่มีรายการย้ายเงินในเดือนนี้', style: TextStyle(color: AppColors.textSecondary))),
          );
        }
        return Column(
          key: const Key('transferTabList'),
          children: [
            for (var i = 0; i < transfers.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.divider),
              TransactionListTile(transaction: transfers[i], categoriesById: categoriesById),
            ],
          ],
        );
      },
    );
  }
}

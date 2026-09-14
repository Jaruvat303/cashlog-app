import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../../../core/month/selected_month_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/format/money.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/categories_providers.dart';
import '../../../dashboard/domain/dashboard_summary.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../domain/transaction.dart';
import '../providers/pending_actions_providers.dart';
import '../providers/transactions_feed_providers.dart';
import '../widgets/transaction_list_tile.dart';
import 'pending_actions_page.dart';
import 'transaction_form_page.dart';

/// How close to the bottom (in pixels) triggers the next page fetch.
const double _kLoadMoreThreshold = 300;

/// Mockup 1b's filter chip row ("ทั้งหมด"/"รายรับ"/"รายจ่าย"/"ไม่ระบุหมวด N")
/// — purely a client-side filter over whatever page(s) are already loaded
/// for the month, same "count from local cache" pattern CLAUDE.md already
/// establishes for the category-delete guard. No new backend query.
enum _TxFilter { all, income, expense, uncategorized }

bool _isUncategorized(Transaction t) => t.type != TransactionType.transfer && t.categoryId == null;

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
  _TxFilter _filter = _TxFilter.all;
  _SummaryTab _summaryTab = _SummaryTab.expense;

  /// Ticket 07's drill-through state: which category (if any) the
  /// transaction list below the summary is currently narrowed to. `null`
  /// means "no filter" — the same call shape every other
  /// `monthTransactionsProvider` caller already uses, so this is additive,
  /// not a parallel query path.
  int? _categoryFilterId;
  String? _categoryFilterName;

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
    _loadFirstPage(month.year, month.month, showErrorSnackBar: false);
  }

  /// Ticket 07's drill-through: a tapped category row in the summary section
  /// narrows the list below to just that category — resets the old type
  /// chip filter back to "all" since a categoryId already implies a single
  /// type (a category is only ever income- or expense-typed), so the two
  /// filters would otherwise double up on the same axis.
  void _selectCategoryFilter(int categoryId, String categoryName) {
    setState(() {
      _categoryFilterId = categoryId;
      _categoryFilterName = categoryName;
      _filter = _TxFilter.all;
    });
  }

  void _clearCategoryFilter() {
    setState(() {
      _categoryFilterId = null;
      _categoryFilterName = null;
    });
  }

  List<Transaction> _applyFilter(List<Transaction> transactions) => switch (_filter) {
    _TxFilter.all => transactions,
    _TxFilter.income => transactions.where((t) => t.type == TransactionType.income).toList(),
    _TxFilter.expense => transactions.where((t) => t.type == TransactionType.expense).toList(),
    _TxFilter.uncategorized => transactions.where(_isUncategorized).toList(),
  };

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedMonthProvider);
    final year = month.year;
    final monthNum = month.month;

    final transactionsAsync = ref.watch(monthTransactionsProvider(year, monthNum, categoryId: _categoryFilterId));
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
        title: const Text('รายการ'),
        actions: [
          // T6's manual-entry entry point (mockup 1e) — the AppShell's FAB
          // slot is taken by the camera/auto-scan button (T21), so this
          // stays a page-level action rather than a second FAB.
          IconButton(
            key: const Key('newTransactionButton'),
            icon: const Icon(RemixIcon.addLine),
            tooltip: 'สร้างรายการเอง',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TransactionFormPage())),
          ),
          IconButton(
            key: const Key('pendingActionsButton'),
            icon: Badge(label: Text('$pendingCount'), isLabelVisible: pendingCount > 0, child: const Icon(RemixIcon.errorWarningLine)),
            tooltip: 'รายการค้าง',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PendingActionsPage())),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _monthArrow(
                    icon: RemixIcon.arrowLeftSLine,
                    onTap: () => _switchMonth(() => ref.read(selectedMonthProvider.notifier).previous()),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: AppColors.screenBackground, borderRadius: BorderRadius.circular(11)),
                    child: Text(monthYearShortLabel(month), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  _monthArrow(
                    icon: RemixIcon.arrowRightSLine,
                    onTap: () => _switchMonth(() => ref.read(selectedMonthProvider.notifier).next()),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                // Ticket 07: an active category drill-through replaces the
                // type chip row with a single clearable filter chip — both
                // filter the same list, so showing them side by side would
                // just be two controls fighting over one axis.
                child: _categoryFilterId == null
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _filterChip('ทั้งหมด', _TxFilter.all),
                            const SizedBox(width: 7),
                            _filterChip('รายรับ', _TxFilter.income),
                            const SizedBox(width: 7),
                            _filterChip('รายจ่าย', _TxFilter.expense),
                            const SizedBox(width: 7),
                            _uncategorizedChip(transactionsAsync.value ?? const []),
                          ],
                        ),
                      )
                    : Align(alignment: Alignment.centerLeft, child: _categoryFilterChip()),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadFirstPage(year, monthNum),
        child: transactionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('โหลดรายการไม่สำเร็จ: $error')),
          data: (transactions) {
            final filtered = _applyFilter(transactions);
            final summarySection = _SummarySection(
              year: year,
              month: monthNum,
              tab: _summaryTab,
              onTabChanged: (tab) => setState(() => _summaryTab = tab),
              selectedCategoryId: _categoryFilterId,
              onCategoryTap: _selectCategoryFilter,
              categoriesById: categoriesById,
            );

            if (filtered.isEmpty) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  summarySection,
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text(transactions.isEmpty ? 'ไม่มีรายการในเดือนนี้' : 'ไม่มีรายการตรงตามตัวกรอง')),
                  ),
                ],
              );
            }

            final groups = _groupByDay(filtered);
            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              // +1 for the summary section header at index 0 — everything
              // else keeps its previous index math shifted by one.
              itemCount: 1 + groups.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(padding: const EdgeInsets.only(bottom: 14), child: summarySection);
                }
                final groupIndex = index - 1;
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
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11.5, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(18),
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

  Widget _filterChip(String label, _TxFilter value) {
    final selected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.chipSelectedBg : AppColors.chipUnselectedBg,
          border: selected ? null : Border.all(color: AppColors.chipUnselectedBorder),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
            color: selected ? Colors.white : AppColors.chipUnselectedText,
          ),
        ),
      ),
    );
  }

  Widget _uncategorizedChip(List<Transaction> monthTransactions) {
    final count = monthTransactions.where(_isUncategorized).length;
    final selected = _filter == _TxFilter.uncategorized;
    return InkWell(
      onTap: () => setState(() => _filter = _TxFilter.uncategorized),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.chipSelectedBg : AppColors.warningBadgeBg,
          border: selected ? null : Border.all(color: AppColors.warningBadgeBorder),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'ไม่ระบุหมวด $count',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.warningText),
        ),
      ),
    );
  }

  /// Ticket 07's "a way exists to clear the filter" requirement — a single
  /// clearable chip standing in for the whole type-chip row while a category
  /// drill-through is active.
  Widget _categoryFilterChip() {
    return InkWell(
      key: const Key('categoryFilterChip'),
      onTap: _clearCategoryFilter,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: AppColors.chipSelectedBg, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('หมวดหมู่: ${_categoryFilterName ?? ''}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Colors.white)),
            const SizedBox(width: 6),
            const Icon(RemixIcon.closeLine, size: 13, color: Colors.white),
          ],
        ),
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

/// Ticket 07 (Design 3, summary half): the category/amount summary that
/// ticket 06 detached from the Home page, relocated here as a tabbed
/// section above the transaction list. Income/Expense source the exact same
/// `dashboardSummaryProvider(year, month)` the old Dashboard pie chart used
/// — no new backend call, per spec — and render a plain
/// `{category_name, total_amount}` list (replacing the old
/// pie-chart-with-labels approach). Ticket 08: Transfer instead sources
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
  final void Function(int categoryId, String categoryName) onCategoryTap;
  final Map<int, Category> categoriesById;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      key: const Key('transactionsSummarySection'),
      decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(20)),
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
                    _SummaryTab.income => _CategoryTotalsList(
                      breakdown: summary.income,
                      selectedCategoryId: selectedCategoryId,
                      onTap: onCategoryTap,
                      emptyMessage: 'ไม่มีรายรับในเดือนนี้',
                    ),
                    _SummaryTab.expense => _CategoryTotalsList(
                      breakdown: summary.expense,
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
            color: selected ? AppColors.chipSelectedBg : AppColors.screenBackground,
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

/// Plain text rows (spec: "category names shown in the list, not on the
/// chart itself"), sorted descending by amount — same DoD `ExpensePieChart`
/// already followed, just without the chart.
class _CategoryTotalsList extends StatelessWidget {
  const _CategoryTotalsList({
    required this.breakdown,
    required this.selectedCategoryId,
    required this.onTap,
    required this.emptyMessage,
  });

  final List<CategoryBreakdown> breakdown;
  final int? selectedCategoryId;
  final void Function(int categoryId, String categoryName) onTap;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text(emptyMessage, style: const TextStyle(color: AppColors.textMuted))),
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
            onTap: () => onTap(sorted[i].categoryId, sorted[i].categoryName),
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
            child: Center(child: Text('ไม่มีรายการย้ายเงินในเดือนนี้', style: TextStyle(color: AppColors.textMuted))),
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

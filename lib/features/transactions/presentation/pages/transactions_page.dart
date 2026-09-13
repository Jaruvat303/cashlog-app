import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../../../core/month/selected_month_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/format/money.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/categories_providers.dart';
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

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final _scrollController = ScrollController();
  _TxFilter _filter = _TxFilter.all;

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

    final transactionsAsync = ref.watch(monthTransactionsProvider(year, monthNum));
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
                child: SingleChildScrollView(
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
                ),
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
            if (filtered.isEmpty) {
              return ListView(
                children: [
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
              itemCount: groups.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= groups.length) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator()));
                }
                final group = groups[index];
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

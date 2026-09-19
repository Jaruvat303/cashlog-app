import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../../../core/month/selected_month_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/format/money.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../categories/presentation/providers/categories_providers.dart';
import '../../../slip_scan/data/slip_gallery_repository.dart';
import '../../../slip_scan/domain/gallery_access_level.dart';
import '../../../slip_scan/presentation/providers/slip_scan_pipeline_provider.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/providers/transactions_feed_providers.dart';
import '../../../transactions/presentation/widgets/transaction_list_tile.dart';
import '../widgets/auto_scan_processing_indicator.dart';
import '../widgets/expense_total_widget.dart';
import '../widgets/pending_actions_banner.dart';

/// How close to the bottom (in pixels) triggers the next page fetch — mirrors
/// `TransactionsPage`'s own threshold, since this page now drives the exact
/// same paged fetch model.
const double _kLoadMoreThreshold = 300;

/// Post-launch redesign ticket 06: Home is no longer a "needs attention"
/// queue that drops a row the moment it gets a category — that was the
/// original bug (spec Problem Statement, 4th bullet). This page now sources
/// the same full, paginated, per-month transaction query `TransactionsPage`
/// uses (`monthTransactionsProvider` + `TransactionsFeedSync`), grouped by
/// day within the selected month, so a transaction stays visible for the
/// whole month regardless of its category state.
///
/// Reads/drives the same `selectedMonthProvider` as `TransactionsPage` (DoD:
/// "shared state, not a second independent selector"), which already
/// defaults to the current month on first build — see
/// `SelectedMonth.build()`.
///
/// The accounts strip (mini balance cards) moved off this page to
/// `TransactionsPage`/"ดูสรุป" in ticket 04 and is not reintroduced here.
///
/// Ticket 07 adds [ExpenseTotalWidget] as the leading item above the day
/// groups. Ticket 08 adds [PendingActionsBanner] directly beneath it,
/// grouped with the other background-auto-scan status readout,
/// `_GalleryPermissionBanner`, which stays directly below it. Ticket 10 adds
/// [AutoScanProcessingIndicator] as a further leading item after that —
/// last, since it's the most transient of the three and shouldn't push the
/// steadier status readouts around while it appears/disappears.
///
/// Post-launch UI polish ticket 02: Home no longer owns the month switcher
/// (moved to `TransactionsPage`'s Topbar, the single place month switching
/// happens now) or a standalone last-auto-scan status row (folded into
/// [ExpenseTotalWidget]'s own banner) — see [_onMonthChanged].
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Cache paints first via monthTransactionsProvider's drift watch; this
    // kicks off the paged API sync for the currently selected month
    // (CLAUDE.md: online-only + read cache). Silent, same as
    // TransactionsPage's initial load — the cached list is already on
    // screen either way.
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

  /// Post-launch UI polish ticket 02: Home no longer has its own month
  /// control — `selectedMonthProvider` only ever changes from the Summary
  /// page's Topbar switcher now. This performs the same side effects the old
  /// on-widget callback did (jump the list back to the top since a new
  /// month's data is a different list entirely, kick off the new month's
  /// paged fetch), driven by [build]'s `ref.listen` below instead of a
  /// widget-level callback, so it fires no matter which page changed the
  /// shared month.
  void _onMonthChanged(DateTime month) {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _loadFirstPage(month.year, month.month, showErrorSnackBar: false);
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedMonthProvider);
    final year = month.year;
    final monthNum = month.month;
    ref.listen<DateTime>(selectedMonthProvider, (previous, next) {
      if (previous == next) return;
      _onMonthChanged(next);
    });

    final transactionsAsync = ref.watch(monthTransactionsProvider(year, monthNum));
    final feedMeta = ref.watch(transactionsFeedSyncProvider(year, monthNum));
    final categories = ref.watch(allCategoriesProvider).value ?? const [];
    final categoriesById = {for (final c in categories) c.id: c};
    final isLoadingMore = feedMeta?.isLoadingMore ?? false;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cashlog', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  CircularIconButton(icon: RemixIcon.bankCardLine, onTap: () => context.go('/accounts'), tooltip: 'บัญชี'),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadFirstPage(year, monthNum),
                child: transactionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('โหลดรายการไม่สำเร็จ: $error')),
          data: (transactions) {
            if (transactions.isEmpty) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                children: [
                  const ExpenseTotalWidget(),
                  const SizedBox(height: 16),
                  const PendingActionsBanner(),
                  const _GalleryPermissionBanner(),
                  const AutoScanProcessingIndicator(),
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('ไม่มีรายการในเดือนนี้')),
                  ),
                ],
              );
            }

            final groups = _groupByDay(transactions);
            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
              // +4 for the expense-total widget, pending-actions banner,
              // gallery-permission banner, and auto-scan processing
              // indicator at indices 0/1/2/3 — everything else keeps its
              // previous index math shifted accordingly. The last-auto-scan
              // status text moved inside the expense-total widget itself
              // (ticket 02) and no longer occupies its own index here.
              itemCount: 4 + groups.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: ExpenseTotalWidget(),
                  );
                }
                // `PendingActionsBanner`/`_GalleryPermissionBanner`/
                // `AutoScanProcessingIndicator` each supply their own bottom
                // margin when visible and collapse to a zero-size box when
                // not — no extra wrapper padding here, unlike the widget
                // above and the day groups below, or a hidden banner would
                // still leave a gap in the list.
                if (index == 1) {
                  return const PendingActionsBanner();
                }
                if (index == 2) {
                  return const _GalleryPermissionBanner();
                }
                if (index == 3) {
                  return const AutoScanProcessingIndicator();
                }
                final groupIndex = index - 4;
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
            ),
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

/// Spec Bug 1 / ticket 06: the only reachable, non-debug entry point for
/// `SlipGalleryRepository.requestAccess()`/`presentLimitedSelection()` — both
/// already existed and worked, but before this were only invoked from the
/// hidden `/debug/slip-scan` route. No change to `SlipGalleryRepository`,
/// `GalleryAccessLevel`, or the debug page itself; this widget only adds a
/// new caller.
///
/// Sourced from `SlipScanPipeline`'s own `SlipScanProgress.accessLevel`
/// (set by `runScan()`, fired automatically on cold start/resume by
/// `slipScanLifecycle` — untouched by this ticket) rather than querying the
/// gallery itself, so this banner never triggers its own permission check —
/// it only reacts to whatever the lifecycle-triggered scan already found.
/// `null` (no scan attempted yet) is treated the same as `full`: no banner,
/// since there's nothing actionable to show before the first scan has even
/// run once.
class _GalleryPermissionBanner extends ConsumerWidget {
  const _GalleryPermissionBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessLevel = ref.watch(slipScanPipelineProvider.select((p) => p.accessLevel));
    if (accessLevel == null || accessLevel == GalleryAccessLevel.full) return const SizedBox.shrink();

    final (title, body, buttonLabel, onPressed) = accessLevel == GalleryAccessLevel.denied
        ? (
            'ยังไม่ได้ให้สิทธิ์เข้าถึงคลังภาพ',
            'แอปต้องใช้สิทธิ์เข้าถึงรูปภาพเพื่อสแกนสลิปธนาคารจากอัลบั้ม SCB EASY และ Dime! โดยอัตโนมัติ',
            'ให้สิทธิ์เข้าถึง',
            () => ref.read(slipGalleryRepositoryProvider).requestAccess(),
          )
        : (
            'เข้าถึงรูปภาพแบบจำกัด',
            'แอปอาจมองไม่เห็นสลิปใหม่ ถ้าอัลบั้ม SCB EASY หรือ Dime! ไม่ได้ถูกเลือกไว้ในรายการรูปที่อนุญาต',
            'เลือกรูปเพิ่มเติม',
            () => ref.read(slipGalleryRepositoryProvider).presentLimitedSelection(),
          );

    return Container(
      key: const Key('galleryPermissionBanner'),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.warningIconBg,
        border: Border.all(color: AppColors.warningBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(RemixIcon.imageLine, size: 18, color: AppColors.warningIcon),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary))),
            ],
          ),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: OutlinedButton(onPressed: onPressed, child: Text(buttonLabel))),
        ],
      ),
    );
  }
}

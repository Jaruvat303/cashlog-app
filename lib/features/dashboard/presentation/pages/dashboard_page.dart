import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../../../core/month/selected_month_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/domain/bank_icon.dart';
import '../../../accounts/presentation/providers/accounts_providers.dart';
import '../../../accounts/presentation/widgets/current_balance_text.dart';
import '../../../categories/presentation/providers/categories_providers.dart';
import '../../../slip_scan/data/slip_gallery_repository.dart';
import '../../../slip_scan/domain/gallery_access_level.dart';
import '../../../slip_scan/presentation/providers/slip_scan_pipeline_provider.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/providers/transactions_feed_providers.dart';
import '../../../transactions/presentation/widgets/transaction_list_tile.dart';

/// Mockup screen 1a, redesigned per the fixes/redesign spec's Design 3 (Home
/// half): this page is no longer the category/amount summary — that block
/// (totals card + `ExpensePieChart`) moved to the Transaction List page's
/// Income/Expense/Transfer tabs (ticket 07's list, ticket 03's chart — see
/// `TransactionsPage`'s `_CategoryBreakdownSection`); neither is referenced
/// from here anymore. Home is now a single actionable feed: the
/// gallery-permission banner (ticket 06 /
/// spec Bug 1) at the top, an accounts strip, then transactions still
/// needing attention (junk or missing a category), most recent first.
///
/// Reads/drives the same `selectedMonthProvider` as `TransactionsPage` (DoD:
/// "shared state, not a second independent selector").
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final year = month.year;
    final monthNum = month.month;
    final accountsAsync = ref.watch(activeAccountsProvider);
    final monthTransactions = ref.watch(monthTransactionsProvider(year, monthNum)).value ?? const [];
    final categories = ref.watch(allCategoriesProvider).value ?? const [];
    final categoriesById = {for (final c in categories) c.id: c};

    final attentionItems = monthTransactions.where(_needsAttention).toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

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
        onRefresh: () => ref.read(accountsRefreshProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _GalleryPermissionBanner(),
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
            const SizedBox(height: 16),
            const Text('รายการที่ต้องดำเนินการ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(height: 9),
            if (attentionItems.isEmpty)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: const Center(child: Text('ไม่มีรายการที่ต้องดำเนินการ', style: TextStyle(color: AppColors.textMuted))),
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < attentionItems.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.divider),
                      TransactionListTile(transaction: attentionItems[i], categoriesById: categoriesById),
                    ],
                  ],
                ),
              ),
          ],
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

  /// Spec Bug 1/Design 3: a row needs attention when it's junk (spec §7.7 —
  /// any type can be junk) or, for income/expense only, still missing a
  /// category — transfers never take a category by design (see
  /// `transaction.dart`), so a `null` `categoryId` there is expected, not a
  /// gap to flag.
  static bool _needsAttention(Transaction t) =>
      t.isJunk || (t.type != TransactionType.transfer && t.categoryId == null);
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
        color: AppColors.warningSurface,
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

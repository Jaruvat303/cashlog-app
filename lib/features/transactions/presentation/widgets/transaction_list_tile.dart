import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/format/money.dart';
import '../../../accounts/presentation/providers/accounts_providers.dart';
import '../../../categories/domain/category.dart';
import '../../domain/pending_action.dart';
import '../../domain/transaction.dart';
import '../pages/transaction_form_page.dart';
import '../providers/pending_actions_providers.dart';
import 'category_quick_assign_sheet.dart';

/// One feed row (mockup screen 1b). Two independent tap targets, per
/// spec §3.2: tapping [CategoryQuickAssignChip] (the leading icon) opens the
/// quick-assign grid sheet immediately; tapping anywhere else on the row —
/// junk or not — opens the full edit page (`_edit` below). Ticket 04
/// supersedes the old junk-only edit/delete icon pair: delete now lives
/// exclusively on `TransactionFormPage`, reached the same way editing is.
///
/// T12 (junk badge): the rule in `computeIsJunk` doesn't key off
/// [TransactionType], so a junk row can in principle be any of the three
/// types — the warning row below is shared across both builders rather than
/// added to just one.
class TransactionListTile extends ConsumerWidget {
  const TransactionListTile({super.key, required this.transaction, required this.categoriesById});

  final Transaction transaction;
  final Map<int, Category> categoriesById;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (transaction.type) {
      TransactionType.transfer => _buildTransfer(context, ref),
      TransactionType.income => _buildIncomeOrExpense(context, ref, isIncome: true),
      TransactionType.expense => _buildIncomeOrExpense(context, ref, isIncome: false),
    };
  }

  Widget _buildTransfer(BuildContext context, WidgetRef ref) {
    final fromAccount = transaction.fromAccountId == null ? null : ref.watch(cachedAccountProvider(transaction.fromAccountId!)).value;
    final toAccount = transaction.toAccountId == null ? null : ref.watch(cachedAccountProvider(transaction.toAccountId!)).value;

    return _Row(
      onTap: () => _edit(context),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
        child: const Icon(RemixIcon.arrowLeftRightLine, color: AppColors.primary, size: 18),
      ),
      title: Text(
        '${fromAccount?.name ?? 'ไม่ทราบบัญชี'} → ${toAccount?.name ?? 'ไม่ทราบบัญชี'}',
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.textPrimary),
      ),
      subtitle: _subtitle(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _accountChip(fromAccount?.name),
            const SizedBox(width: 5),
            const Icon(RemixIcon.arrowRightSLine, size: 11, color: AppColors.textMuted),
            const SizedBox(width: 5),
            _accountChip(toAccount?.name),
          ],
        ),
      ),
      trailing: _trailing(
        ref,
        Text(
          formatAmount(transaction.amount),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildIncomeOrExpense(BuildContext context, WidgetRef ref, {required bool isIncome}) {
    final account = transaction.accountId == null ? null : ref.watch(cachedAccountProvider(transaction.accountId!)).value;
    final category = transaction.categoryId == null ? null : categoriesById[transaction.categoryId];

    final counterpartyName = isIncome ? transaction.senderName : transaction.receiverName;
    final title = counterpartyName.isNotEmpty
        ? counterpartyName
        : transaction.note.isNotEmpty
        ? transaction.note
        : account?.name ?? (isIncome ? 'รายรับ' : 'รายจ่าย');

    final amountColor = isIncome ? AppColors.income : AppColors.expense;
    final amountText = formatAmount(transaction.amount, sign: isIncome ? '+' : '-');

    return _Row(
      onTap: () => _edit(context),
      leading: CategoryQuickAssignChip(transaction: transaction, category: category),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.textPrimary)),
      subtitle: _subtitle(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _accountChip(account?.name),
            const SizedBox(width: 5),
            if (category != null)
              Flexible(child: Text(category.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)))
            else
              _uncategorizedBadge(),
          ],
        ),
      ),
      trailing: _trailing(
        ref,
        Text(amountText, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: amountColor)),
      ),
    );
  }

  Widget _accountChip(String? name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: AppColors.screenBackground, borderRadius: BorderRadius.circular(5)),
      child: Text(name ?? '—', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
    );
  }

  Widget _uncategorizedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warningBadgeBg,
        border: Border.all(color: AppColors.warningBadgeBorder),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Text('ยังไม่ระบุหมวดหมู่', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.warningText)),
    );
  }

  /// Appends the spec §7.7 warning line below the normal subtitle when this
  /// row is junk; passes the normal subtitle through untouched otherwise.
  Widget _subtitle(Widget normal) {
    if (!transaction.isJunk) return normal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        normal,
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 14, color: Colors.amber.shade800),
            const SizedBox(width: 4),
            Text('อ่านข้อมูลจากสลิปไม่ได้', style: TextStyle(color: Colors.amber.shade800, fontSize: 11.5)),
          ],
        ),
      ],
    );
  }

  /// Ticket 04: every row just shows its amount now, junk included — the
  /// old junk-only edit/delete icon pair is gone, since the whole row is a
  /// tap target and delete moved to `TransactionFormPage`. Bug 3 follow-up:
  /// a queued-but-not-yet-retried mutation shows a small sync indicator
  /// ahead of the amount, independent of junk status.
  Widget _trailing(WidgetRef ref, Widget normal) {
    final pendingIndicator = _pendingSyncIndicator(ref);
    if (pendingIndicator == null) return normal;
    return Row(mainAxisSize: MainAxisSize.min, children: [pendingIndicator, const SizedBox(width: 6), normal]);
  }

  /// Sourced from `PendingActionsRepository.watchAll()` (spec: Bug 3
  /// follow-up), keyed by `targetTransactionId` — reactive by construction,
  /// since it's the same drift-backed stream `PendingActionsPage` and the
  /// AppBar queue badge already watch. Returns null (no indicator) when this
  /// transaction has no open queued action, including once a manual retry
  /// from the Pending Actions page removes the row.
  Widget? _pendingSyncIndicator(WidgetRef ref) {
    final pendingActions = ref.watch(pendingActionsProvider).value ?? const <PendingAction>[];
    final hasPending = pendingActions.any((action) => action.targetTransactionId == transaction.id);
    if (!hasPending) return null;
    return const Tooltip(
      message: 'รอซิงค์ข้อมูล',
      child: Icon(RemixIcon.refreshLine, key: Key('pendingSyncIndicator'), size: 14, color: AppColors.neutralIcon),
    );
  }

  /// Opens `TransactionFormPage` for every row now, junk included (ticket
  /// 04) — fixing the amount alone is enough to clear `isJunk` once the
  /// PATCH response is re-parsed through `transactionFromJson`, since the
  /// rule is an AND across amount/senderName/receiverName. Delete for any
  /// transaction, junk or not, now lives on that page instead of here.
  void _edit(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => TransactionFormPage(initial: transaction)));
  }
}

/// Shared row chrome for both builders above — mockup 1b's card row:
/// leading icon, title/subtitle column, trailing amount, all inside a
/// bottom-divided flex row rather than a Material `ListTile` (whose fixed
/// paddings don't match the mockup's tighter 12/14 spacing).
class _Row extends StatelessWidget {
  const _Row({required this.leading, required this.title, required this.subtitle, required this.trailing, this.onTap});

  final Widget leading;
  final Widget title;
  final Widget subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('transactionRowTapTarget'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            leading,
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [title, const SizedBox(height: 3), subtitle],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}

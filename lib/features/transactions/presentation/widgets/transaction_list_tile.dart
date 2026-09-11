import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/cache_invalidator.dart';
import '../../../accounts/presentation/providers/accounts_providers.dart';
import '../../../accounts/presentation/widgets/bank_icon_avatar.dart';
import '../../../categories/domain/category.dart';
import '../../data/pending_actions_repository.dart';
import '../../data/transactions_repository.dart';
import '../../domain/pending_action.dart';
import '../../domain/transaction.dart';
import '../pages/transaction_form_page.dart';
import 'category_quick_assign_sheet.dart';

const List<String> _kMonthAbbreviations = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
];

String _dayLabel(DateTime date) => '${_kMonthAbbreviations[date.month - 1]} ${date.day}';

/// One feed row. T18: the category label in `_buildIncomeOrExpense`'s
/// subtitle is `CategoryQuickAssignChip` (a real tap target, not display-only
/// — see that widget for the bottom-sheet flow); transfer rows never show a
/// category chip since transfers don't take one (BR-5).
///
/// T12 (junk badge): the rule in `computeIsJunk` doesn't key off
/// [TransactionType], so a junk row can in principle be any of the three
/// types (e.g. an unparseable transfer slip also lands on
/// amount==0/no names) — the warning row and edit/delete actions below are
/// therefore shared across both builders rather than added to just one.
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

    return ListTile(
      leading: const CircleAvatar(backgroundColor: Color(0x1F9E9E9E), child: Icon(Icons.swap_horiz, color: Color(0xFF616161))),
      title: Text('${fromAccount?.name ?? 'Unknown'} → ${toAccount?.name ?? 'Unknown'}'),
      subtitle: _subtitle(context, Text(_dayLabel(transaction.transactionDate))),
      trailing: _trailing(context, ref, Text(transaction.amount.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w600))),
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
        : account?.name ?? (isIncome ? 'Income' : 'Expense');

    final amountColor = isIncome ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final amountText = '${isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(2)}';

    return ListTile(
      leading: account == null
          ? const CircleAvatar(backgroundColor: Color(0x1F9E9E9E), child: Icon(Icons.account_balance_wallet_outlined))
          : BankIconAvatar(bankIconCode: account.bankIcon),
      title: Text(title),
      subtitle: _subtitle(
        context,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_dayLabel(transaction.transactionDate)),
            const SizedBox(width: 6),
            const Text('·'),
            const SizedBox(width: 6),
            // T18/BR-9/FR-5.3: the primary way to assign/change a category —
            // tap opens the quick-assign bottom sheet, no navigation away
            // from the feed. T6's full edit form is the escape hatch, not
            // this.
            Flexible(child: CategoryQuickAssignChip(transaction: transaction, category: category)),
          ],
        ),
      ),
      trailing: _trailing(context, ref, Text(amountText, style: TextStyle(fontWeight: FontWeight.w600, color: amountColor))),
    );
  }

  /// Appends the spec §7.7 warning line below the normal subtitle when this
  /// row is junk; passes the normal subtitle through untouched otherwise.
  Widget _subtitle(BuildContext context, Widget normal) {
    if (!transaction.isJunk) return normal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        normal,
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 14, color: Colors.amber.shade800),
            const SizedBox(width: 4),
            Text("Couldn't read slip data", style: TextStyle(color: Colors.amber.shade800, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  /// Spec §7.7: junk rows swap the (uninformative — always 0) amount for
  /// explicit edit/delete actions; non-junk rows keep showing the amount.
  Widget _trailing(BuildContext context, WidgetRef ref, Widget normal) {
    if (!transaction.isJunk) return normal;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const Key('junkEditButton'),
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit',
          onPressed: () => _edit(context),
        ),
        IconButton(
          key: const Key('junkDeleteButton'),
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete',
          onPressed: () => _confirmDelete(context, ref),
        ),
      ],
    );
  }

  /// T6's full edit form is the escape hatch for junk rows (CLAUDE.md/spec
  /// §12.3) — fixing the amount alone is enough to clear `isJunk` once the
  /// PATCH response is re-parsed through `transactionFromJson`, since the
  /// rule is an AND across amount/senderName/receiverName.
  void _edit(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => TransactionFormPage(initial: transaction)));
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text("This transaction's slip data couldn't be read. Deleting it can't be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await ref.read(transactionsRepositoryProvider).delete(transaction.id);
    if (!context.mounted) return;
    await result.fold(
      // T13: a transient failure gets snapshotted into `pending_manual_actions`
      // (`PendingActionsRepository.recordIfTransient` is the single shared
      // decision point with `TransactionFormPage`'s create/update failures —
      // only `RetryPolicy.transient` failures get queued); a permanent one
      // stays snackbar-only, same as before this ticket.
      (failure) async {
        final queued = await ref
            .read(pendingActionsRepositoryProvider)
            .recordIfTransient(
              failure: failure,
              actionType: PendingActionType.deleteTransaction,
              payload: deleteTransactionPayload(date: transaction.transactionDate),
              targetTransactionId: transaction.id,
            );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(queued ? 'No connection — saved to the retry queue' : (failure.message ?? 'Could not delete transaction'))),
        );
      },
      // T14: deleting a transaction changes its month's feed and dashboard
      // totals, so that month must be invalidated by hand, same as
      // TransactionFormPage's own mutation does.
      (_) async => ref
          .read(cacheInvalidatorProvider)
          .invalidateMonth(transaction.transactionDate.year, transaction.transactionDate.month),
    );
  }
}

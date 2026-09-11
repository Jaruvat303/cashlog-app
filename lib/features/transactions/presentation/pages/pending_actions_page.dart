import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../data/pending_actions_repository.dart';
import '../../data/transactions_repository.dart';
import '../../domain/pending_action.dart';
import '../../domain/transaction.dart';
import '../providers/pending_actions_providers.dart';

String _dateLabel(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _actionLabel(PendingActionType type) => switch (type) {
  PendingActionType.createTransaction => 'Create transaction',
  PendingActionType.createTransfer => 'Create transfer',
  PendingActionType.updateTransaction => 'Edit transaction',
  PendingActionType.deleteTransaction => 'Delete transaction',
};

String _summary(PendingAction action) => switch (action.actionType) {
  PendingActionType.createTransaction => () {
    final args = readCreateTransactionPayload(action.payload);
    return '${args.type.label} · ${args.amount.toStringAsFixed(2)} · ${_dateLabel(args.date)}';
  }(),
  PendingActionType.createTransfer => () {
    final args = readCreateTransferPayload(action.payload);
    return 'Transfer · ${args.amount.toStringAsFixed(2)} · ${_dateLabel(args.date)}';
  }(),
  PendingActionType.updateTransaction => () {
    final args = readUpdateTransactionPayload(action.payload);
    return '${args.type.label} · ${args.amount.toStringAsFixed(2)} · ${_dateLabel(args.date)}';
  }(),
  PendingActionType.deleteTransaction => () {
    final args = readDeleteTransactionPayload(action.payload);
    return 'Transaction from ${_dateLabel(args.date)}';
  }(),
};

/// T13's "stuck — tap to retry" list. Reached only from `TransactionsPage`'s
/// AppBar icon+badge, never a bottom-nav tab of its own. Every action here
/// (retry, dismiss) is bound to the row's own stable `action.id` — never to
/// its position in the list — same discipline T12 already applies to
/// junk-row edit/delete.
class PendingActionsPage extends ConsumerStatefulWidget {
  const PendingActionsPage({super.key});

  @override
  ConsumerState<PendingActionsPage> createState() => _PendingActionsPageState();
}

class _PendingActionsPageState extends ConsumerState<PendingActionsPage> {
  final Set<int> _retryingIds = {};

  Future<void> _retry(PendingAction action) async {
    setState(() => _retryingIds.add(action.id));
    final result = await retryPendingAction(
      ref.read(transactionsRepositoryProvider),
      ref.read(pendingActionsRepositoryProvider),
      action,
    );
    if (!mounted) return;
    setState(() => _retryingIds.remove(action.id));
    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message ?? 'Still failing — stays in the queue'))),
      (_) {
        _invalidateAffectedMonths(action);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Retried successfully')));
      },
    );
  }

  /// No dedicated cache table backs the dashboard summary (spec §8/§11) — the
  /// retried mutation's month(s) must be invalidated by hand, same as
  /// `TransactionFormPage`/`TransactionListTile` already do for the
  /// non-retry path. An edit that crossed a month boundary invalidates both
  /// the original and new month, using `originalDate` snapshotted in the
  /// payload at the time of the original failed submit.
  void _invalidateAffectedMonths(PendingAction action) {
    switch (action.actionType) {
      case PendingActionType.createTransaction:
        final date = readCreateTransactionPayload(action.payload).date;
        ref.invalidate(dashboardSummaryProvider(date.year, date.month));
      case PendingActionType.createTransfer:
        final date = readCreateTransferPayload(action.payload).date;
        ref.invalidate(dashboardSummaryProvider(date.year, date.month));
      case PendingActionType.updateTransaction:
        final args = readUpdateTransactionPayload(action.payload);
        ref.invalidate(dashboardSummaryProvider(args.date.year, args.date.month));
        if (args.originalDate.year != args.date.year || args.originalDate.month != args.date.month) {
          ref.invalidate(dashboardSummaryProvider(args.originalDate.year, args.originalDate.month));
        }
      case PendingActionType.deleteTransaction:
        final date = readDeleteTransactionPayload(action.payload).date;
        ref.invalidate(dashboardSummaryProvider(date.year, date.month));
    }
  }

  Future<void> _dismiss(PendingAction action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard this item?'),
        content: const Text('It will be removed from the retry queue for good — this cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Discard')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(pendingActionsRepositoryProvider).remove(action.id);
  }

  @override
  Widget build(BuildContext context) {
    final actionsAsync = ref.watch(pendingActionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stuck items')),
      body: actionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load: $error')),
        data: (actions) {
          if (actions.isEmpty) {
            return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No stuck items')));
          }
          return ListView.builder(
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              final isRetrying = _retryingIds.contains(action.id);
              return ListTile(
                key: ValueKey(action.id),
                title: Text(_actionLabel(action.actionType)),
                isThreeLine: true,
                subtitle: Text(
                  '${_summary(action)}\n'
                  'Retries: ${action.retryCount}'
                  '${action.lastErrorCode != null ? ' · Last error: ${action.lastErrorCode}' : ''}',
                ),
                onTap: isRetrying ? null : () => _retry(action),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isRetrying)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    else
                      IconButton(
                        key: Key('retryButton_${action.id}'),
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Retry',
                        onPressed: () => _retry(action),
                      ),
                    IconButton(
                      key: Key('dismissButton_${action.id}'),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Discard',
                      onPressed: () => _dismiss(action),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

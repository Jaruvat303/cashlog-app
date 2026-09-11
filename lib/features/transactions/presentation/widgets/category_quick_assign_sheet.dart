import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/cache_invalidator.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/categories_providers.dart';
import '../../data/transactions_repository.dart';
import '../../domain/transaction.dart';

/// T18/BR-9/FR-5.3's primary category-assignment path: tap this chip on a
/// feed row → bottom sheet → `PATCH /transactions/:id` immediately, no
/// navigation away from the feed. T6's full edit form stays the escape
/// hatch for abnormal data (junk, amount/account/note fixes) — untouched by
/// this ticket (spec §12.3).
class CategoryQuickAssignChip extends ConsumerWidget {
  const CategoryQuickAssignChip({super.key, required this.transaction, required this.category});

  final Transaction transaction;
  final Category? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outlineColor = Theme.of(context).colorScheme.outline;
    final color = category == null ? outlineColor : colorFromHex(category!.colorHex);
    final icon = category == null ? Icons.add_circle_outline : resolveCategoryIcon(category!.iconKey);
    final label = category?.name ?? 'Add category';

    return InkWell(
      key: const Key('categoryQuickAssignChip'),
      onTap: () => _openSheet(context, ref),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: color))),
        ],
      ),
    );
  }

  Future<void> _openSheet(BuildContext context, WidgetRef ref) async {
    final selection = await showModalBottomSheet<_QuickAssignSelection>(
      context: context,
      builder: (_) => _CategoryPickerSheet(transactionType: transaction.type, currentCategoryId: transaction.categoryId),
    );
    // `selection` stays null both when the sheet is dismissed without a tap
    // and (deliberately) when the user re-picks the transaction's current
    // category — either way there's nothing to PATCH.
    if (selection == null || !context.mounted) return;

    final repo = ref.read(transactionsRepositoryProvider);
    final result = await repo.update(
      transaction.id,
      type: transaction.type,
      amount: transaction.amount,
      date: transaction.transactionDate,
      note: transaction.note,
      accountId: transaction.accountId,
      fromAccountId: transaction.fromAccountId,
      toAccountId: transaction.toAccountId,
      categoryId: selection.categoryId,
    );
    if (!context.mounted) return;

    result.fold(
      // No optimistic update to undo here: `cached_transactions` (the
      // feed's only source of truth for the displayed category) is never
      // touched unless `update` returns `Right`, so a failure leaves the
      // row exactly as it was — just surface the error.
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message ?? 'Could not update category'))),
      // T14: a category change affects this month's dashboard
      // expense-by-category breakdown, which — unlike the feed — is
      // in-memory Riverpod state, not drift-reactive, so it needs an
      // explicit invalidation the same way T6/T10's mutations already do.
      (_) => ref.read(cacheInvalidatorProvider).invalidateMonth(transaction.transactionDate.year, transaction.transactionDate.month),
    );
  }
}

class _QuickAssignSelection {
  const _QuickAssignSelection(this.categoryId);
  final int? categoryId;
}

/// Only offers categories matching this transaction's type (e.g. an expense
/// never offers an income category) — same rule `TransactionFormPage`'s
/// dropdown already applies.
class _CategoryPickerSheet extends ConsumerWidget {
  const _CategoryPickerSheet({required this.transactionType, required this.currentCategoryId});

  final TransactionType transactionType;
  final int? currentCategoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(allCategoriesProvider);
    return SafeArea(
      child: categoriesAsync.when(
        loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        error: (error, _) => Padding(padding: const EdgeInsets.all(24), child: Text('Failed to load categories: $error')),
        data: (categories) {
          final matching = categories.where((c) => c.type.name == transactionType.name).toList();
          return ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                key: const Key('categoryOptionUncategorized'),
                leading: const Icon(Icons.remove_circle_outline),
                title: const Text('Uncategorized'),
                trailing: currentCategoryId == null ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(currentCategoryId == null ? null : const _QuickAssignSelection(null)),
              ),
              for (final category in matching)
                ListTile(
                  key: Key('categoryOption_${category.id}'),
                  leading: Icon(resolveCategoryIcon(category.iconKey), color: colorFromHex(category.colorHex)),
                  title: Text(category.name),
                  trailing: currentCategoryId == category.id ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(context).pop(currentCategoryId == category.id ? null : _QuickAssignSelection(category.id)),
                ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../../../core/cache/cache_invalidator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/format/money.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../../../../shared/widgets/category_picker_sheet.dart';
import '../../../categories/domain/category.dart';
import '../../data/transactions_repository.dart';
import '../../domain/transaction.dart';

/// T18/BR-9/FR-5.3's primary category-assignment path: tap this icon on a
/// feed row → the shared grid sheet (mockup 1c) → `PATCH /transactions/:id`
/// immediately, no navigation away from the feed. T6's full edit sheet
/// stays the escape hatch for abnormal data (spec §12.3) — untouched by
/// this ticket.
class CategoryQuickAssignChip extends ConsumerWidget {
  const CategoryQuickAssignChip({super.key, required this.transaction, required this.category});

  final Transaction transaction;
  final Category? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUncategorized = category == null;
    final color = isUncategorized ? AppColors.warningIcon : colorFromHex(category!.colorHex);
    final background = isUncategorized ? AppColors.warningSurface : color.withValues(alpha: 0.12);
    final icon = isUncategorized ? RemixIcon.addLine : resolveCategoryIcon(category!.iconKey);

    return InkWell(
      key: const Key('categoryQuickAssignChip'),
      onTap: () => _openSheet(context, ref),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: isUncategorized ? Border.all(color: AppColors.warningBorder, width: 1.5) : null,
        ),
        child: Icon(icon, size: isUncategorized ? 19 : 18, color: color),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context, WidgetRef ref) async {
    final categoryType = transaction.type == TransactionType.income ? CategoryType.income : CategoryType.expense;
    final merchant = transaction.type == TransactionType.income ? transaction.senderName : transaction.receiverName;
    final label = transaction.type == TransactionType.income ? 'รายรับ' : 'รายจ่าย';
    final subtitle = '$label${merchant.isNotEmpty ? ' · $merchant' : ''} · ${formatAmount(transaction.amount)} — แตะเพื่อบันทึกทันที';

    final selection = await showCategoryGridPicker(
      context,
      categoryType: categoryType,
      currentCategoryId: transaction.categoryId,
      subtitle: subtitle,
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
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message ?? 'อัปเดตหมวดหมู่ไม่สำเร็จ'))),
      // T14: a category change affects this month's dashboard
      // expense-by-category breakdown, which — unlike the feed — is
      // in-memory Riverpod state, not drift-reactive, so it needs an
      // explicit invalidation the same way T6/T10's mutations already do.
      (_) => ref.read(cacheInvalidatorProvider).invalidateMonth(transaction.transactionDate.year, transaction.transactionDate.month),
    );
  }
}

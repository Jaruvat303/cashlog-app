import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../../../../shared/widgets/pill_form_row.dart';
import '../../../categories/domain/category.dart';
import '../../domain/transaction.dart';

/// Ticket 04 established the visual pattern (amount card, icon+label+chevron
/// pill rows, sticky bottom button) for the Add/Edit Transaction screens,
/// but each screen kept its own separate copy of it instead of one shared
/// widget — so when ticket 07 changed `AddTransactionPage`'s amount input to
/// a native-keyboard `TextField`, it touched only that copy, and
/// `TransactionFormPage` (Edit) quietly fell back out of parity again with
/// nobody noticing until ticket 13's QA pass. This widget is now the *one*
/// implementation both pages render for the amount card and the
/// category/date/account/note fields, so a future layout change is
/// structurally shared, not something that can silently drift a third time.
///
/// Deliberately does **not** cover: the type tabs (`SegmentedTabs`, already
/// identical/shared between both pages before this ticket), the submit
/// button (`PrimaryGradientButton`, same reasoning — only its `label` text
/// differs, which is exactly what a shared *component* means: same widget,
/// caller-supplied content), the Topbar (intentionally different between
/// the two screens — Add's is a close button with no trailing action,
/// Edit's is a back button with a delete action), or Edit's "ข้อมูลจากสลิป"
/// card (ticket 04, explicitly out of ticket 13's scope).
///
/// Each field's *interaction* stays page-owned via callbacks — only the
/// *layout* is shared here. Add's category/date/account pickers open an
/// anchored quick-pick dropdown; Edit's date picker opens the native system
/// date picker instead. That's a real, pre-existing behavior difference
/// between the two screens, not a styling one, and ticket 13's scope is
/// layout parity, not a behavior change — so each page still supplies its
/// own `onDateTap`/`onAccountTap`/etc. implementation.
class TransactionFormFields extends StatelessWidget {
  const TransactionFormFields({
    super.key,
    required this.type,
    required this.amountController,
    this.amountValidator,
    this.autofocusAmount = false,
    required this.category,
    required this.accountName,
    required this.fromAccountName,
    required this.toAccountName,
    required this.dateLabel,
    required this.onCategoryTap,
    required this.onDateTap,
    required this.onAccountTap,
    required this.onFromAccountTap,
    required this.onToAccountTap,
    this.transferError,
    required this.noteController,
  });

  final TransactionType type;
  final TextEditingController amountController;
  final String? Function(String?)? amountValidator;

  /// Add autofocuses the amount field on open (it's the first thing typed);
  /// Edit doesn't (the user came here to fix something specific, often not
  /// the amount) — a real, pre-existing behavior difference, not something
  /// this ticket's layout-parity scope changes.
  final bool autofocusAmount;

  final Category? category;
  final String? accountName;
  final String? fromAccountName;
  final String? toAccountName;
  final String dateLabel;
  final VoidCallback onCategoryTap;
  final void Function(BuildContext anchorContext) onDateTap;
  final void Function(BuildContext anchorContext) onAccountTap;
  final void Function(BuildContext anchorContext) onFromAccountTap;
  final void Function(BuildContext anchorContext) onToAccountTap;
  final String? transferError;
  final TextEditingController noteController;

  bool get _isTransfer => type == TransactionType.transfer;

  Color get _typeColor => switch (type) {
    TransactionType.income => AppColors.income,
    TransactionType.expense => AppColors.expense,
    TransactionType.transfer => AppColors.accentA,
  };

  IconData get _typeIcon => switch (type) {
    TransactionType.income => RemixIcon.arrowUpLine,
    TransactionType.expense => RemixIcon.arrowDownLine,
    TransactionType.transfer => RemixIcon.arrowLeftRightLine,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const Key('amountCard'),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.cardLarge), boxShadow: const [AppShadows.card]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('จำนวนเงิน', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.pillChipBg, borderRadius: BorderRadius.circular(6)),
                    child: const Text('THB', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: _typeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                    child: Icon(_typeIcon, color: _typeColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: const Key('amountField'),
                      controller: amountController,
                      autofocus: autofocusAmount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [AmountInputFormatter()],
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: _typeColor),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        isCollapsed: true,
                        hintText: '0',
                        hintStyle: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: _typeColor.withValues(alpha: 0.3)),
                      ),
                      validator: amountValidator,
                    ),
                  ),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: AppColors.divider)),
              if (_isTransfer)
                Row(
                  children: [
                    const Icon(RemixIcon.arrowRightLine, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${fromAccountName ?? 'เลือกบัญชีต้นทาง'} → ${toAccountName ?? 'เลือกบัญชีปลายทาง'}',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: category == null ? AppColors.warningIcon : colorFromHex(category!.colorHex), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${category?.name ?? 'ยังไม่ระบุหมวดหมู่'} • ${accountName ?? 'ยังไม่เลือกบัญชี'}',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (!_isTransfer) ...[
          Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (anchorContext) => PillFormRow(
                    key: const Key('categoryPill'),
                    icon: RemixIcon.folderLine,
                    label: 'หมวดหมู่',
                    value: category?.name ?? 'ยังไม่ระบุ',
                    iconColor: category == null ? AppColors.warningIcon : colorFromHex(category!.colorHex),
                    onTap: onCategoryTap,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Builder(
                  builder: (anchorContext) => PillFormRow(
                    key: const Key('datePill'),
                    icon: RemixIcon.calendarLine,
                    label: 'วันที่',
                    value: dateLabel,
                    onTap: () => onDateTap(anchorContext),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Builder(
            builder: (anchorContext) => PillFormRow(
              key: const Key('accountPill'),
              icon: RemixIcon.wallet3Line,
              label: 'บัญชี',
              value: accountName ?? 'เลือกบัญชี',
              onTap: () => onAccountTap(anchorContext),
            ),
          ),
        ] else ...[
          Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  Builder(
                    builder: (anchorContext) => PillFormRow(
                      key: const Key('fromAccountPill'),
                      icon: RemixIcon.arrowUpLine,
                      label: 'จากบัญชี',
                      value: fromAccountName ?? 'เลือกบัญชีต้นทาง',
                      onTap: () => onFromAccountTap(anchorContext),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Builder(
                    builder: (anchorContext) => PillFormRow(
                      key: const Key('toAccountPill'),
                      icon: RemixIcon.arrowDownLine,
                      label: 'ไปบัญชี',
                      value: toAccountName ?? 'เลือกบัญชีปลายทาง',
                      onTap: () => onToAccountTap(anchorContext),
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 14,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.accentGradient,
                      border: Border.fromBorderSide(BorderSide(color: AppColors.background, width: 3)),
                    ),
                    child: const Icon(RemixIcon.arrowUpDownLine, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          if (transferError != null) ...[
            const SizedBox(height: 6),
            Text(transferError!, style: const TextStyle(fontSize: 12, color: AppColors.expense)),
          ],
          const SizedBox(height: 10),
          Builder(
            builder: (anchorContext) => PillFormRow(
              key: const Key('transferDatePill'),
              icon: RemixIcon.calendarLine,
              label: 'วันที่',
              value: dateLabel,
              onTap: () => onDateTap(anchorContext),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.control), boxShadow: const [AppShadows.card]),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              const Icon(RemixIcon.editLine, size: 16, color: AppColors.accentA),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const Key('noteField'),
                  controller: noteController,
                  minLines: 1,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'เพิ่มบันทึกย่อ',
                    hintStyle: TextStyle(color: AppColors.accentA, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The digit-grouping core of [AmountInputFormatter], factored out so
/// [formatAmountForInput] can pre-format Edit's initial value (e.g.
/// "1234.5" -> "1,234.50") the exact same way the formatter reformats every
/// keystroke — otherwise Edit's amount would open un-grouped and only start
/// matching Add's live-typed style after the user's first edit.
String _groupAmountDigits(String raw) {
  var value = raw.replaceAll(RegExp(r'[^0-9.]'), '');

  final firstDot = value.indexOf('.');
  if (firstDot != -1) {
    value = value.substring(0, firstDot + 1) + value.substring(firstDot + 1).replaceAll('.', '');
  }

  final dotIndex = value.indexOf('.');
  if (dotIndex != -1 && value.length - dotIndex - 1 > 2) {
    value = value.substring(0, dotIndex + 3);
  }

  final parts = value.split('.');
  final wholeDigits = parts[0];
  final grouped = StringBuffer();
  for (var i = 0; i < wholeDigits.length; i++) {
    if (i > 0 && (wholeDigits.length - i) % 3 == 0) grouped.write(',');
    grouped.write(wholeDigits[i]);
  }
  return parts.length > 1 ? '$grouped.${parts[1]}' : grouped.toString();
}

/// Ticket 07: replaces the removed custom on-screen numpad — the amount
/// field takes the native numeric keyboard, and this formatter keeps the
/// same comma-grouped-thousands / max-2-decimal-places display the numpad's
/// live preview used, live as the user types. Always collapses the cursor
/// to the end, which is fine for a field only ever appended to (no
/// mid-string editing use case for a monetary amount).
///
/// Ticket 13: now shared by both Add and Edit's amount fields via
/// [TransactionFormFields] — previously Add-only, since Edit had its own
/// unformatted amount field before this ticket unified them.
class AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final formatted = _groupAmountDigits(newValue.text);
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

/// Pre-formats an existing amount (Edit's initial value) the same way
/// [AmountInputFormatter] formats live keystrokes — see its doc comment.
String formatAmountForInput(double amount) => _groupAmountDigits(amount.toStringAsFixed(2));

/// Parses [TransactionFormFields]'s amount field text back into a plain
/// double, stripping the thousands-grouping commas [AmountInputFormatter]
/// added.
double parseAmountInput(String formatted) => double.tryParse(formatted.replaceAll(',', '')) ?? 0;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../../../core/cache/cache_invalidator.dart';
import '../../../../core/network/failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/anchored_dropdown_panel.dart';
import '../../../../shared/widgets/category_picker_sheet.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../../../../shared/widgets/segmented_tabs.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/providers/accounts_providers.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/categories_providers.dart';
import '../../data/pending_actions_repository.dart';
import '../../data/transactions_repository.dart';
import '../../domain/pending_action.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_validation.dart';
import '../widgets/transaction_form_fields.dart';

/// The mockup's `AddTransaction`/`AddTransactionIncome`/`AddTransactionTransfer`
/// screens, unified into one page (same `sc-if`-per-type structure the
/// mockup itself uses) — the new sole creation entry point, reached from
/// `ManualSlipAttachButton`'s speed-dial "บันทึกเอง" option. Editing an
/// existing transaction stays on `TransactionFormPage` (the escape hatch),
/// untouched by this page.
class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  DateTime _date = DateTime.now();
  int? _accountId;
  int? _fromAccountId;
  int? _toAccountId;
  int? _categoryId;
  bool _isSubmitting = false;
  String? _transferError;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = parseAmountInput(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรอกจำนวนเงินให้ถูกต้อง')));
      return;
    }
    final isTransfer = _type == TransactionType.transfer;
    if (isTransfer) {
      final error = validateTransferAccounts(_fromAccountId, _toAccountId);
      if (error != null) {
        setState(() => _transferError = error);
        return;
      }
      if (_fromAccountId == null || _toAccountId == null) {
        setState(() => _transferError = 'จำเป็นต้องเลือกบัญชี');
        return;
      }
    } else if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('จำเป็นต้องเลือกบัญชี')));
      return;
    }

    setState(() {
      _isSubmitting = true;
      _transferError = null;
    });

    final note = _noteController.text.trim();
    final result = await ref
        .read(transactionsRepositoryProvider)
        .create(
          type: _type,
          amount: amount,
          date: _date,
          note: note,
          accountId: isTransfer ? null : _accountId,
          fromAccountId: isTransfer ? _fromAccountId : null,
          toAccountId: isTransfer ? _toAccountId : null,
          categoryId: isTransfer ? null : _categoryId,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    await result.fold((failure) => _handleFailure(failure, amount: amount, note: note, isTransfer: isTransfer), (_) async {
      ref.read(cacheInvalidatorProvider).invalidateMonth(_date.year, _date.month);
      Navigator.of(context).pop(true);
    });
  }

  Future<void> _handleFailure(Failure failure, {required double amount, required String note, required bool isTransfer}) async {
    final payload = isTransfer
        ? createTransferPayload(amount: amount, date: _date, note: note, fromAccountId: _fromAccountId!, toAccountId: _toAccountId!, categoryId: _categoryId)
        : createTransactionPayload(type: _type, amount: amount, date: _date, note: note, accountId: _accountId!, categoryId: _categoryId);

    final queued = await ref
        .read(pendingActionsRepositoryProvider)
        .recordIfTransient(
          failure: failure,
          actionType: isTransfer ? PendingActionType.createTransfer : PendingActionType.createTransaction,
          payload: payload,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(queued ? 'ไม่มีการเชื่อมต่อ — บันทึกไว้ในคิวลองใหม่แล้ว' : (failure.message ?? 'ทำรายการไม่สำเร็จ ลองใหม่อีกครั้ง'))));
  }

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _type = type;
      _transferError = null;
      _categoryId = null;
      if (type == TransactionType.transfer) {
        _accountId = null;
      } else {
        _fromAccountId = null;
        _toAccountId = null;
      }
    });
  }

  Future<void> _pickCategory() async {
    final categoryType = _type == TransactionType.income ? CategoryType.income : CategoryType.expense;
    final selection = await showCategoryGridPicker(context, categoryType: categoryType, currentCategoryId: _categoryId, subtitle: 'เลือกหมวดหมู่สำหรับรายการนี้');
    if (selection == null) return;
    setState(() => _categoryId = selection.categoryId);
  }

  Future<void> _pickDate(BuildContext anchorContext) async {
    final result = await showAnchoredDropdown<DateTime>(
      anchorContext: anchorContext,
      panelBuilder: (context, close) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownPanelOption(label: 'วันนี้', onTap: () => close(DateTime.now())),
          DropdownPanelOption(label: 'เมื่อวาน', onTap: () => close(DateTime.now().subtract(const Duration(days: 1)))),
          DropdownPanelOption(
            label: 'เลือกวันที่',
            onTap: () async {
              close();
              final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
              if (picked != null && mounted) setState(() => _date = picked);
            },
          ),
        ],
      ),
    );
    if (result != null) setState(() => _date = result);
  }

  Future<void> _pickAccount(BuildContext anchorContext, List<Account> accounts, void Function(int id) onPicked) async {
    final result = await showAnchoredDropdown<int>(
      anchorContext: anchorContext,
      panelBuilder: (context, close) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [for (final a in accounts) DropdownPanelOption(key: Key('accountOption_${a.id}'), label: a.name, onTap: () => close(a.id))],
      ),
    );
    if (result != null) onPicked(result);
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(activeAccountsProvider).value ?? const [];
    final categories = ref.watch(allCategoriesProvider).value ?? const [];
    final category = _findById(categories, _categoryId, (c) => c.id);
    final accountName = _findById(accounts, _accountId, (a) => a.id)?.name;
    final fromAccountName = _findById(accounts, _fromAccountId, (a) => a.id)?.name;
    final toAccountName = _findById(accounts, _toAccountId, (a) => a.id)?.name;
    final isTransfer = _type == TransactionType.transfer;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircularIconButton(icon: RemixIcon.closeLine, onTap: () => Navigator.of(context).pop()),
                  const Text('เพิ่มรายการ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(width: 38, height: 38),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedTabs<TransactionType>(
                      values: TransactionType.values,
                      labels: TransactionType.values.map((t) => t.label).toList(),
                      selected: _type,
                      onChanged: _onTypeChanged,
                    ),
                    const SizedBox(height: 14),
                    TransactionFormFields(
                      type: _type,
                      amountController: _amountController,
                      autofocusAmount: true,
                      category: category,
                      accountName: accountName,
                      fromAccountName: fromAccountName,
                      toAccountName: toAccountName,
                      dateLabel: _dateLabel(_date),
                      onCategoryTap: _pickCategory,
                      onDateTap: (anchorContext) => _pickDate(anchorContext),
                      onAccountTap: (anchorContext) => _pickAccount(anchorContext, accounts, (id) => setState(() => _accountId = id)),
                      onFromAccountTap: (anchorContext) => _pickAccount(anchorContext, accounts, (id) => setState(() {
                        _fromAccountId = id;
                        _transferError = null;
                      })),
                      onToAccountTap: (anchorContext) => _pickAccount(anchorContext, accounts, (id) => setState(() {
                        _toAccountId = id;
                        _transferError = null;
                      })),
                      transferError: _transferError,
                      noteController: _noteController,
                    ),
                    const SizedBox(height: 16),
                    PrimaryGradientButton(
                      key: const Key('submitButton'),
                      label: isTransfer ? 'โอนเงิน' : 'บันทึกรายการ',
                      onTap: _isSubmitting ? null : _submit,
                      enabled: !_isSubmitting,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final today = DateTime.now();
    if (date.year == today.year && date.month == today.month && date.day == today.day) return 'วันนี้';
    final yesterday = today.subtract(const Duration(days: 1));
    if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) return 'เมื่อวาน';
    return '${date.day}/${date.month}/${date.year}';
  }

  T? _findById<T>(List<T> items, int? id, int Function(T) idOf) {
    if (id == null) return null;
    for (final item in items) {
      if (idOf(item) == id) return item;
    }
    return null;
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../../../core/cache/cache_invalidator.dart';
import '../../../../core/network/failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../accounts/presentation/providers/accounts_providers.dart';
import '../../../categories/presentation/providers/categories_providers.dart';
import '../../data/pending_actions_repository.dart';
import '../../data/transactions_repository.dart';
import '../../domain/pending_action.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_validation.dart';

/// Create when [initial] is null, edit otherwise — same control flow as
/// `AccountFormPage`/`CategoryFormPage`. Account/category pickers reuse
/// T4's `activeAccountsProvider` and T5's `allCategoriesProvider` verbatim
/// (no new queries against `cached_accounts`/`cached_categories`).
class TransactionFormPage extends ConsumerStatefulWidget {
  const TransactionFormPage({super.key, this.initial});

  final Transaction? initial;

  bool get isEditing => initial != null;

  @override
  ConsumerState<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _amountController = TextEditingController(text: widget.initial?.amount.toStringAsFixed(2) ?? '');
  late final _noteController = TextEditingController(text: widget.initial?.note ?? '');
  late TransactionType _type = widget.initial?.type ?? TransactionType.expense;
  late DateTime _date = widget.initial?.transactionDate ?? DateTime.now();
  int? _accountId;
  int? _fromAccountId;
  int? _toAccountId;
  int? _categoryId;
  bool _isSubmitting = false;
  String? _transferError;

  @override
  void initState() {
    super.initState();
    _accountId = widget.initial?.accountId;
    _fromAccountId = widget.initial?.fromAccountId;
    _toAccountId = widget.initial?.toAccountId;
    _categoryId = widget.initial?.categoryId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Client-side mirror of the backend's ErrTransferSameAccount rule —
    // checked before any request is sent (spec §4).
    if (_type == TransactionType.transfer) {
      final error = validateTransferAccounts(_fromAccountId, _toAccountId);
      if (error != null) {
        setState(() => _transferError = error);
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _transferError = null;
    });
    final repo = ref.read(transactionsRepositoryProvider);
    final amount = double.parse(_amountController.text);
    final note = _noteController.text.trim();
    final isTransfer = _type == TransactionType.transfer;

    final result = widget.isEditing
        ? await repo.update(
            widget.initial!.id,
            type: _type,
            amount: amount,
            date: _date,
            note: note,
            accountId: isTransfer ? null : _accountId,
            fromAccountId: isTransfer ? _fromAccountId : null,
            toAccountId: isTransfer ? _toAccountId : null,
            categoryId: isTransfer ? null : _categoryId,
          )
        : await repo.create(
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

    await result.fold(
      (failure) => _handleFailure(failure, amount: amount, note: note, isTransfer: isTransfer),
      (_) async {
        _invalidateAffectedMonths();
        Navigator.of(context).pop(true);
      },
    );
  }

  /// T13: a transient failure (CLAUDE.md/spec §9 — network cut, timeout,
  /// etc.) gets snapshotted into `pending_manual_actions` so the user's typed
  /// data isn't lost; a permanent one (e.g. invalid input) stays
  /// snackbar-only, same as before this ticket, since retrying an identical
  /// payload against it can't succeed. `PendingActionsRepository.recordIfTransient`
  /// is the single place that decision is made, shared with
  /// `TransactionListTile`'s delete path — never re-derived from live form
  /// state on a later retry, only the args snapshotted right here.
  Future<void> _handleFailure(Failure failure, {required double amount, required String note, required bool isTransfer}) async {
    final payload = widget.isEditing
        ? updateTransactionPayload(
            type: _type,
            amount: amount,
            date: _date,
            note: note,
            accountId: isTransfer ? null : _accountId,
            fromAccountId: isTransfer ? _fromAccountId : null,
            toAccountId: isTransfer ? _toAccountId : null,
            categoryId: isTransfer ? null : _categoryId,
            originalDate: widget.initial!.transactionDate,
          )
        : isTransfer
        ? createTransferPayload(amount: amount, date: _date, note: note, fromAccountId: _fromAccountId!, toAccountId: _toAccountId!, categoryId: _categoryId)
        : createTransactionPayload(type: _type, amount: amount, date: _date, note: note, accountId: _accountId!, categoryId: _categoryId);

    final queued = await ref
        .read(pendingActionsRepositoryProvider)
        .recordIfTransient(
          failure: failure,
          actionType: widget.isEditing
              ? PendingActionType.updateTransaction
              : (isTransfer ? PendingActionType.createTransfer : PendingActionType.createTransaction),
          payload: payload,
          targetTransactionId: widget.isEditing ? widget.initial!.id : null,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(queued ? 'ไม่มีการเชื่อมต่อ — บันทึกไว้ในคิวลองใหม่แล้ว' : (failure.message ?? 'ทำรายการไม่สำเร็จ ลองใหม่อีกครั้ง'))),
    );
  }

  /// T14/CLAUDE.md: invalidate only the affected month's cache. Create (no
  /// `widget.initial`) always invalidates the single new month; an edit
  /// compares the pre-submit `widget.initial!.transactionDate` against the
  /// chosen `_date` and invalidates both months when they differ across a
  /// month boundary, one otherwise — see `monthsAffectedByEdit`.
  void _invalidateAffectedMonths() {
    ref.read(cacheInvalidatorProvider).invalidateMonths(monthsAffectedByEdit(widget.initial?.transactionDate, _date));
  }

  /// Mockup 1d's "ลบรายการ" button — ticket 04's sole delete path for any
  /// transaction, junk or not (the old junk-row delete icon on
  /// `TransactionListTile` is gone): real delete → invalidate the
  /// transaction's month → transient failures queue into
  /// `pending_manual_actions`.
  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบรายการนี้ใช่ไหม'),
        content: const Text('การลบไม่สามารถกู้คืนได้'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('ลบ')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final transaction = widget.initial!;
    final result = await ref.read(transactionsRepositoryProvider).delete(transaction.id);
    if (!context.mounted) return;

    await result.fold(
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
          SnackBar(content: Text(queued ? 'ไม่มีการเชื่อมต่อ — บันทึกไว้ในคิวลองใหม่แล้ว' : (failure.message ?? 'ลบรายการไม่สำเร็จ'))),
        );
      },
      (_) async {
        ref.read(cacheInvalidatorProvider).invalidateMonth(transaction.transactionDate.year, transaction.transactionDate.month);
        if (context.mounted) Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(activeAccountsProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);

    // Mockup 1d: the category field gets a highlighted (amber) treatment
    // when this row still has no category — purely a decoration around the
    // existing dropdown, not a structural change.
    final categoryUnset = widget.isEditing && _type != TransactionType.transfer && _categoryId == null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'แก้ไขรายการ' : 'สร้างรายการเอง')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<TransactionType>(
              key: const Key('transactionTypeDropdown'),
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'ประเภท'),
              items: TransactionType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.label))).toList(),
              onChanged: (type) => setState(() {
                _type = type!;
                _transferError = null;
                _categoryId = null;
                if (_type == TransactionType.transfer) {
                  _accountId = null;
                } else {
                  _fromAccountId = null;
                  _toAccountId = null;
                }
              }),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('amountField'),
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'จำนวนเงิน'),
              validator: (value) {
                final parsed = double.tryParse(value ?? '');
                if (parsed == null) return 'กรอกตัวเลขให้ถูกต้อง';
                if (parsed <= 0) return 'ต้องมากกว่า 0';
                return null;
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.inputBorder)),
              title: const Text('วันที่'),
              subtitle: Text(
                '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(RemixIcon.calendarLine),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            accountsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('โหลดบัญชีไม่สำเร็จ: $error'),
              data: (accounts) {
                if (_type == TransactionType.transfer) {
                  return Column(
                    children: [
                      DropdownButtonFormField<int>(
                        key: const Key('fromAccountDropdown'),
                        initialValue: _fromAccountId,
                        decoration: const InputDecoration(labelText: 'บัญชีต้นทาง'),
                        items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                        onChanged: (id) => setState(() {
                          _fromAccountId = id;
                          _transferError = null;
                        }),
                        validator: (value) => value == null ? 'จำเป็นต้องเลือก' : null,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        key: const Key('toAccountDropdown'),
                        initialValue: _toAccountId,
                        decoration: InputDecoration(labelText: 'บัญชีปลายทาง', errorText: _transferError),
                        items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                        onChanged: (id) => setState(() {
                          _toAccountId = id;
                          _transferError = null;
                        }),
                        validator: (value) => value == null ? 'จำเป็นต้องเลือก' : null,
                      ),
                    ],
                  );
                }
                return DropdownButtonFormField<int>(
                  key: const Key('accountDropdown'),
                  initialValue: _accountId,
                  decoration: const InputDecoration(labelText: 'บัญชี'),
                  items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                  onChanged: (id) => setState(() => _accountId = id),
                  validator: (value) => value == null ? 'จำเป็นต้องเลือก' : null,
                );
              },
            ),
            if (_type != TransactionType.transfer) ...[
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: categoryUnset ? Border.all(color: AppColors.warningBorder, width: 1.5) : null,
                ),
                child: categoriesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text('โหลดหมวดหมู่ไม่สำเร็จ: $error'),
                  data: (categories) {
                    // Only offer categories matching this transaction's type
                    // (e.g. an expense never offers an income category).
                    final matching = categories.where((c) => c.type.name == _type.name).toList();
                    return DropdownButtonFormField<int?>(
                      initialValue: _categoryId,
                      decoration: InputDecoration(labelText: categoryUnset ? 'แตะเพื่อเลือกหมวดหมู่' : 'หมวดหมู่ (ไม่บังคับ)'),
                      items: [
                        const DropdownMenuItem<int?>(child: Text('ยังไม่ระบุหมวดหมู่')),
                        ...matching.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (id) => setState(() => _categoryId = id),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextFormField(controller: _noteController, decoration: const InputDecoration(labelText: 'โน้ต'), minLines: 1, maxLines: 3),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('submitButton'),
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.isEditing ? 'บันทึก' : 'สร้างรายการ'),
            ),
            if (widget.isEditing) ...[
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  key: const Key('deleteTransactionButton'),
                  onPressed: _isSubmitting ? null : () => _confirmDelete(context),
                  style: TextButton.styleFrom(foregroundColor: AppColors.expense),
                  child: const Text('ลบรายการ'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

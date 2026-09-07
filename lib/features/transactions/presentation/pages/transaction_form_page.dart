import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../accounts/presentation/providers/accounts_providers.dart';
import '../../../categories/presentation/providers/categories_providers.dart';
import '../../data/transactions_repository.dart';
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

    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message ?? 'Request failed. Please try again.'))),
      (_) => Navigator.of(context).pop(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(activeAccountsProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit transaction' : 'New transaction')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<TransactionType>(
              key: const Key('transactionTypeDropdown'),
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
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
              decoration: const InputDecoration(labelText: 'Amount'),
              validator: (value) {
                final parsed = double.tryParse(value ?? '');
                if (parsed == null) return 'Enter a valid number';
                if (parsed <= 0) return 'Must be greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(
                '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            accountsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Failed to load accounts: $error'),
              data: (accounts) {
                if (_type == TransactionType.transfer) {
                  return Column(
                    children: [
                      DropdownButtonFormField<int>(
                        key: const Key('fromAccountDropdown'),
                        initialValue: _fromAccountId,
                        decoration: const InputDecoration(labelText: 'From account'),
                        items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                        onChanged: (id) => setState(() {
                          _fromAccountId = id;
                          _transferError = null;
                        }),
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        key: const Key('toAccountDropdown'),
                        initialValue: _toAccountId,
                        decoration: InputDecoration(labelText: 'To account', errorText: _transferError),
                        items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                        onChanged: (id) => setState(() {
                          _toAccountId = id;
                          _transferError = null;
                        }),
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                    ],
                  );
                }
                return DropdownButtonFormField<int>(
                  key: const Key('accountDropdown'),
                  initialValue: _accountId,
                  decoration: const InputDecoration(labelText: 'Account'),
                  items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                  onChanged: (id) => setState(() => _accountId = id),
                  validator: (value) => value == null ? 'Required' : null,
                );
              },
            ),
            if (_type != TransactionType.transfer) ...[
              const SizedBox(height: 8),
              categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Failed to load categories: $error'),
                data: (categories) {
                  // Only offer categories matching this transaction's type
                  // (e.g. an expense never offers an income category).
                  final matching = categories.where((c) => c.type.name == _type.name).toList();
                  return DropdownButtonFormField<int?>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(labelText: 'Category (optional)'),
                    items: [
                      const DropdownMenuItem<int?>(child: Text('Uncategorized')),
                      ...matching.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (id) => setState(() => _categoryId = id),
                  );
                },
              ),
            ],
            const SizedBox(height: 8),
            TextFormField(controller: _noteController, decoration: const InputDecoration(labelText: 'Note'), minLines: 1, maxLines: 3),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('submitButton'),
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.isEditing ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}

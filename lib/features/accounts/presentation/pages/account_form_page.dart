import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/accounts_repository.dart';
import '../../domain/account.dart';
import '../../domain/bank_icon.dart';

/// Create when [initial] is null, edit otherwise. `opening_balance` is only
/// ever shown/sent in create mode — `UpdateAccountInput` has no such field,
/// so it can't be edited after creation (confirmed against the live
/// swagger schema).
class AccountFormPage extends ConsumerStatefulWidget {
  const AccountFormPage({super.key, this.initial});

  final Account? initial;

  bool get isEditing => initial != null;

  @override
  ConsumerState<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends ConsumerState<AccountFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.initial?.name ?? '');
  late final _openingBalanceController = TextEditingController(text: widget.initial?.openingBalance.toStringAsFixed(2) ?? '0');
  late final _matchingKeywordsController = TextEditingController(text: (widget.initial?.matchingKeywords ?? const []).join(', '));
  late AccountType _accountType = widget.initial?.accountType ?? AccountType.bank;
  late String _bankIconCode = widget.initial?.bankIcon.isNotEmpty == true ? widget.initial!.bankIcon : kBankIcons.keys.first;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _openingBalanceController.dispose();
    _matchingKeywordsController.dispose();
    super.dispose();
  }

  List<String> get _matchingKeywords => _matchingKeywordsController.text
      .split(RegExp(r'[,\n]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final repo = ref.read(accountsRepositoryProvider);
    final result = widget.isEditing
        ? await repo.update(
            widget.initial!.id,
            name: _nameController.text.trim(),
            accountType: _accountType,
            matchingKeywords: _matchingKeywords,
            bankIcon: _bankIconCode,
          )
        : await repo.create(
            name: _nameController.text.trim(),
            accountType: _accountType,
            openingBalance: double.parse(_openingBalanceController.text),
            matchingKeywords: _matchingKeywords,
            bankIcon: _bankIconCode,
          );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message ?? 'ทำรายการไม่สำเร็จ ลองใหม่อีกครั้ง'))),
      (_) => Navigator.of(context).pop(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'แก้ไขบัญชี' : 'เพิ่มบัญชี')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'ชื่อบัญชี'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'กรุณากรอกชื่อบัญชี' : null,
            ),
            DropdownButtonFormField<AccountType>(
              initialValue: _accountType,
              decoration: const InputDecoration(labelText: 'ประเภทบัญชี'),
              items: AccountType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.label))).toList(),
              onChanged: (type) => setState(() => _accountType = type!),
            ),
            if (!widget.isEditing) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _openingBalanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'ยอดเปิดบัญชี'),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null) return 'กรอกตัวเลขให้ถูกต้อง';
                  if (parsed < 0) return 'ต้องมากกว่าหรือเท่ากับ 0';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 8),
            TextFormField(
              controller: _matchingKeywordsController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'คำค้นหาที่ใช้จับคู่', helperText: 'คั่นด้วยจุลภาค ใช้จับคู่บัญชีนี้จากข้อความในสลิป'),
            ),
            const SizedBox(height: 16),
            const Text('ธนาคาร'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kBankIcons.values
                  .map(
                    (bankIcon) => ChoiceChip(
                      label: Text(bankIcon.label),
                      avatar: Icon(bankIcon.icon, color: bankIcon.color, size: 18),
                      selected: _bankIconCode == bankIcon.code,
                      onSelected: (_) => setState(() => _bankIconCode = bankIcon.code),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.isEditing ? 'บันทึก' : 'สร้างบัญชี'),
            ),
          ],
        ),
      ),
    );
  }
}

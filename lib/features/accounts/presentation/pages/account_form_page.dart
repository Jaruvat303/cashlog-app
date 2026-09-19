import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/anchored_dropdown_panel.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/form_text_field.dart';
import '../../../../shared/widgets/pill_form_row.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../../data/accounts_repository.dart';
import '../../domain/account.dart';
import '../../domain/bank_icon.dart';

/// Create when [initial] is null, edit otherwise. `opening_balance` is only
/// ever shown/sent in create mode — `UpdateAccountInput` has no such field,
/// so it can't be edited after creation (confirmed against the live
/// swagger schema).
///
/// Post-launch UI polish ticket 05: restyled to the same icon+label+chevron
/// row / sticky-bottom-button component pattern ticket 04 established on
/// `AddTransactionPage`/`TransactionFormPage` (`PillFormRow`,
/// `PrimaryGradientButton`, `CircularIconButton`, `showAnchoredDropdown`) —
/// no new picker/row components invented here, and no change to any field
/// or to `_submit`'s call shape.
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

  Future<void> _pickAccountType(BuildContext anchorContext) async {
    final result = await showAnchoredDropdown<AccountType>(
      anchorContext: anchorContext,
      panelBuilder: (context, close) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final type in AccountType.values)
            DropdownPanelOption(
              key: Key('accountTypeOption_${type.name}'),
              label: type.label,
              selected: type == _accountType,
              onTap: () => close(type),
            ),
        ],
      ),
    );
    if (result != null) setState(() => _accountType = result);
  }

  Future<void> _pickBankIcon(BuildContext anchorContext) async {
    final result = await showAnchoredDropdown<String>(
      anchorContext: anchorContext,
      panelBuilder: (context, close) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final bankIcon in kBankIcons.values)
            DropdownPanelOption(
              key: Key('bankIconOption_${bankIcon.code}'),
              label: bankIcon.label,
              selected: bankIcon.code == _bankIconCode,
              onTap: () => close(bankIcon.code),
            ),
        ],
      ),
    );
    if (result != null) setState(() => _bankIconCode = result);
  }

  @override
  Widget build(BuildContext context) {
    final bankIcon = resolveBankIcon(_bankIconCode);

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircularIconButton(
                      icon: widget.isEditing ? RemixIcon.arrowLeftLine : RemixIcon.closeLine,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      widget.isEditing ? 'แก้ไขบัญชี' : 'เพิ่มบัญชี',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    // No trailing action on this form — closing an existing
                    // account is `AccountDetailPage`'s job, not this one's.
                    const SizedBox(width: 38, height: 38),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  children: [
                    FormTextField(
                      key: const Key('nameField'),
                      icon: RemixIcon.editLine,
                      controller: _nameController,
                      hintText: 'ชื่อบัญชี',
                      maxLength: 100,
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'กรุณากรอกชื่อบัญชี' : null,
                    ),
                    const SizedBox(height: 10),
                    Builder(
                      builder: (anchorContext) => PillFormRow(
                        key: const Key('accountTypePill'),
                        icon: RemixIcon.bankCardLine,
                        label: 'ประเภทบัญชี',
                        value: _accountType.label,
                        onTap: () => _pickAccountType(anchorContext),
                      ),
                    ),
                    if (!widget.isEditing) ...[
                      const SizedBox(height: 10),
                      FormTextField(
                        key: const Key('openingBalanceField'),
                        icon: RemixIcon.moneyDollarCircleLine,
                        controller: _openingBalanceController,
                        hintText: 'ยอดเปิดบัญชี',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          final parsed = double.tryParse(value ?? '');
                          if (parsed == null) return 'กรอกตัวเลขให้ถูกต้อง';
                          if (parsed < 0) return 'ต้องมากกว่าหรือเท่ากับ 0';
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 10),
                    Builder(
                      builder: (anchorContext) => PillFormRow(
                        key: const Key('bankIconPill'),
                        icon: bankIcon.icon,
                        iconColor: bankIcon.color,
                        label: 'ธนาคาร',
                        value: bankIcon.label,
                        onTap: () => _pickBankIcon(anchorContext),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FormTextField(
                      key: const Key('matchingKeywordsField'),
                      icon: RemixIcon.searchLine,
                      controller: _matchingKeywordsController,
                      hintText: 'คำค้นหาที่ใช้จับคู่',
                      helperText: 'คั่นด้วยจุลภาค ใช้จับคู่บัญชีนี้จากข้อความในสลิป',
                      minLines: 1,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    PrimaryGradientButton(
                      key: const Key('submitButton'),
                      label: widget.isEditing ? 'บันทึก' : 'สร้างบัญชี',
                      onTap: _isSubmitting ? null : _submit,
                      enabled: !_isSubmitting,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


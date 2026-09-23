import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/form_text_field.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../../../../shared/widgets/segmented_tabs.dart';
import '../../data/categories_repository.dart';
import '../../domain/category.dart';

/// Create when [initial] is null, edit otherwise — mirrors `AccountFormPage`.
/// [initialType] pre-selects income/expense when creating from a context
/// that already knows the type (e.g. the category grid picker's "เพิ่มใหม่"
/// cell) — ignored when [initial] is set, since editing keeps its own type.
///
/// Post-launch UI polish ticket 06: restyled to the same
/// `FormTextField`/`SegmentedTabs`/`PrimaryGradientButton`/`CircularIconButton`
/// component pattern tickets 04/05 already established on the Transaction
/// and Account forms — no new picker/row components invented here, and no
/// change to any field, validator, or `_submit`/`_confirmDelete` call shape.
/// The icon grid and color swatches have no equivalent in either of those
/// forms (nothing to reuse), so they keep their existing structure, just
/// restyled to sit inside the new page chrome.
class CategoryFormPage extends ConsumerStatefulWidget {
  const CategoryFormPage({super.key, this.initial, this.initialType});

  final Category? initial;
  final CategoryType? initialType;

  bool get isEditing => initial != null;

  @override
  ConsumerState<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends ConsumerState<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initial?.name ?? '',
  );
  late CategoryType _type =
      widget.initial?.type ?? widget.initialType ?? CategoryType.expense;
  late String _iconKey = widget.initial?.iconKey.isNotEmpty == true
      ? widget.initial!.iconKey
      : categoryIconChoicesFor(_type).first.$1;
  late String _colorHex = widget.initial?.colorHex.isNotEmpty == true
      ? widget.initial!.colorHex
      : kCategoryColorChoices.first;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final repo = ref.read(categoriesRepositoryProvider);
    final result = widget.isEditing
        ? await repo.update(
            widget.initial!.id,
            name: _nameController.text.trim(),
            type: _type,
            iconKey: _iconKey,
            colorHex: _colorHex,
          )
        : await repo.create(
            name: _nameController.text.trim(),
            type: _type,
            iconKey: _iconKey,
            colorHex: _colorHex,
          );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message ?? 'ทำรายการไม่สำเร็จ ลองใหม่อีกครั้ง'),
        ),
      ),
      (_) => Navigator.of(context).pop(true),
    );
  }

  /// Same delete guard as `CategoriesPage._confirmDelete` (spec §12.4/FR-2.2:
  /// count linked transactions from local cache, warn with that count — no
  /// backend endpoint for this) — duplicated here rather than shared because
  /// this page also needs to pop itself afterward, unlike the list's inline
  /// delete.
  Future<void> _confirmDelete() async {
    final category = widget.initial!;
    final count = await ref
        .read(categoriesRepositoryProvider)
        .countLinkedTransactions(category.id);
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('ลบ "${category.name}" ใช่ไหม'),
        content: Text(
          count == 0
              ? 'ไม่มีธุรกรรมที่ใช้หมวดหมู่นี้อยู่'
              : 'มี $count รายการที่ใช้หมวดหมู่นี้อยู่ — รายการเหล่านั้นจะกลายเป็น "ยังไม่ระบุหมวดหมู่" ยืนยันลบไหม',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await ref
        .read(categoriesRepositoryProvider)
        .delete(category.id);
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message ?? 'ทำรายการไม่สำเร็จ ลองใหม่อีกครั้ง'),
        ),
      ),
      (_) => Navigator.of(context).pop(true),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      icon: widget.isEditing
                          ? RemixIcon.arrowLeftLine
                          : RemixIcon.closeLine,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      widget.isEditing ? 'แก้ไขหมวดหมู่' : 'เพิ่มหมวดหมู่',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    // No trailing action — deleting an existing category
                    // stays a secondary action below the form (unchanged
                    // from before this restyle), not a Topbar icon.
                    const SizedBox(width: 38, height: 38),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  children: [
                    SegmentedTabs<CategoryType>(
                      values: CategoryType.values,
                      labels: CategoryType.values.map((t) => t.label).toList(),
                      selected: _type,
                      onChanged: (type) => setState(() {
                        _type = type;
                        final choices = categoryIconChoicesFor(type);
                        if (!choices.any((choice) => choice.$1 == _iconKey)) {
                          _iconKey = choices.first.$1;
                        }
                      }),
                    ),
                    const SizedBox(height: 12),
                    FormTextField(
                      key: const Key('nameField'),
                      icon: RemixIcon.editLine,
                      controller: _nameController,
                      hintText: 'ชื่อหมวดหมู่ เช่น ค่ากาแฟ',
                      maxLength: 100,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'กรุณากรอกชื่อหมวดหมู่'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'เลือกไอคอน',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'เลื่อนดูเพิ่ม',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textFaint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 6,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: categoryIconChoicesFor(_type).map((choice) {
                        final selected = _iconKey == choice.$1;
                        final accent = selected
                            ? colorFromHex(_colorHex)
                            : AppColors.textSecondary;
                        return InkWell(
                          onTap: () => setState(() => _iconKey = choice.$1),
                          borderRadius: BorderRadius.circular(13),
                          child: Container(
                            decoration: BoxDecoration(
                              color: selected
                                  ? colorFromHex(_colorHex)
                                        .withValues(alpha: 0.14)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(13),
                              border: selected
                                  ? Border.all(
                                      color: colorFromHex(_colorHex),
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Icon(choice.$3, size: 19, color: accent),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'เลือกสี',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: kCategoryColorChoices
                          .map(
                            (hex) => InkWell(
                              onTap: () => setState(() => _colorHex = hex),
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: colorFromHex(hex),
                                  shape: BoxShape.circle,
                                  boxShadow: _colorHex == hex
                                      ? [
                                          BoxShadow(
                                            color: colorFromHex(hex)
                                                .withValues(alpha: 0.5),
                                            blurRadius: 0,
                                            spreadRadius: 2.5,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: _colorHex == hex
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    PrimaryGradientButton(
                      key: const Key('submitButton'),
                      label: 'บันทึก',
                      onTap: _isSubmitting ? null : _submit,
                      enabled: !_isSubmitting,
                    ),
                    if (widget.isEditing) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          key: const Key('deleteCategoryButton'),
                          onPressed: _isSubmitting ? null : _confirmDelete,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.expense,
                          ),
                          child: const Text('ลบหมวดหมู่'),
                        ),
                      ),
                    ],
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

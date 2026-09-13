import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../core/theme/app_theme.dart';
import '../../features/categories/domain/category.dart';
import '../../features/categories/presentation/pages/category_form_page.dart';
import '../../features/categories/presentation/providers/categories_providers.dart';
import 'category_icon.dart';

/// Disambiguates "the sheet was dismissed with no choice made" (`null`, from
/// `showModalBottomSheet` itself) from "the user explicitly picked
/// Uncategorized" (`CategoryPickerResult(null)`) — same reasoning as the old
/// `_QuickAssignSelection` this replaces.
class CategoryPickerResult {
  const CategoryPickerResult(this.categoryId);
  final int? categoryId;
}

/// Mockup screen 1c: a 4-column icon grid, one tap = immediate selection, no
/// confirm button. Shared by the Transactions feed's quick-assign (tap the
/// row's category icon), the Edit Transaction sheet's category row, and
/// Manual Entry's category box — every category-picking surface in the app
/// funnels through this one sheet so they can never drift apart visually.
Future<CategoryPickerResult?> showCategoryGridPicker(
  BuildContext context, {
  required CategoryType categoryType,
  required int? currentCategoryId,
  required String subtitle,
}) {
  return showModalBottomSheet<CategoryPickerResult>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CategoryGridSheet(categoryType: categoryType, currentCategoryId: currentCategoryId, subtitle: subtitle),
  );
}

class _CategoryGridSheet extends ConsumerStatefulWidget {
  const _CategoryGridSheet({required this.categoryType, required this.currentCategoryId, required this.subtitle});

  final CategoryType categoryType;
  final int? currentCategoryId;
  final String subtitle;

  @override
  ConsumerState<_CategoryGridSheet> createState() => _CategoryGridSheetState();
}

class _CategoryGridSheetState extends ConsumerState<_CategoryGridSheet> {
  final _gridScrollController = ScrollController();

  @override
  void dispose() {
    _gridScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(allCategoriesProvider);
    // Fixed at half the screen height regardless of category count (spec:
    // Design 2 / ticket 03) — previously this Column sized itself to
    // content (`mainAxisSize.min` + shrink-wrapped grid), so a long enough
    // category list grew the sheet past half-screen or overflowed instead
    // of scrolling. The grid area below is the only part that scrolls; the
    // header/subtitle/footer stay put.
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.5;
    return SizedBox(
      height: sheetHeight,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Column(
            children: [
              const SheetHandle(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('เลือกหมวดหมู่', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)),
                  InkWell(
                    key: const Key('categoryPickerCloseButton'),
                    onTap: () => Navigator.of(context).pop(),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(color: AppColors.screenBackground, shape: BoxShape.circle),
                      child: const Icon(RemixIcon.closeLine, size: 16, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(widget.subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: categoriesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('โหลดหมวดหมู่ไม่สำเร็จ: $error')),
                  data: (categories) {
                    final matching = categories.where((c) => c.type == widget.categoryType).toList();
                    return Scrollbar(
                      controller: _gridScrollController,
                      thumbVisibility: true,
                      child: GridView.count(
                        controller: _gridScrollController,
                        crossAxisCount: 4,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.82,
                        children: [
                          _GridCell(
                            key: const Key('categoryOptionUncategorized'),
                            label: 'ยังไม่ระบุ',
                            icon: RemixIcon.questionFill,
                            iconColor: AppColors.textSecondary,
                            backgroundColor: AppColors.screenBackground,
                            selected: widget.currentCategoryId == null,
                            onTap: () => Navigator.of(
                              context,
                            ).pop(widget.currentCategoryId == null ? null : const CategoryPickerResult(null)),
                          ),
                          for (final category in matching)
                            _GridCell(
                              key: Key('categoryOption_${category.id}'),
                              label: category.name,
                              icon: resolveCategoryIcon(category.iconKey),
                              iconColor: colorFromHex(category.colorHex),
                              backgroundColor: colorFromHex(category.colorHex).withValues(alpha: 0.12),
                              selected: widget.currentCategoryId == category.id,
                              onTap: () => Navigator.of(
                                context,
                              ).pop(widget.currentCategoryId == category.id ? null : CategoryPickerResult(category.id)),
                            ),
                          _GridCell(
                            key: const Key('categoryOptionAddNew'),
                            label: 'เพิ่มใหม่',
                            icon: RemixIcon.addLine,
                            iconColor: AppColors.textSecondary,
                            backgroundColor: AppColors.screenBackground,
                            dashed: true,
                            selected: false,
                            onTap: () async {
                              final navigator = Navigator.of(context);
                              final created = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(builder: (_) => CategoryFormPage(initialType: widget.categoryType)),
                              );
                              if (created == true) navigator.pop();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(RemixIcon.flashlightLine, size: 13, color: AppColors.textMuted),
                  SizedBox(width: 7),
                  Text('แตะไอคอนเดียว = บันทึกและปิดทันที ไม่มีปุ่มยืนยัน', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({
    super.key,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.selected,
    required this.onTap,
    this.dashed = false,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final bool selected;
  final bool dashed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(18),
              border: selected
                  ? Border.all(color: AppColors.primary, width: 2)
                  : dashed
                  ? Border.all(color: AppColors.textFaint, width: 1.5)
                  : null,
            ),
            child: Stack(
              children: [
                Center(child: Icon(icon, color: iconColor, size: 23)),
                if (selected)
                  const Positioned(
                    right: 2,
                    top: 2,
                    child: Icon(Icons.check, size: 14, color: AppColors.primary),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.chipUnselectedText), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

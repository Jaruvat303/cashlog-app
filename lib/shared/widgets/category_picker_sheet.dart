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
    builder: (_) => _CategoryGridSheet(
      categoryType: categoryType,
      currentCategoryId: currentCategoryId,
      subtitle: subtitle,
    ),
  );
}

class _CategoryGridSheet extends ConsumerStatefulWidget {
  const _CategoryGridSheet({
    required this.categoryType,
    required this.currentCategoryId,
    required this.subtitle,
  });

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
                  const Text(
                    'เลือกหมวดหมู่',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  InkWell(
                    key: const Key('categoryPickerCloseButton'),
                    onTap: () => Navigator.of(context).pop(),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        RemixIcon.closeLine,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: categoriesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      Center(child: Text('โหลดหมวดหมู่ไม่สำเร็จ: $error')),
                  data: (categories) {
                    final matching = categories
                        .where((c) => c.type == widget.categoryType)
                        .toList();
                    final tiles = [
                      CategoryGridTile(
                        key: const Key('categoryOptionUncategorized'),
                        label: 'ยังไม่ระบุ',
                        icon: RemixIcon.questionFill,
                        iconColor: AppColors.textSecondary,
                        backgroundColor: AppColors.background,
                        borderColor: AppColors.textSecondary,
                        selected: widget.currentCategoryId == null,
                        onTap: () => Navigator.of(context).pop(
                          widget.currentCategoryId == null
                              ? null
                              : const CategoryPickerResult(null),
                        ),
                      ),
                      for (final category in matching)
                        CategoryGridTile(
                          key: Key('categoryOption_${category.id}'),
                          label: category.name,
                          icon: resolveCategoryIcon(category.iconKey),
                          iconColor: colorFromHex(category.colorHex),
                          backgroundColor: colorFromHex(category.colorHex)
                              .withValues(alpha: 0.15),
                          borderColor: colorFromHex(category.colorHex),
                          selected: widget.currentCategoryId == category.id,
                          onTap: () => Navigator.of(context).pop(
                            widget.currentCategoryId == category.id
                                ? null
                                : CategoryPickerResult(category.id),
                          ),
                        ),
                      CategoryGridTile(
                        key: const Key('categoryOptionAddNew'),
                        label: 'เพิ่มใหม่',
                        icon: RemixIcon.addLine,
                        iconColor: AppColors.textSecondary,
                        backgroundColor: AppColors.background,
                        borderColor: AppColors.textFaint,
                        dashed: true,
                        selected: false,
                        onTap: () async {
                          final navigator = Navigator.of(context);
                          final created = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => CategoryFormPage(
                                    initialType: widget.categoryType,
                                  ),
                                ),
                              );
                          if (created == true) navigator.pop();
                        },
                      ),
                    ];
                    return Scrollbar(
                      controller: _gridScrollController,
                      thumbVisibility: true,
                      child: GridView.builder(
                        controller: _gridScrollController,
                        // Ticket 11: this grid used to size cells by
                        // `childAspectRatio` (0.82), which scales cell
                        // *height* with cell *width* — on a real phone
                        // width that came out shorter than `CategoryGridTile`
                        // actually needs for its 56px icon + up to 2 lines of
                        // label, overflowing by 7.6px (confirmed by
                        // reproducing the exact figure QA reported). A fixed
                        // `mainAxisExtent` sized to the tile's real content
                        // decouples row height from cell width, the same fix
                        // ticket 08 already applied to the Categories grid
                        // screen's own (separate — see `CategoryGridTile`'s
                        // doc comment) tile/grid.
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 10,
                              mainAxisExtent: 108,
                            ),
                        itemCount: tiles.length,
                        itemBuilder: (context, index) => tiles[index],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              // Found while verifying ticket 11's fix, not part of what it
              // described: an unrelated, independent overflow — this footer
              // hint's `Text` had no `Expanded`/`Flexible`, so at a
              // realistic phone width (390dp, well within the 360-412dp
              // real Android phones use) it doesn't fit on one line and
              // overflows ~197px to the right. `Flexible` here lets it wrap
              // to 2 lines instead.
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      RemixIcon.flashlightLine,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      'แตะไอคอนเดียว = บันทึกและปิดทันที ไม่มีปุ่มยืนยัน',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The 56×56 rounded category tile used by this file's category picker
/// sheet: a colored-tint icon square that gets a `2px solid
/// {categoryColor}` border plus a small accent-gradient checkmark badge
/// when selected (vs. `2px solid transparent` otherwise).
///
/// Ticket 11: despite this doc comment's previous claim, this widget is
/// **not** shared with the Categories grid screen
/// (`features/categories/presentation/pages/categories_page.dart`) — that
/// screen builds its own separate `InkWell`/`Column`/`Container` tile
/// inline and has never referenced `CategoryGridTile` (confirmed against
/// full git history). The two independently overflowed on a 2-line label at
/// phone width for the same underlying reason (aspect-ratio-based grid
/// cells scale height with cell width, not with content) — ticket 08 fixed
/// the Categories grid screen's own copy; ticket 11 fixed this one — but
/// they are two separate widgets that must each be fixed on their own if
/// this happens again, not one shared component.
class CategoryGridTile extends StatelessWidget {
  const CategoryGridTile({
    super.key,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.selected,
    required this.onTap,
    this.dashed = false,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final bool selected;
  final bool dashed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.cardLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(AppRadii.cardLarge),
                    border: dashed
                        ? Border.all(color: AppColors.textFaint, width: 1.5)
                        : Border.all(
                            color: selected ? borderColor : Colors.transparent,
                            width: 2,
                          ),
                  ),
                  child: Center(child: Icon(icon, color: iconColor, size: 23)),
                ),
                if (selected)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.accentGradient,
                        border: Border.fromBorderSide(
                          BorderSide(color: AppColors.background, width: 2),
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            // Ticket 11: an explicit `height` tightens the font's own
            // (Thai-script-generous) default line spacing — same fix ticket
            // 08 applied to the Categories grid screen's tile label, needed
            // here for the same reason: without it, two lines at this font
            // size don't fit `mainAxisExtent` above.
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.15,
              color: AppColors.chipUnselectedText,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

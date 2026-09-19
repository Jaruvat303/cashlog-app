import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/segmented_tabs.dart';
import '../../data/categories_repository.dart';
import '../../domain/category.dart';
import '../providers/categories_providers.dart';
import 'category_form_page.dart';

/// Mockup screen 1f's "category settings behind the modal" — Tab
/// รายรับ/รายจ่าย over a grid of icon cards, "+ เพิ่มหมวดหมู่" in the header
/// rather than a FAB (matches the mockup exactly; the FAB slot on this tab
/// is otherwise empty since AppShell's own FAB is the camera button).
class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  CategoryType _selectedType = CategoryType.income;

  @override
  void initState() {
    super.initState();
    // Cache paints first via allCategoriesProvider's drift watch; this kicks
    // off the API sync that keeps it fresh (CLAUDE.md: online-only + read
    // cache). Silent: nobody asked for this one, so a failure (e.g. offline
    // on app open) shouldn't interrupt with a SnackBar — the cached list is
    // already on screen either way.
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh(showErrorSnackBar: false));
  }

  Future<void> _refresh({bool showErrorSnackBar = true}) async {
    final result = await ref.read(categoriesRefreshProvider.notifier).refresh();
    if (!mounted || !showErrorSnackBar) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message ?? 'รีเฟรชหมวดหมู่ไม่สำเร็จ'))),
      (_) {},
    );
  }

  /// Delete guard (spec §12.4 / FR-2.2): count linked transactions from the
  /// local cache first and warn with that count before the delete is ever
  /// confirmed — no backend endpoint exists (or is needed) for this count.
  Future<void> _confirmDelete(Category category) async {
    final count = await ref.read(categoriesRepositoryProvider).countLinkedTransactions(category.id);
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ลบ "${category.name}" ใช่ไหม'),
        content: Text(
          count == 0
              ? 'ไม่มีธุรกรรมที่ใช้หมวดหมู่นี้อยู่'
              : 'มี $count รายการที่ใช้หมวดหมู่นี้อยู่ — รายการเหล่านั้นจะกลายเป็น "ยังไม่ระบุหมวดหมู่" ยืนยันลบไหม',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('ลบ')),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await ref.read(categoriesRepositoryProvider).delete(category.id);
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message ?? 'ทำรายการไม่สำเร็จ ลองใหม่อีกครั้ง'))),
      (_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบหมวดหมู่แล้ว'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('หมวดหมู่', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  CircularIconButton(
                    icon: RemixIcon.addLine,
                    gradient: AppColors.accentGradient,
                    iconColor: Colors.white,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CategoryFormPage(initialType: _selectedType))),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: SegmentedTabs<CategoryType>(
                values: const [CategoryType.income, CategoryType.expense],
                labels: const ['รายรับ', 'รายจ่าย'],
                selected: _selectedType,
                onChanged: (type) => setState(() => _selectedType = type),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: categoriesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('โหลดหมวดหมู่ไม่สำเร็จ: $error')),
                  data: (categories) {
                    final matching = categories.where((c) => c.type == _selectedType).toList();
                    if (matching.isEmpty) {
                      return ListView(
                        children: const [
                          Padding(padding: EdgeInsets.all(32), child: Center(child: Text('ยังไม่มีหมวดหมู่ — แตะ "+" เพื่อเริ่ม'))),
                        ],
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: matching.length,
                      itemBuilder: (context, index) {
                        final category = matching[index];
                        return InkWell(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CategoryFormPage(initial: category))),
                          onLongPress: () => _confirmDelete(category),
                          borderRadius: BorderRadius.circular(AppRadii.cardLarge),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: colorFromHex(category.colorHex).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(AppRadii.cardLarge),
                                ),
                                child: Icon(resolveCategoryIcon(category.iconKey), color: colorFromHex(category.colorHex), size: 23),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                category.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.chipUnselectedText),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

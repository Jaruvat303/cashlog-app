import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/category_icon.dart';
import '../../data/categories_repository.dart';
import '../../domain/category.dart';
import '../providers/categories_providers.dart';
import 'category_form_page.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
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
      ).showSnackBar(SnackBar(content: Text(failure.message ?? 'Could not refresh categories'))),
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
        title: Text('Delete "${category.name}"?'),
        content: Text(
          count == 0
              ? 'This category has no transactions linked to it.'
              : '$count transaction${count == 1 ? '' : 's'} use this category. '
                    'Deleting it will leave ${count == 1 ? 'that transaction' : 'them'} uncategorized — '
                    'they will not be deleted.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await ref.read(categoriesRepositoryProvider).delete(category.id);
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message ?? 'Request failed. Please try again.'))),
      (_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category deleted'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Failed to load categories: $error')),
          data: (categories) {
            if (categories.isEmpty) {
              return ListView(
                children: const [
                  Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No categories yet — tap + to add one'))),
                ],
              );
            }
            return ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorFromHex(category.colorHex).withValues(alpha: 0.15),
                    child: Icon(resolveCategoryIcon(category.iconKey), color: colorFromHex(category.colorHex)),
                  ),
                  title: Text(category.name),
                  subtitle: Text(category.type.label),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _confirmDelete(category)),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CategoryFormPage(initial: category))),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoryFormPage())),
        child: const Icon(Icons.add),
      ),
    );
  }
}

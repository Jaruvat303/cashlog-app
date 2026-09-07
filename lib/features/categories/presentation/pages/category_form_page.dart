import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/categories_repository.dart';
import '../../domain/category.dart';
import '../../domain/category_icon.dart';

/// Create when [initial] is null, edit otherwise — mirrors `AccountFormPage`.
class CategoryFormPage extends ConsumerStatefulWidget {
  const CategoryFormPage({super.key, this.initial});

  final Category? initial;

  bool get isEditing => initial != null;

  @override
  ConsumerState<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends ConsumerState<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.initial?.name ?? '');
  late CategoryType _type = widget.initial?.type ?? CategoryType.expense;
  late String _iconKey = widget.initial?.iconKey.isNotEmpty == true ? widget.initial!.iconKey : kCategoryIconChoices.first.$1;
  late String _colorHex = widget.initial?.colorHex.isNotEmpty == true ? widget.initial!.colorHex : kCategoryColorChoices.first;
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
        ? await repo.update(widget.initial!.id, name: _nameController.text.trim(), type: _type, iconKey: _iconKey, colorHex: _colorHex)
        : await repo.create(name: _nameController.text.trim(), type: _type, iconKey: _iconKey, colorHex: _colorHex);
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit category' : 'New category')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Name is required' : null,
            ),
            DropdownButtonFormField<CategoryType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: CategoryType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.label))).toList(),
              onChanged: (type) => setState(() => _type = type!),
            ),
            const SizedBox(height: 16),
            const Text('Icon'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kCategoryIconChoices
                  .map(
                    (choice) => ChoiceChip(
                      label: Text(choice.$2),
                      avatar: Icon(choice.$3, size: 18),
                      selected: _iconKey == choice.$1,
                      onSelected: (_) => setState(() => _iconKey = choice.$1),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text('Color'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kCategoryColorChoices
                  .map(
                    (hex) => InkWell(
                      onTap: () => setState(() => _colorHex = hex),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colorFromHex(hex),
                          shape: BoxShape.circle,
                          border: _colorHex == hex ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3) : null,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            FilledButton(
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

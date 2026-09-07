import 'package:cashlog/features/categories/data/category_mapper.dart';
import 'package:cashlog/features/categories/domain/category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('categoryFromJson parses a category response', () {
    final category = categoryFromJson({
      'id': 7,
      'name': 'Food',
      'type': 'expense',
      'icon_key': 'food',
      'color_hex': '#EF4444',
    });

    expect(category.id, 7);
    expect(category.name, 'Food');
    expect(category.type, CategoryType.expense);
    expect(category.iconKey, 'food');
    expect(category.colorHex, '#EF4444');
  });

  test('categoryFromJson tolerates a missing icon_key/color_hex', () {
    final category = categoryFromJson({'id': 1, 'name': 'Misc', 'type': 'income'});

    expect(category.iconKey, '');
    expect(category.colorHex, '');
  });

  test('round-trips through a CachedCategoriesCompanion', () {
    const category = Category(id: 1, name: 'Salary', type: CategoryType.income, iconKey: 'salary', colorHex: '#22C55E');

    final companion = categoryToCompanion(category);
    expect(companion.name.value, 'Salary');
    expect(companion.type.value, 'income');
    expect(companion.iconKey.value, 'salary');
    expect(companion.colorHex.value, '#22C55E');
  });

  test('categoryTypeFromWire falls back to expense for an unrecognized value', () {
    expect(categoryTypeFromWire('transfer'), CategoryType.expense);
    expect(categoryTypeFromWire('income'), CategoryType.income);
  });
}

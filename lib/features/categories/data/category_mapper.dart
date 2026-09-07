import 'package:drift/drift.dart' show Value;

import '../../../core/db/app_database.dart';
import '../domain/category.dart';

/// Wire field names mirror the `CachedCategories` drift columns exactly
/// (`type`, `icon_key`, `color_hex`), following the same convention as
/// `account_type`/`bank_icon` in `account_mapper.dart`. No swagger was
/// available locally to confirm this against a live response the way T4's
/// accounts mapper was — spot-check against `GET /api/v1/categories` and
/// adjust only this file if a field name differs.
Category categoryFromJson(Map<String, dynamic> json) => Category(
  id: json['id'] as int,
  name: json['name'] as String,
  type: categoryTypeFromWire(json['type'] as String),
  iconKey: json['icon_key'] as String? ?? '',
  colorHex: json['color_hex'] as String? ?? '',
);

Map<String, dynamic> createCategoryBody({
  required String name,
  required CategoryType type,
  required String iconKey,
  required String colorHex,
}) => {
  'name': name,
  'type': type.name,
  'icon_key': iconKey,
  'color_hex': colorHex,
};

Map<String, dynamic> updateCategoryBody({
  required String name,
  required CategoryType type,
  required String iconKey,
  required String colorHex,
}) => {
  'name': name,
  'type': type.name,
  'icon_key': iconKey,
  'color_hex': colorHex,
};

CachedCategoriesCompanion categoryToCompanion(Category category) => CachedCategoriesCompanion.insert(
  id: Value(category.id),
  name: category.name,
  type: category.type.name,
  iconKey: category.iconKey,
  colorHex: category.colorHex,
);

Category categoryFromCached(CachedCategory row) => Category(
  id: row.id,
  name: row.name,
  type: categoryTypeFromWire(row.type),
  iconKey: row.iconKey,
  colorHex: row.colorHex,
);

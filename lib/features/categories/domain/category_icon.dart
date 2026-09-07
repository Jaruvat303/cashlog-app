import 'package:flutter/material.dart';

/// Curated picker data only — unlike `BankIcon` (client-owned identity, never
/// sent as color to the backend), `CachedCategories`/the category API really
/// do persist `icon_key` and `color_hex` as free strings (see
/// `category_mapper.dart`), so this map exists purely to give the create/edit
/// form a fixed set of choices rather than a raw text field. The resolver
/// below tolerates any key/hex this list doesn't cover (e.g. hand-edited
/// data, a future client version) so display never crashes.
const List<(String key, String label, IconData icon)> kCategoryIconChoices = [
  ('food', 'Food', Icons.restaurant),
  ('transport', 'Transport', Icons.directions_car),
  ('shopping', 'Shopping', Icons.shopping_bag),
  ('bills', 'Bills', Icons.receipt_long),
  ('salary', 'Salary', Icons.payments),
  ('health', 'Health', Icons.local_hospital),
  ('entertainment', 'Entertainment', Icons.movie),
  ('education', 'Education', Icons.school),
  ('home', 'Home', Icons.home),
  ('gift', 'Gift', Icons.card_giftcard),
  ('travel', 'Travel', Icons.flight),
  ('other', 'Other', Icons.category_outlined),
];

const List<String> kCategoryColorChoices = [
  '#EF4444',
  '#F97316',
  '#EAB308',
  '#22C55E',
  '#14B8A6',
  '#3B82F6',
  '#8B5CF6',
  '#EC4899',
];

const _fallbackIcon = Icons.category_outlined;
const Color fallbackCategoryColor = Color(0xFF9E9E9E);

/// A `icon_key` not in [kCategoryIconChoices] (older client, hand-edited
/// data) falls back to a generic icon rather than crashing — same
/// resilience pattern as `resolveBankIcon`.
IconData resolveCategoryIcon(String iconKey) {
  for (final choice in kCategoryIconChoices) {
    if (choice.$1 == iconKey) return choice.$3;
  }
  return _fallbackIcon;
}

/// A `color_hex` that isn't a parseable `#RRGGBB`/`#AARRGGBB` string falls
/// back to a neutral gray rather than throwing.
Color colorFromHex(String colorHex) {
  final hex = colorHex.replaceFirst('#', '');
  final normalized = hex.length == 6 ? 'FF$hex' : hex;
  final value = int.tryParse(normalized, radix: 16);
  return value == null ? fallbackCategoryColor : Color(value);
}

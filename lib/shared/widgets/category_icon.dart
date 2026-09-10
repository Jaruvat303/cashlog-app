import 'package:flutter/material.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

/// Curated picker data only — unlike `BankIcon` (client-owned identity, never
/// sent as color to the backend), `CachedCategories`/the category API really
/// do persist `icon_key` and `color_hex` as free strings (see
/// `category_mapper.dart`), so this map exists purely to give the create/edit
/// form a fixed set of choices rather than a raw text field. The resolver
/// below tolerates any key/hex this list doesn't cover (e.g. hand-edited
/// data, a future client version) so display never crashes.
///
/// Keys are real Remix icon names, and this list is now the exact 21
/// `icon_key` values seeded on the live dev backend (confirmed via
/// `GET /api/v1/categories`) — not an invented/curated subset. That
/// verification is what caught two real bugs during T8's DoD review:
///
/// 1. `flutter_remix` (the package originally used here) is an
///    older/incomplete Remix Icon port — most of these 21 real keys weren't
///    in it at all, so most real categories silently showed the generic
///    fallback icon. Migrated to `remix_icons_flutter` (maps to Remix Icon
///    v4.9.1, current) to fix that.
/// 2. `remix_icons_flutter` constants are camelCase with a `Fill`/`Line`
///    suffix, generated straight from remixicon.com's own names (e.g.
///    `restaurant-fill` -> `RemixIcon.restaurantFill`, confirmed against
///    the package's own README/generated source — not guessed).
///
/// One real key doesn't actually exist in Remix Icon under that name: the
/// backend's `sparkles-fill` has no matching `RemixIcon.sparklesFill` —
/// the real remixicon.com icon is named `sparkling-fill`
/// (`RemixIcon.sparklingFill`). Aliased deliberately below rather than left
/// to fall back, since it's clearly the intended icon — but this is a
/// backend seed-data naming inconsistency, not a client guess, and is worth
/// fixing at the source rather than papering over here indefinitely.
///
/// Lives in `shared/` (not `features/categories/domain/`) because it's
/// resolved from three features — categories (the picker itself), the
/// transaction feed row, and the dashboard's expense-by-category chart —
/// and CLAUDE.md only allows cross-feature reuse through `core/`/`shared/`.
const List<(String key, String label, IconData icon)> kCategoryIconChoices = [
  ('question-fill', 'Uncategorized', RemixIcon.questionFill),
  ('restaurant-fill', 'Food & Drink', RemixIcon.restaurantFill),
  ('cup-fill', 'Snacks & Café', RemixIcon.cupFill),
  ('shopping-bag-3-fill', 'Groceries', RemixIcon.shoppingBag3Fill),
  ('bus-fill', 'Public Transport', RemixIcon.busFill),
  ('car-fill', 'Fuel & Car', RemixIcon.carFill),
  ('home-4-fill', 'Housing', RemixIcon.home4Fill),
  ('flashlight-fill', 'Utilities', RemixIcon.flashlightFill),
  ('wifi-fill', 'Internet & Phone', RemixIcon.wifiFill),
  ('t-shirt-fill', 'Fashion', RemixIcon.tShirtFill),
  // Backend seed data names this "sparkles-fill"; the real Remix Icon name
  // is "sparkling-fill" — see the class doc comment above.
  ('sparkles-fill', 'Beauty & Skincare', RemixIcon.sparklingFill),
  ('clapperboard-fill', 'Entertainment', RemixIcon.clapperboardFill),
  ('goblet-fill', 'Parties & Socializing', RemixIcon.gobletFill),
  ('plane-fill', 'Travel', RemixIcon.planeFill),
  ('capsule-fill', 'Medical & Medicine', RemixIcon.capsuleFill),
  ('shield-check-fill', 'Insurance', RemixIcon.shieldCheckFill),
  ('book-open-fill', 'Education', RemixIcon.bookOpenFill),
  ('computer-fill', 'Electronics & Gadgets', RemixIcon.computerFill),
  ('footprint-fill', 'Pet Supplies', RemixIcon.footprintFill),
  ('heart-3-fill', 'Donations', RemixIcon.heart3Fill),
  ('archive-fill', 'Other', RemixIcon.archiveFill),
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

const _fallbackIcon = RemixIcon.folderFill;
const Color fallbackCategoryColor = Color(0xFF9E9E9E);

/// A `icon_key` not in [kCategoryIconChoices] (older client, hand-edited
/// data) falls back to a generic icon rather than crashing — same
/// resilience pattern as `resolveBankIcon`. The backend's own bare
/// `"folder"` default (sent when a category has no `icon_key` at all,
/// confirmed against a live `GET /api/v1/transactions/summary` response for
/// an uncategorized transaction) is recognized explicitly here rather than
/// left to fall through, even though it happens to resolve to the same icon
/// as the unrecognized-key fallback.
IconData resolveCategoryIcon(String iconKey) {
  if (iconKey == 'folder') return _fallbackIcon;
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

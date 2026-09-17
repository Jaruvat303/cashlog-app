import 'package:cashlog/shared/widgets/category_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

/// The exact 21 `icon_key` values seeded on the live dev backend, confirmed
/// via `GET /api/v1/categories` during T8's DoD re-verification — this is
/// what actually caught the flutter_remix coverage gap, not a guess.
const _liveDevIconKeys = [
  'question-fill',
  'restaurant-fill',
  'cup-fill',
  'shopping-bag-3-fill',
  'bus-fill',
  'car-fill',
  'home-4-fill',
  'flashlight-fill',
  'wifi-fill',
  't-shirt-fill',
  'sparkles-fill',
  'clapperboard-fill',
  'goblet-fill',
  'plane-fill',
  'capsule-fill',
  'shield-check-fill',
  'book-open-fill',
  'computer-fill',
  'footprint-fill',
  'heart-3-fill',
  'archive-fill',
];

/// The 10 real income `icon_key` values the backend returns for income
/// categories (spec: "Frontend — income category icons"), each expected to
/// map to its own distinct Remix icon rather than the generic fallback.
const _liveDevIncomeIconKeys = <(String key, IconData icon)>[
  ('wallet-3-fill', RemixIcon.wallet3Fill),
  ('gift-fill', RemixIcon.giftFill),
  ('tools-fill', RemixIcon.toolsFill),
  ('store-2-fill', RemixIcon.store2Fill),
  ('line-chart-fill', RemixIcon.lineChartFill),
  ('trophy-fill', RemixIcon.trophyFill),
  ('key-2-fill', RemixIcon.key2Fill),
  ('hand-heart-fill', RemixIcon.handHeartFill),
  ('coins-fill', RemixIcon.coinsFill),
  ('money-dollar-circle-fill', RemixIcon.moneyDollarCircleFill),
];

void main() {
  test('resolveCategoryIcon resolves every real dev icon_key to a real, non-fallback icon', () {
    for (final key in _liveDevIconKeys) {
      final icon = resolveCategoryIcon(key);
      expect(icon, isNot(RemixIcon.folderFill), reason: '"$key" should resolve to its own icon, not the generic fallback');
    }
  });

  test('resolveCategoryIcon resolves every real income icon_key to its own distinct, non-fallback icon', () {
    final seenIcons = <IconData>{};
    for (final (key, expectedIcon) in _liveDevIncomeIconKeys) {
      final icon = resolveCategoryIcon(key);
      expect(icon, isNot(RemixIcon.folderFill), reason: '"$key" should resolve to its own icon, not the generic fallback');
      expect(icon, expectedIcon, reason: '"$key" should resolve to its exact expected Remix icon');
      expect(seenIcons.add(icon), isTrue, reason: '"$key" resolved to an icon already used by another income key — icons must be distinct');
    }
  });

  test('resolveCategoryIcon resolves specific known Remix keys to their exact icon', () {
    expect(resolveCategoryIcon('restaurant-fill'), RemixIcon.restaurantFill);
    expect(resolveCategoryIcon('shopping-bag-3-fill'), RemixIcon.shoppingBag3Fill);
  });

  test('resolveCategoryIcon aliases the backend\'s "sparkles-fill" (not a real Remix name) to the real sparkling-fill icon', () {
    expect(resolveCategoryIcon('sparkles-fill'), RemixIcon.sparklingFill);
  });

  test('resolveCategoryIcon falls back to the generic icon for an unrecognized key', () {
    // e.g. a category created before the Remix migration, still holding the
    // old client-invented key scheme ("food", "transport", ...).
    expect(resolveCategoryIcon('food'), RemixIcon.folderFill);
    expect(resolveCategoryIcon(''), RemixIcon.folderFill);
  });

  test('resolveCategoryIcon recognizes the backend\'s bare "folder" default explicitly', () {
    expect(resolveCategoryIcon('folder'), RemixIcon.folderFill);
  });

  test('colorFromHex parses a 6-digit hex', () {
    expect(colorFromHex('#EF4444'), const Color(0xFFEF4444));
  });

  test('colorFromHex falls back to gray for an unparseable string', () {
    expect(colorFromHex('not-a-color'), fallbackCategoryColor);
  });
}

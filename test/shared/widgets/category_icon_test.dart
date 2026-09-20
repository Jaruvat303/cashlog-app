import 'dart:convert';
import 'dart:io';

import 'package:cashlog/shared/widgets/category_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

/// Every `icon_key` a live category can actually have, read straight out of
/// a raw `GET /api/v1/categories?type=...` response captured against the
/// dev backend (`test/fixtures/README.md` has the refresh command) — never
/// hand-typed. Three rounds of category-icon-fallback bugs (post-launch UI
/// polish tickets 01, 07, and 08) shipped specifically because both the
/// resolver *and* this test used to hardcode a snapshot of the key list in
/// Dart source, which silently went stale the next time a category was
/// added to the seed data. Ticket 09 root-caused this on the resolver side
/// (`resolveCategoryIcon` now resolves against the complete Remix Icon set,
/// not a hand-picked subset — see `category_icon.dart`'s doc comment); this
/// test still reads its expected keys from a fixture rather than hardcoding
/// them, so the only way it can go stale is the fixture itself going stale
/// — one obvious file to refresh, not scattered Dart literals.
List<String> _iconKeysFromFixture(String filename) {
  final json = jsonDecode(File('test/fixtures/$filename').readAsStringSync()) as Map<String, dynamic>;
  final rows = json['data'] as List<dynamic>;
  return [for (final row in rows) (row as Map<String, dynamic>)['icon_key'] as String];
}

void main() {
  final expenseIconKeys = _iconKeysFromFixture('categories_expense_response.json');
  final incomeIconKeys = _iconKeysFromFixture('categories_income_response.json');

  test('fixtures actually loaded real category data (guards against an empty/broken fixture silently passing everything below)', () {
    expect(expenseIconKeys, isNotEmpty);
    expect(incomeIconKeys, isNotEmpty);
  });

  test('resolveCategoryIcon resolves every real expense icon_key to a real, non-fallback icon', () {
    for (final key in expenseIconKeys) {
      expect(resolveCategoryIcon(key), isNot(RemixIcon.folderFill), reason: '"$key" should resolve to its own icon, not the generic fallback');
    }
  });

  test('resolveCategoryIcon resolves every real income icon_key to a real, non-fallback icon', () {
    for (final key in incomeIconKeys) {
      expect(resolveCategoryIcon(key), isNot(RemixIcon.folderFill), reason: '"$key" should resolve to its own icon, not the generic fallback');
    }
  });

  test('every real expense icon_key maps to an icon distinct from every other expense key\'s', () {
    final seenIcons = <IconData>{};
    for (final key in expenseIconKeys) {
      final icon = resolveCategoryIcon(key);
      expect(seenIcons.add(icon), isTrue, reason: '"$key" resolved to an icon already used by another expense key — icons must be distinct');
    }
  });

  test('every real income icon_key maps to an icon distinct from every other income key\'s', () {
    final seenIcons = <IconData>{};
    for (final key in incomeIconKeys) {
      final icon = resolveCategoryIcon(key);
      expect(seenIcons.add(icon), isTrue, reason: '"$key" resolved to an icon already used by another income key — icons must be distinct');
    }
  });

  test(
    'resolveCategoryIcon resolves a real Remix Icon name that has never appeared in any category yet — '
    'the ticket 09 guarantee: a brand-new backend category needs zero frontend changes, not just "today\'s categories work"',
    () {
      // "anchor-fill" is a real Remix Icon but isn't wired into any curated
      // picker list, fixture, or prior test in this file — standing in for
      // a category the backend might add tomorrow.
      expect(resolveCategoryIcon('anchor-fill'), isNot(RemixIcon.folderFill));
      expect(resolveCategoryIcon('anchor-fill'), RemixIcon.anchorFill);
    },
  );

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

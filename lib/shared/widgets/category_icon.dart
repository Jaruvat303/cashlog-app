import 'package:flutter/material.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../features/categories/domain/category.dart';
import 'remix_icon_codepoints.dart';

/// Curated *picker* data only, for the create/edit category form's icon
/// grid — a deliberately small, friendly-labeled subset of the full Remix
/// Icon set for a user to choose from when making a new category, not an
/// attempt to enumerate every `icon_key` a category can have. [resolveCategoryIcon]
/// below does NOT read from this list (see its own doc comment) — resolving
/// an *existing* category's icon and offering icon *choices* for a brand
/// new one are different problems, and conflating them (one combined
/// "known icon_key -> icon" list serving both) is exactly what caused the
/// fallback-icon bug to ship three times in a row (post-launch UI polish
/// tickets 01, 07, 08): every time the backend's seed data grew, this list
/// didn't, and nothing forced it to.
///
/// Lives in `shared/` (not `features/categories/domain/`) because it's
/// resolved from three features — categories (the picker itself), the
/// transaction feed row, and the dashboard's expense-by-category chart —
/// and CLAUDE.md only allows cross-feature reuse through `core/`/`shared/`.
const List<(String key, String label, IconData icon)> kExpenseCategoryIconChoices = [
  ('question-fill', 'ยังไม่ระบุหมวดหมู่', RemixIcon.questionFill),
  ('restaurant-fill', 'อาหาร', RemixIcon.restaurantFill),
  ('cup-fill', 'ของว่าง/คาเฟ่', RemixIcon.cupFill),
  ('shopping-bag-3-fill', 'ของใช้', RemixIcon.shoppingBag3Fill),
  ('bus-fill', 'ขนส่งสาธารณะ', RemixIcon.busFill),
  ('car-fill', 'น้ำมัน/รถยนต์', RemixIcon.carFill),
  ('home-4-fill', 'ที่พัก', RemixIcon.home4Fill),
  ('flashlight-fill', 'ค่าน้ำไฟ', RemixIcon.flashlightFill),
  ('wifi-fill', 'อินเทอร์เน็ต/โทรศัพท์', RemixIcon.wifiFill),
  ('t-shirt-fill', 'เสื้อผ้า', RemixIcon.tShirtFill),
  ('sparkling-fill', 'ความงาม/ผิวพรรณ', RemixIcon.sparklingFill),
  ('clapperboard-fill', 'บันเทิง', RemixIcon.clapperboardFill),
  ('goblet-fill', 'สังสรรค์', RemixIcon.gobletFill),
  ('plane-fill', 'เดินทาง', RemixIcon.planeFill),
  ('capsule-fill', 'สุขภาพ/ยา', RemixIcon.capsuleFill),
  ('shield-check-fill', 'ประกัน', RemixIcon.shieldCheckFill),
  ('book-open-fill', 'การศึกษา', RemixIcon.bookOpenFill),
  ('computer-fill', 'อิเล็กทรอนิกส์', RemixIcon.computerFill),
  ('footprint-fill', 'สัตว์เลี้ยง', RemixIcon.footprintFill),
  ('heart-3-fill', 'บริจาค', RemixIcon.heart3Fill),
  ('archive-fill', 'อื่นๆ', RemixIcon.archiveFill),
  ('bank-card-fill', 'หนี้บัตรเครดิต', RemixIcon.bankCardFill),
  ('government-fill', 'ภาษี/ราชการ', RemixIcon.governmentFill),
  ('gift-2-fill', 'ของขวัญ', RemixIcon.gift2Fill),
  ('parent-fill', 'เลี้ยงดูครอบครัว', RemixIcon.parentFill),
  ('stock-fill', 'ลงทุน', RemixIcon.stockFill),
  ('ticket-2-fill', 'หวย/พนัน', RemixIcon.ticket2Fill),
  ('parking-box-fill', 'จอดรถ/ทางด่วน', RemixIcon.parkingBoxFill),
  ('hammer-fill', 'ซ่อมแซม', RemixIcon.hammerFill),
  ('bank-fill', 'ธรรมเนียมธนาคาร', RemixIcon.bankFill),
];

/// Curated picker data for income categories — same purpose and caveats as
/// [kExpenseCategoryIconChoices] above.
const List<(String key, String label, IconData icon)> kIncomeCategoryIconChoices = [
  ('wallet-3-fill', 'เงินเดือน', RemixIcon.wallet3Fill),
  ('gift-fill', 'ของขวัญ', RemixIcon.giftFill),
  ('tools-fill', 'รับจ้าง/ฟรีแลนซ์', RemixIcon.toolsFill),
  ('store-2-fill', 'ขายของ', RemixIcon.store2Fill),
  ('line-chart-fill', 'ลงทุน', RemixIcon.lineChartFill),
  ('trophy-fill', 'รางวัล', RemixIcon.trophyFill),
  ('key-2-fill', 'ค่าเช่า', RemixIcon.key2Fill),
  ('hand-heart-fill', 'เงินช่วยเหลือ', RemixIcon.handHeartFill),
  ('coins-fill', 'รายได้เสริม', RemixIcon.coinsFill),
  ('money-dollar-circle-fill', 'รายได้อื่นๆ', RemixIcon.moneyDollarCircleFill),
  ('refund-2-fill', 'เงินคืนภาษี', RemixIcon.refund2Fill),
  ('percent-fill', 'ดอกเบี้ย', RemixIcon.percentFill),
  ('recycle-fill', 'ขายของมือสอง', RemixIcon.recycleFill),
];

/// Type-scoped choices for the create/edit category icon picker — income
/// categories only offer income icons, expense categories only offer
/// expense icons, never a single mixed list.
List<(String key, String label, IconData icon)> categoryIconChoicesFor(CategoryType type) =>
    type == CategoryType.income ? kIncomeCategoryIconChoices : kExpenseCategoryIconChoices;

const List<String> kCategoryColorChoices = [
  '#5EEAD4',
  '#60A5FA',
  '#FBBF24',
  '#FB7185',
  '#CBD5E1',
  '#4F8EF7',
  '#8B5CF6',
  '#22B573',
];

const _fallbackIcon = RemixIcon.folderFill;
const Color fallbackCategoryColor = Color(0xFF9E9E9E);

/// Genuine backend seed-data naming quirks — an `icon_key` that doesn't
/// match any real Remix Icon name at all, but whose intended icon is
/// unambiguous. Deliberately tiny and hand-maintained, unlike the per-
/// category list this ticket (post-launch UI polish 09) removed: this only
/// grows when the backend *misnames* something, never when it simply adds a
/// new category in the same icon set — [kRemixIconCodepoints] already
/// covers that with zero maintenance.
const Map<String, String> _iconKeyAliases = {
  // Backend seed data calls this "sparkles-fill"; no such Remix Icon
  // exists — the real name is "sparkling-fill".
  'sparkles-fill': 'sparkling-fill',
};

/// Resolves a category's `icon_key` straight against the *complete* Remix
/// Icon set (`kRemixIconCodepoints`, mechanically generated from
/// `package:remix_icons_flutter`'s own source — see
/// `tool/generate_remix_icon_codepoints.dart`) instead of a hand-curated
/// subset. This is the root-cause fix for the fallback-icon bug that shipped
/// three times in a row (post-launch UI polish tickets 01, 07, 08): every
/// time, the backend added a category with a valid `icon_key` the old
/// hand-typed list simply hadn't been extended to include yet. A real
/// backend category can now use *any* Remix Icon name and resolve
/// correctly with zero frontend changes.
///
/// Only two things ever fall back to the generic icon now: the backend's
/// own bare `"folder"` default (sent when a category has no `icon_key` at
/// all, confirmed against a live `GET /api/v1/transactions/summary`
/// response for an uncategorized transaction) recognized explicitly, and a
/// truly unrecognized key (not a real Remix Icon name under any alias) —
/// e.g. pre-Remix-migration client-invented keys ("food", "transport", ...)
/// still sitting on old data.
IconData resolveCategoryIcon(String iconKey) {
  if (iconKey.isEmpty || iconKey == 'folder') return _fallbackIcon;
  final resolvedKey = _iconKeyAliases[iconKey] ?? iconKey;
  final codepoint = kRemixIconCodepoints[resolvedKey];
  if (codepoint == null) return _fallbackIcon;
  // A codepoint resolved at runtime, by design (see doc comment above) — not
  // a compile-time constant, so Flutter's release-build icon tree-shaker
  // can't statically enumerate which glyphs are used. The project's release
  // build passes `--no-tree-shake-icons` accordingly (see
  // .github/workflows/ci.yml), shipping the full Remix Icon font instead.
  // ignore: non_const_argument_for_const_parameter
  return IconData(codepoint, fontFamily: _fallbackIcon.fontFamily, fontPackage: _fallbackIcon.fontPackage);
}

/// A `color_hex` that isn't a parseable `#RRGGBB`/`#AARRGGBB` string falls
/// back to a neutral gray rather than throwing.
Color colorFromHex(String colorHex) {
  final hex = colorHex.replaceFirst('#', '');
  final normalized = hex.length == 6 ? 'FF$hex' : hex;
  final value = int.tryParse(normalized, radix: 16);
  return value == null ? fallbackCategoryColor : Color(value);
}

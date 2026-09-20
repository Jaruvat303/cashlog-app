// Post-launch UI polish ticket 09: root-cause fix for the category
// icon-fallback bug that shipped three times in a row (tickets 01, 07, 08).
// Each time, the backend added a new category with a new (but perfectly
// valid) Remix Icon `icon_key`, and the frontend's hand-curated
// icon_key -> IconData list simply didn't know about it yet.
//
// `package:remix_icons_flutter` ships every icon as a `static const
// IconData` field on its `RemixIcon` class — there is no runtime
// string-name -> IconData lookup exported anywhere in that package (checked
// its full source: `remixicon_ids.dart` and `remixicon_list.dart`). But the
// kebab-case name IS present as a doc comment directly above every
// declaration, e.g.:
//
//   /// wallet-3-fill
//   /// ![wallet-3-fill](data:image/svg+xml;base64,...)
//     static const IconData wallet3Fill = IconData(0xEFF7, fontFamily: ..., fontPackage: ...);
//
// This script parses that generated source once and emits a *complete*
// `Map<String, int>` of every kebab-case icon name -> its font codepoint —
// covering the entire Remix Icon set (~3000 icons), not just the categories
// that happen to exist today. `resolveCategoryIcon` builds an `IconData`
// straight from this map at runtime, so a brand-new backend category using
// any real Remix Icon name resolves correctly with zero frontend changes.
//
// Run with: dart run tool/generate_remix_icon_codepoints.dart
// Re-run only if the `remix_icons_flutter` dependency is upgraded to a
// version that adds/renames icons (see its CHANGELOG).
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final packageConfig = jsonDecode(await File('.dart_tool/package_config.json').readAsString()) as Map<String, dynamic>;
  final packages = packageConfig['packages'] as List<dynamic>;
  final remixPackage = packages.cast<Map<String, dynamic>>().firstWhere(
    (p) => p['name'] == 'remix_icons_flutter',
    orElse: () => throw StateError('remix_icons_flutter not found in .dart_tool/package_config.json — run `flutter pub get` first'),
  );
  // `rootUri` has no trailing slash, so resolving a relative reference
  // against it as-is drops its last path segment per RFC 3986 (treating it
  // like resolving from a *file*, not a directory) — add the slash back
  // first.
  var rootUriString = remixPackage['rootUri'] as String;
  if (!rootUriString.endsWith('/')) rootUriString = '$rootUriString/';
  final packageRoot = Uri.parse(rootUriString);
  final sourceFile = File.fromUri(packageRoot.resolve('lib/remixicon_ids.dart'));
  final source = await sourceFile.readAsLines();

  // A name doc comment ("/// wallet-3-fill") is always followed, a line or
  // two later (an optional "/// ![name](data:...)" preview line comes
  // between them), by that icon's non-"Dir" declaration
  // ("static const IconData wallet3Fill = IconData(0xEFF7, ...);"). The
  // "Dir" (RTL-mirrored) sibling right after shares the same codepoint and
  // has no doc comment of its own, so it's already covered by the same name.
  final nameCommentPattern = RegExp(r'^/// ([a-z0-9-]+)$');
  final codepointPattern = RegExp(r'IconData\(0x([0-9A-Fa-f]+),');

  final codepoints = <String, int>{};
  String? pendingName;
  for (final line in source) {
    final nameMatch = nameCommentPattern.firstMatch(line.trim());
    if (nameMatch != null) {
      pendingName = nameMatch.group(1);
      continue;
    }
    if (pendingName == null) continue;
    final codeMatch = codepointPattern.firstMatch(line);
    if (codeMatch == null) continue;
    codepoints[pendingName] = int.parse(codeMatch.group(1)!, radix: 16);
    pendingName = null;
  }

  if (codepoints.length < 2900) {
    throw StateError('Only parsed ${codepoints.length} icon names — expected ~3000+. The package source format may have '
        'changed; check the regexes above against a fresh copy of remixicon_ids.dart before trusting this output.');
  }

  final buffer = StringBuffer()
    ..writeln('// GENERATED FILE — do not hand-edit.')
    ..writeln('// Produced by tool/generate_remix_icon_codepoints.dart from package:remix_icons_flutter')
    ..writeln('// (see that script\'s doc comment for why this exists and when to re-run it).')
    ..writeln()
    ..writeln('/// Every Remix Icon name (kebab-case, exactly as the backend\'s `icon_key` values')
    ..writeln('/// are expected to look) mapped to its font codepoint — the complete set, not a')
    ..writeln('/// hand-picked subset. `resolveCategoryIcon` builds an `IconData` from this at')
    ..writeln('/// runtime instead of requiring a matching `RemixIcon.xxxFill` constant reference')
    ..writeln('/// per category, so a new backend category never needs a frontend code change as')
    ..writeln('/// long as its `icon_key` is a real Remix Icon name.')
    ..writeln('const Map<String, int> kRemixIconCodepoints = {');
  for (final name in codepoints.keys.toList()..sort()) {
    buffer.writeln("  '$name': 0x${codepoints[name]!.toRadixString(16).toUpperCase().padLeft(4, '0')},");
  }
  buffer.writeln('};');

  final outputFile = File('lib/shared/widgets/remix_icon_codepoints.dart');
  await outputFile.writeAsString(buffer.toString());
  stdout.writeln('Wrote ${codepoints.length} icon codepoints to ${outputFile.path}');
}

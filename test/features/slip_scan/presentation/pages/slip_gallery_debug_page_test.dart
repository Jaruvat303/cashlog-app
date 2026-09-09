// Before any pumpWidget/pumpAndSettle, slipGalleryRepositoryProvider is
// overridden with a hand-written fake (same pattern as the other features'
// _Fake*Repository classes) — this is what keeps a real photo_manager
// platform-channel call from ever happening in this test environment (there
// is no real Android gallery to query here).
import 'dart:typed_data';

import 'package:cashlog/features/slip_scan/data/slip_gallery_repository.dart';
import 'package:cashlog/features/slip_scan/domain/gallery_access_level.dart';
import 'package:cashlog/features/slip_scan/domain/slip_candidate.dart';
import 'package:cashlog/features/slip_scan/presentation/pages/slip_gallery_debug_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSlipGalleryRepository implements SlipGalleryRepository {
  GalleryAccessLevel access = GalleryAccessLevel.full;
  List<SlipCandidate> candidates = const [];
  int presentLimitedCalls = 0;
  int openSettingsCalls = 0;

  @override
  Future<GalleryAccessLevel> currentAccess() async => access;

  @override
  Future<GalleryAccessLevel> requestAccess() async => access;

  @override
  Future<void> presentLimitedSelection() async => presentLimitedCalls++;

  @override
  Future<void> openSettings() async => openSettingsCalls++;

  @override
  Future<List<SlipCandidate>> queryConfiguredAlbums() async => candidates;

  @override
  Future<Uint8List?> readBytes(String assetId) async => null;
}

/// pumpAndSettle can't tell "still legitimately loading" from "stuck
/// forever" — a bounded pump loop fails fast instead (same reasoning as
/// test/widget_test.dart's `_pumpBounded`).
Future<void> _pumpBounded(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late _FakeSlipGalleryRepository fakeRepository;

  setUp(() {
    fakeRepository = _FakeSlipGalleryRepository();
  });

  Widget buildApp() => ProviderScope(
    overrides: [slipGalleryRepositoryProvider.overrideWithValue(fakeRepository)],
    child: const MaterialApp(home: SlipGalleryDebugPage()),
  );

  testWidgets('full access groups filenames by configured album and shows the total count', (tester) async {
    fakeRepository.access = GalleryAccessLevel.full;
    fakeRepository.candidates = const [
      SlipCandidate(id: '1', filename: 'scb_001.jpg', sourceAlbum: 'SCB EASY'),
      SlipCandidate(id: '2', filename: 'scb_002.jpg', sourceAlbum: 'SCB EASY'),
      SlipCandidate(id: '3', filename: 'dime_001.jpg', sourceAlbum: 'Dime!'),
    ];

    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);

    expect(find.text('Full access'), findsOneWidget);
    expect(find.text('SCB EASY (2)'), findsOneWidget);
    expect(find.text('Dime! (1)'), findsOneWidget);
    expect(find.text('scb_001.jpg'), findsOneWidget);
    expect(find.text('scb_002.jpg'), findsOneWidget);
    expect(find.text('dime_001.jpg'), findsOneWidget);
    expect(find.text('3 file(s) across 2 configured album(s)'), findsOneWidget);
  });

  testWidgets('an album with no matches still shows its own zero-count section', (tester) async {
    fakeRepository.access = GalleryAccessLevel.full;
    fakeRepository.candidates = const [SlipCandidate(id: '1', filename: 'scb_001.jpg', sourceAlbum: 'SCB EASY')];

    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);

    expect(find.text('SCB EASY (1)'), findsOneWidget);
    expect(find.text('Dime! (0)'), findsOneWidget);
    expect(find.text('No files found in this album'), findsOneWidget);
  });

  testWidgets('denied access shows the denied banner with a grant-access action, no query attempted', (tester) async {
    fakeRepository.access = GalleryAccessLevel.denied;

    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);

    expect(find.text('No access'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Grant access'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Open settings'), findsOneWidget);
  });

  testWidgets('limited access offers "Select more photos" and triggers the picker', (tester) async {
    fakeRepository.access = GalleryAccessLevel.limited;
    fakeRepository.candidates = const [SlipCandidate(id: '1', filename: 'scb_001.jpg', sourceAlbum: 'SCB EASY')];

    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);

    expect(find.text('Limited access — some photos may be missing'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Select more photos'));
    await _pumpBounded(tester);

    expect(fakeRepository.presentLimitedCalls, 1);
  });
}

// T10 Layer 2/3 verification (see conversation) — drives the REAL
// SlipScanPipeline against a REAL Android gallery (photo_manager platform
// channel) and the REAL dev backend (network), which `flutter test` alone
// cannot exercise (CLAUDE.md's testing rule exists precisely because a real
// dio call in a plain test environment misbehaves). Requires:
//   - dummy (or real, for Layer 3) images already pushed via `adb push` into
//     "/sdcard/Pictures/SCB EASY/" and "/sdcard/Pictures/Dime!/", each
//     followed by an `adb shell am broadcast -a
//     android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file://...` so
//     MediaStore (and therefore photo_manager) actually sees them
//   - android.permission.READ_EXTERNAL_STORAGE pre-granted via `adb shell pm
//     grant`, so no system permission dialog blocks the run
//   - run with: flutter test integration_test/slip_upload_pipeline_test.dart
//     -d <device> --dart-define-from-file=env/dev.json
//
// Every finding is printed with a "T10-LAYER2:" prefix so it's easy to grep
// out of the host-side `flutter test` output.
import 'package:cashlog/core/db/app_database.dart';
import 'package:cashlog/core/db/tables/scanned_slips.dart';
import 'package:cashlog/features/slip_scan/data/slip_gallery_repository.dart';
import 'package:cashlog/features/slip_scan/data/slip_upload_repository.dart';
import 'package:cashlog/features/slip_scan/domain/gallery_access_level.dart';
import 'package:cashlog/features/slip_scan/presentation/providers/slip_scan_pipeline_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUpAll(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  test('gallery access is granted and both configured albums are visible', () async {
    final gallery = container.read(slipGalleryRepositoryProvider);
    final access = await gallery.currentAccess();
    // ignore: avoid_print
    print('T10-LAYER2: gallery access = $access');
    expect(access, isNot(GalleryAccessLevel.denied));

    final candidates = await gallery.queryConfiguredAlbums();
    // ignore: avoid_print
    print('T10-LAYER2: found ${candidates.length} candidate(s): ${candidates.map((c) => '${c.sourceAlbum}/${c.filename}').join(', ')}');
    expect(candidates, isNotEmpty, reason: 'no candidates found — did the adb push + MEDIA_SCANNER_SCAN_FILE broadcast actually land?');
  });

  test(
    'scan pass: uploads/attempts every new pushed file, sequential ~7s apart, no 429',
    () async {
      container.listen(slipScanPipelineProvider, (prev, next) {});
      final notifier = container.read(slipScanPipelineProvider.notifier);

      final started = DateTime.now();
      await notifier.runScan(); // production default: kSlipUploadDelay (7s)
      final elapsed = DateTime.now().difference(started);

      final progress = container.read(slipScanPipelineProvider);
      // ignore: avoid_print
      print('T10-LAYER2: pass total=${progress.total} completed=${progress.completed} elapsed=${elapsed.inSeconds}s');
      for (final r in progress.results) {
        // ignore: avoid_print
        print('T10-LAYER2:   ${r.filename} -> ${r.status}${r.failureMessage != null ? ' (${r.failureMessage})' : ''}');
      }

      if (progress.total > 1) {
        // Sequential-pacing floor: (n-1) * 7s, even before any per-request
        // network/Gemini time is added on top.
        expect(elapsed.inSeconds, greaterThanOrEqualTo((progress.total - 1) * 7));
      }

      final db = container.read(appDatabaseProvider);
      final rows = await db.select(db.scannedSlips).get();
      // ignore: avoid_print
      print('T10-LAYER2: scanned_slips rows: ${rows.length}');
      for (final row in rows) {
        // ignore: avoid_print
        print(
          'T10-LAYER2:   ${row.localImageName} status=${row.status} lastErrorCode=${row.lastErrorCode} serverTransactionId=${row.serverTransactionId}',
        );
      }

      // The client-side signal that the sequential ~7s pacing failed to keep
      // us under the backend's 10 req/60s /upload-slip limit: a 429
      // response. dio_client.dart's interceptor doesn't recognize a 429
      // body's shape (no error_code field) so it always lands as an
      // UnknownFailure — detect it by the rate limiter's own literal
      // response text instead.
      final rateLimited = progress.results.where((r) => (r.failureMessage ?? '').contains('Too many requests'));
      expect(rateLimited, isEmpty, reason: 'a 429 slipped through for: ${rateLimited.map((r) => r.filename).join(', ')}');
    },
    // 12 files * 7s sequential delay alone is 77s, plus per-request/Gemini
    // latency on top — well past flutter_test's default 30s test timeout.
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test('second pass: files already uploaded/duplicate are excluded by the local diff', () async {
    final gallery = container.read(slipGalleryRepositoryProvider);
    final uploadRepo = container.read(slipUploadRepositoryProvider);
    final candidates = await gallery.queryConfiguredAlbums();

    final stillNew = await uploadRepo.diffNewFiles(candidates);
    // ignore: avoid_print
    print('T10-LAYER2: diff after pass 1 -> ${stillNew.length} still-new file(s): ${stillNew.map((c) => c.filename).join(', ')}');

    final db = container.read(appDatabaseProvider);
    final resolvedRows = await (db.select(
      db.scannedSlips,
    )..where((s) => s.status.isInValues(const [SlipStatus.uploaded, SlipStatus.duplicate]))).get();
    final resolvedNames = resolvedRows.map((r) => r.localImageName).toSet();
    // ignore: avoid_print
    print('T10-LAYER2: ${resolvedNames.length} file(s) resolved (uploaded/duplicate) from pass 1: ${resolvedNames.join(', ')}');

    // The actual "re-scanning doesn't re-upload" guarantee: every filename
    // that resolved to uploaded/duplicate must be absent from this diff.
    final stillNewNames = stillNew.map((c) => c.filename).toSet();
    expect(stillNewNames.intersection(resolvedNames), isEmpty);

    // A 'failed' file is, BY DESIGN, not expected to be excluded here — it's
    // eligible for retry on the next scan cycle (spec's Gemini-quota rule
    // requires this for that specific error, and the pipeline applies it to
    // every 'failed' status uniformly). Reported, not asserted on: whether a
    // non-slip dummy image lands as 'uploaded' (junk, amount 0) or 'failed'
    // (parse error) is a real backend behavior this test observes rather
    // than dictates.
    final failedRows = await (db.select(db.scannedSlips)..where((s) => s.status.equalsValue(SlipStatus.failed))).get();
    // ignore: avoid_print
    print(
      'T10-LAYER2: ${failedRows.length} file(s) landed as failed after pass 1 (expected to be retried on pass 2 by design, not skipped): ${failedRows.map((r) => r.localImageName).join(', ')}',
    );
  });
}

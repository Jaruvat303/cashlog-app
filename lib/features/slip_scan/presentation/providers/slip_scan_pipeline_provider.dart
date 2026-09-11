import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/cache/cache_invalidator.dart';
import '../../data/slip_gallery_repository.dart';
import '../../data/slip_upload_repository.dart';
import '../../domain/gallery_access_level.dart';
import '../../domain/slip_upload_outcome.dart';

part 'slip_scan_pipeline_provider.g.dart';

/// spec §7.6.1: sequential uploads, ~7s apart — safer than the backend's
/// 10 req/60s `/upload-slip` limit even with request round-trip time added
/// on top. Exposed as a default parameter (not a bare constant used
/// directly in [SlipScanPipeline.runScan]) so tests can pass
/// `Duration.zero` and exercise the loop instantly.
const kSlipUploadDelay = Duration(seconds: 7);

enum SlipUploadStatus { uploaded, duplicate, failed }

class SlipFileResult {
  const SlipFileResult({required this.filename, required this.status, this.failureMessage});

  final String filename;
  final SlipUploadStatus status;
  final String? failureMessage;
}

/// T10 is manual-trigger only — no `AppLifecycleState` wiring (that's T11).
/// `build()`'s idle state never queries the gallery on its own; only
/// [runScan] does.
class SlipScanProgress {
  const SlipScanProgress({
    required this.isScanning,
    required this.total,
    required this.completed,
    required this.currentFilename,
    required this.results,
    required this.accessLevel,
  });

  static const idle = SlipScanProgress(
    isScanning: false,
    total: 0,
    completed: 0,
    currentFilename: null,
    results: [],
    accessLevel: null,
  );

  final bool isScanning;
  final int total;
  final int completed;
  final String? currentFilename;
  final List<SlipFileResult> results;

  /// `null` until a scan has run at least once; distinguishes "haven't
  /// checked yet" from a confirmed [GalleryAccessLevel.denied].
  final GalleryAccessLevel? accessLevel;
}

@riverpod
class SlipScanPipeline extends _$SlipScanPipeline {
  @override
  SlipScanProgress build() => SlipScanProgress.idle;

  /// Diff → sequential compress+upload+record, one file at a time.
  /// [delay] defaults to [kSlipUploadDelay]; tests override it to
  /// [Duration.zero] so the loop's branching logic can be exercised without
  /// a multi-second real-time wait per file.
  Future<void> runScan({Duration delay = kSlipUploadDelay}) async {
    if (state.isScanning) return;
    // Claims the "scanning" state synchronously, before the first `await`
    // below — otherwise two rapid calls (e.g. a double-tap on the trigger
    // button) both pass the guard above, since `state.isScanning` wouldn't
    // flip to true until after the first `await` yields control back to the
    // caller. `total`/`accessLevel` are still unknown at this point, so this
    // is a provisional state the loop below immediately supersedes.
    state = SlipScanProgress(
      isScanning: true,
      total: 0,
      completed: 0,
      currentFilename: null,
      results: const [],
      accessLevel: state.accessLevel,
    );

    final galleryRepo = ref.read(slipGalleryRepositoryProvider);
    final uploadRepo = ref.read(slipUploadRepositoryProvider);

    final access = await galleryRepo.currentAccess();
    if (access == GalleryAccessLevel.denied) {
      if (ref.mounted) {
        state = SlipScanProgress(
          isScanning: false,
          total: 0,
          completed: 0,
          currentFilename: null,
          results: const [],
          accessLevel: access,
        );
      }
      return;
    }

    final candidates = await galleryRepo.queryConfiguredAlbums();
    final newFiles = await uploadRepo.diffNewFiles(candidates);

    if (!ref.mounted) return;
    state = SlipScanProgress(
      isScanning: true,
      total: newFiles.length,
      completed: 0,
      currentFilename: null,
      results: const [],
      accessLevel: access,
    );

    final results = <SlipFileResult>[];
    // T14: accumulated across the whole batch, not invalidated per-file —
    // a single `invalidateMonths` call after the loop covers a 30-day
    // backfill spanning multiple months in one shot.
    final affectedMonths = <(int, int)>{};
    for (var i = 0; i < newFiles.length; i++) {
      if (i > 0) await Future<void>.delayed(delay);
      final candidate = newFiles[i];

      if (ref.mounted) {
        state = SlipScanProgress(
          isScanning: true,
          total: newFiles.length,
          completed: i,
          currentFilename: candidate.filename,
          results: List.unmodifiable(results),
          accessLevel: access,
        );
      }

      final outcome = await uploadRepo.uploadOne(candidate);
      results.add(
        outcome.fold(
          (failure) => SlipFileResult(filename: candidate.filename, status: SlipUploadStatus.failed, failureMessage: failure.message),
          (outcome) {
            if (outcome is SlipUploaded) {
              final date = outcome.transaction.transactionDate;
              affectedMonths.add((date.year, date.month));
            }
            return SlipFileResult(
              filename: candidate.filename,
              status: outcome is SlipUploaded ? SlipUploadStatus.uploaded : SlipUploadStatus.duplicate,
            );
          },
        ),
      );

      if (ref.mounted) {
        state = SlipScanProgress(
          isScanning: true,
          total: newFiles.length,
          completed: i + 1,
          currentFilename: candidate.filename,
          results: List.unmodifiable(results),
          accessLevel: access,
        );
      }
    }

    if (affectedMonths.isNotEmpty && ref.mounted) {
      ref.read(cacheInvalidatorProvider).invalidateMonths(affectedMonths);
    }

    if (ref.mounted) {
      state = SlipScanProgress(
        isScanning: false,
        total: newFiles.length,
        completed: newFiles.length,
        currentFilename: null,
        results: List.unmodifiable(results),
        accessLevel: access,
      );
    }
  }
}

import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/cache/cache_invalidator.dart';
import '../../../../core/network/failure.dart';
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
    this.isManualUploading = false,
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

  /// T21: true only for the manual-attach entry point's own in-flight
  /// request — deliberately separate from [isScanning] (an auto-scan
  /// batch), since the two are serialized against each other (see
  /// [SlipScanPipeline._withExclusiveAccess]) but represent different user
  /// actions and shouldn't be conflated in the UI.
  final bool isManualUploading;
}

@riverpod
class SlipScanPipeline extends _$SlipScanPipeline {
  @override
  SlipScanProgress build() => SlipScanProgress.idle;

  /// T21: the mutual-exclusion point between the two slip-intake channels
  /// (auto-scan's [runScan] batch and manual attach's [uploadManual]) —
  /// CLAUDE.md's "slip uploads must be sequential, never fire uploads
  /// concurrently" rate-limit rule applies across both combined, not just
  /// within one channel's own loop. A promise-chain mutex rather than a bare
  /// `bool` flag: whichever call arrives second simply awaits the first
  /// call's own future before running, instead of bailing out (T10's
  /// `isScanning` re-entrancy guard bails; this one queues, per T21's DoD —
  /// "wait for that batch to finish... then proceed automatically, no need
  /// for the user to re-tap").
  Future<void> _exclusiveAccess = Future<void>.value();

  Future<T> _withExclusiveAccess<T>(Future<T> Function() operation) async {
    final previous = _exclusiveAccess;
    final completer = Completer<void>();
    _exclusiveAccess = completer.future;
    await previous;
    try {
      return await operation();
    } finally {
      completer.complete();
    }
  }

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
      isManualUploading: state.isManualUploading,
    );

    // Waits here (not before the claim above) if a manual attach is
    // currently mid-upload — the claim still needs to happen synchronously
    // so a second overlapping runScan call keeps bailing out immediately,
    // same as before T21.
    await _withExclusiveAccess(() => _runScanBody(delay));
  }

  Future<void> _runScanBody(Duration delay) async {
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
          isManualUploading: state.isManualUploading,
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
      isManualUploading: state.isManualUploading,
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
          isManualUploading: state.isManualUploading,
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
          isManualUploading: state.isManualUploading,
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
        isManualUploading: state.isManualUploading,
      );
    }
  }

  /// T21's manual-attach entry point: a single deliberate user-picked/
  /// captured file, serialized against any in-progress auto-scan batch via
  /// the same [_withExclusiveAccess] lock [runScan] uses — never a second
  /// concurrent `/upload-slip` call regardless of which channel started
  /// first. Only one manual upload is supported in flight at a time (T21's
  /// DoD explicitly excludes a multi-item manual queue); a second call while
  /// one is already running is rejected outright rather than queued, unlike
  /// the auto-scan/manual queuing above — the UI is expected to disable the
  /// attach button while [SlipScanProgress.isManualUploading] is true, so
  /// this is a defensive guard, not the primary mechanism.
  Future<Either<Failure, SlipUploadOutcome>> uploadManual({required Uint8List bytes, required String filename}) async {
    if (state.isManualUploading) {
      return const Left(UnknownFailure(message: 'A manual slip upload is already in progress.'));
    }
    state = SlipScanProgress(
      isScanning: state.isScanning,
      total: state.total,
      completed: state.completed,
      currentFilename: state.currentFilename,
      results: state.results,
      accessLevel: state.accessLevel,
      isManualUploading: true,
    );

    final result = await _withExclusiveAccess(() {
      final uploadRepo = ref.read(slipUploadRepositoryProvider);
      return uploadRepo.uploadManual(bytes: bytes, filename: filename);
    });

    if (ref.mounted) {
      result.fold((_) {}, (outcome) {
        if (outcome is SlipUploaded) {
          final date = outcome.transaction.transactionDate;
          ref.read(cacheInvalidatorProvider).invalidateMonths({(date.year, date.month)});
        }
      });
      state = SlipScanProgress(
        isScanning: state.isScanning,
        total: state.total,
        completed: state.completed,
        currentFilename: state.currentFilename,
        results: state.results,
        accessLevel: state.accessLevel,
        isManualUploading: false,
      );
    }

    return result;
  }
}

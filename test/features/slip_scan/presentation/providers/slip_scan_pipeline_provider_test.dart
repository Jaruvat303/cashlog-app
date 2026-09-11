// Riverpod ProviderContainer test (no widget tree needed) — both
// slipGalleryRepositoryProvider and slipUploadRepositoryProvider are
// overridden with hand-written fakes so this never touches photo_manager's
// platform channel or a real network call (CLAUDE.md's testing rule).
// delay: Duration.zero is passed to runScan so the ~7s real-world pacing
// (spec §7.6.1) doesn't make this test slow — the pacing itself isn't what
// this test is verifying, the sequencing/outcome-bucketing logic is.
import 'dart:typed_data';

import 'package:cashlog/core/cache/cache_invalidator.dart';
import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/slip_scan/data/slip_gallery_repository.dart';
import 'package:cashlog/features/slip_scan/data/slip_upload_repository.dart';
import 'package:cashlog/features/slip_scan/domain/gallery_access_level.dart';
import 'package:cashlog/features/slip_scan/domain/slip_candidate.dart';
import 'package:cashlog/features/slip_scan/domain/slip_upload_outcome.dart';
import 'package:cashlog/features/slip_scan/presentation/providers/slip_scan_pipeline_provider.dart';
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSlipGalleryRepository implements SlipGalleryRepository {
  GalleryAccessLevel access = GalleryAccessLevel.full;
  List<SlipCandidate> candidates = const [];
  int queryCalls = 0;

  @override
  Future<GalleryAccessLevel> currentAccess() async => access;
  @override
  Future<List<SlipCandidate>> queryConfiguredAlbums() async {
    queryCalls++;
    return candidates;
  }

  @override
  Future<GalleryAccessLevel> requestAccess() => throw UnimplementedError();
  @override
  Future<void> presentLimitedSelection() => throw UnimplementedError();
  @override
  Future<void> openSettings() => throw UnimplementedError();
  @override
  Future<Uint8List?> readBytes(String assetId) => throw UnimplementedError();
}

class _FakeSlipUploadRepository implements SlipUploadRepository {
  List<SlipCandidate> newFiles = const [];
  final List<String> uploadedInOrder = [];
  final List<DateTime> uploadedAt = [];

  /// Per-filename scripted result — defaults to a successful upload if a
  /// filename has no entry.
  Map<String, Either<Failure, SlipUploadOutcome>> resultByFilename = {};

  @override
  Future<List<SlipCandidate>> diffNewFiles(List<SlipCandidate> candidates) async => newFiles;

  @override
  Future<Either<Failure, SlipUploadOutcome>> uploadOne(SlipCandidate candidate) async {
    uploadedInOrder.add(candidate.filename);
    uploadedAt.add(DateTime.now());
    return resultByFilename[candidate.filename] ??
        Right(
          SlipUploaded(
            Transaction(
              id: uploadedInOrder.length,
              amount: 100,
              type: TransactionType.expense,
              source: 'slip',
              transactionDate: DateTime.utc(2026, 9, 1),
            ),
          ),
        );
  }
}

/// T14: records exactly which month-sets this pipeline's batch asked to
/// invalidate — the underlying invalidation mechanics against the real
/// `monthTransactionsProvider`/`dashboardSummaryProvider` families are
/// covered by test/core/cache/cache_invalidator_test.dart.
class _RecordingCacheInvalidator implements CacheInvalidator {
  final List<Set<(int, int)>> invalidateMonthsCalls = [];

  @override
  void invalidateMonth(int year, int month) => invalidateMonthsCalls.add({(year, month)});

  @override
  void invalidateMonths(Set<(int, int)> months) => invalidateMonthsCalls.add(months);
}

void main() {
  late _FakeSlipGalleryRepository galleryRepository;
  late _FakeSlipUploadRepository uploadRepository;
  late _RecordingCacheInvalidator cacheInvalidator;
  late ProviderContainer container;

  setUp(() {
    galleryRepository = _FakeSlipGalleryRepository();
    uploadRepository = _FakeSlipUploadRepository();
    cacheInvalidator = _RecordingCacheInvalidator();
    container = ProviderContainer(
      overrides: [
        slipGalleryRepositoryProvider.overrideWithValue(galleryRepository),
        slipUploadRepositoryProvider.overrideWithValue(uploadRepository),
        cacheInvalidatorProvider.overrideWithValue(cacheInvalidator),
      ],
    );
    addTearDown(container.dispose);
    // slipScanPipelineProvider is autoDispose (no widget tree here to watch
    // it) — without a listener it can be torn down and silently rebuilt back
    // to SlipScanProgress.idle between `runScan`'s awaits (the notifier's own
    // `ref.mounted` guards exist for exactly this case), so a real listener
    // is required to observe the in-progress/final state this test asserts
    // on.
    container.listen(slipScanPipelineProvider, (prev, next) {});
  });

  const candidateA = SlipCandidate(id: '1', filename: 'a.jpg', sourceAlbum: 'SCB EASY');
  const candidateB = SlipCandidate(id: '2', filename: 'b.jpg', sourceAlbum: 'SCB EASY');
  const candidateC = SlipCandidate(id: '3', filename: 'c.jpg', sourceAlbum: 'Dime!');

  test('the production default delay is spec §7.6.1\'s ~7s, not just whatever a caller happens to pass', () {
    expect(kSlipUploadDelay, const Duration(seconds: 7));
  });

  test('denied access short-circuits before querying albums, leaves results empty', () async {
    galleryRepository.access = GalleryAccessLevel.denied;

    await container.read(slipScanPipelineProvider.notifier).runScan(delay: Duration.zero);

    final state = container.read(slipScanPipelineProvider);
    expect(state.isScanning, isFalse);
    expect(state.accessLevel, GalleryAccessLevel.denied);
    expect(state.results, isEmpty);
    expect(galleryRepository.queryCalls, 0);
  });

  test('uploads new files sequentially and buckets uploaded/duplicate/failed outcomes', () async {
    galleryRepository.access = GalleryAccessLevel.full;
    galleryRepository.candidates = [candidateA, candidateB, candidateC];
    uploadRepository.newFiles = [candidateA, candidateB, candidateC];
    uploadRepository.resultByFilename = {
      'b.jpg': const Right(SlipDuplicate()),
      'c.jpg': const Left(SlipParseFailedFailure(message: 'could not read slip')),
    };

    await container.read(slipScanPipelineProvider.notifier).runScan(delay: Duration.zero);

    final state = container.read(slipScanPipelineProvider);
    expect(state.isScanning, isFalse);
    expect(state.total, 3);
    expect(state.completed, 3);
    expect(uploadRepository.uploadedInOrder, ['a.jpg', 'b.jpg', 'c.jpg']);

    final byFilename = {for (final r in state.results) r.filename: r};
    expect(byFilename['a.jpg']!.status, SlipUploadStatus.uploaded);
    expect(byFilename['b.jpg']!.status, SlipUploadStatus.duplicate);
    expect(byFilename['c.jpg']!.status, SlipUploadStatus.failed);
    expect(byFilename['c.jpg']!.failureMessage, 'could not read slip');

    // T14: only 'a.jpg' actually uploaded (the default fake result, dated
    // 2026-09-01) — the duplicate and the failed file contribute nothing.
    expect(cacheInvalidator.invalidateMonthsCalls, [
      {(2026, 9)},
    ]);
  });

  group('T14 cache invalidation', () {
    test('a batch spanning multiple months invalidates every uploaded month exactly once, after the whole batch', () async {
      galleryRepository.access = GalleryAccessLevel.full;
      galleryRepository.candidates = [candidateA, candidateB, candidateC];
      uploadRepository.newFiles = [candidateA, candidateB, candidateC];
      uploadRepository.resultByFilename = {
        'a.jpg': Right(
          SlipUploaded(
            Transaction(id: 1, amount: 100, type: TransactionType.expense, source: 'slip', transactionDate: DateTime.utc(2026, 8, 31)),
          ),
        ),
        'b.jpg': const Right(SlipDuplicate()),
        'c.jpg': Right(
          SlipUploaded(
            Transaction(id: 2, amount: 100, type: TransactionType.expense, source: 'slip', transactionDate: DateTime.utc(2026, 9, 1)),
          ),
        ),
      };

      await container.read(slipScanPipelineProvider.notifier).runScan(delay: Duration.zero);

      // Exactly one call, covering both months from the whole batch — not
      // one call per file.
      expect(cacheInvalidator.invalidateMonthsCalls, [
        {(2026, 8), (2026, 9)},
      ]);
    });

    test('a batch with no successful uploads (only duplicates/failures) never invalidates anything', () async {
      galleryRepository.access = GalleryAccessLevel.full;
      galleryRepository.candidates = [candidateB, candidateC];
      uploadRepository.newFiles = [candidateB, candidateC];
      uploadRepository.resultByFilename = {
        'b.jpg': const Right(SlipDuplicate()),
        'c.jpg': const Left(SlipParseFailedFailure(message: 'could not read slip')),
      };

      await container.read(slipScanPipelineProvider.notifier).runScan(delay: Duration.zero);

      expect(cacheInvalidator.invalidateMonthsCalls, isEmpty);
    });
  });

  test('runScan spaces uploads apart by the given delay, but never delays before the first one', () async {
    galleryRepository.access = GalleryAccessLevel.full;
    galleryRepository.candidates = [candidateA, candidateB, candidateC];
    uploadRepository.newFiles = [candidateA, candidateB, candidateC];
    const testDelay = Duration(milliseconds: 150);

    final started = DateTime.now();
    await container.read(slipScanPipelineProvider.notifier).runScan(delay: testDelay);
    final totalElapsed = DateTime.now().difference(started);

    expect(uploadRepository.uploadedAt, hasLength(3));
    // 3 uploads, delay applied between them only (not before the first) —
    // spec §7.6.1's "sequential + ~7s apart" pacing, exercised here at a
    // test-sized delay instead of the real 7s so this stays fast.
    expect(totalElapsed, greaterThanOrEqualTo(testDelay * 2));
    final gapBeforeSecond = uploadRepository.uploadedAt[1].difference(uploadRepository.uploadedAt[0]);
    final gapBeforeThird = uploadRepository.uploadedAt[2].difference(uploadRepository.uploadedAt[1]);
    expect(gapBeforeSecond, greaterThanOrEqualTo(testDelay));
    expect(gapBeforeThird, greaterThanOrEqualTo(testDelay));
  });

  test('a concurrent runScan call while already scanning is a no-op', () async {
    galleryRepository.access = GalleryAccessLevel.full;
    galleryRepository.candidates = [candidateA];
    uploadRepository.newFiles = [candidateA];

    final notifier = container.read(slipScanPipelineProvider.notifier);
    final first = notifier.runScan(delay: Duration.zero);
    final second = notifier.runScan(delay: Duration.zero);
    await Future.wait([first, second]);

    expect(uploadRepository.uploadedInOrder, ['a.jpg']);
  });
}

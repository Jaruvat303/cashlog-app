import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart' show FormData, MultipartFile;
import 'package:drift/drift.dart' show Value;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/tables/scanned_slips.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import '../../transactions/data/transaction_mapper.dart';
import '../../transactions/domain/transaction.dart';
import '../domain/slip_candidate.dart';
import '../domain/slip_upload_outcome.dart';
import 'slip_gallery_repository.dart';

part 'slip_upload_repository.g.dart';

/// `POST /api/v1/transactions/upload-slip` + `scanned_slips`/
/// `cached_transactions` bookkeeping, one file at a time (spec §7.6.1's
/// sequential+delay pacing lives in `SlipScanPipeline`, not here — this
/// repository has no opinion on timing, only on one file's outcome).
///
/// error_code values below are confirmed against cashlog-api's
/// `error_handler.go`/`transaction_usecase.go` directly (T10), not guessed
/// from CLAUDE.md/spec §4 — see `core/network/failure.dart`'s doc comment
/// for the full mismatch this uncovered.
class SlipUploadRepository {
  SlipUploadRepository(this._apiClient, this._db, this._galleryRepository);

  final ApiClient _apiClient;
  final AppDatabase _db;
  final SlipGalleryRepository _galleryRepository;

  /// Excludes files already permanently resolved (`uploaded`/`duplicate`/
  /// `failed`/`junk`). `quotaExceeded` is the one exception (T15): a slip
  /// that hit `GEMINI_QUOTA_EXHAUSTED` gets retried on the *next* scan cycle
  /// indefinitely, since the quota exhaustion says nothing about whether
  /// that particular slip is actually unparseable. Every other `failed` row
  /// is a real permanent failure (matches spec §4's "surface to user, no
  /// auto-retry") and must not be re-attempted automatically. `junk` never
  /// appears here since T10 never writes that status (T12's job).
  Future<List<SlipCandidate>> diffNewFiles(List<SlipCandidate> candidates) async {
    final resolvedNames = await (_db.select(_db.scannedSlips)
          ..where((s) => s.status.isInValues(const [SlipStatus.uploaded, SlipStatus.duplicate, SlipStatus.failed, SlipStatus.junk])))
        .map((row) => row.localImageName)
        .get();
    final resolved = resolvedNames.toSet();
    return candidates.where((c) => !resolved.contains(c.filename)).toList();
  }

  /// One file, one request. Never throws — every branch (network failure,
  /// deleted source file, uploaded, duplicate) both returns an `Either` and
  /// records the attempt in `scanned_slips` before returning, so a caller
  /// that never inspects the result still gets a durable record of what was
  /// attempted.
  Future<Either<Failure, SlipUploadOutcome>> uploadOne(SlipCandidate candidate) async {
    final priorRow = await (_db.select(
      _db.scannedSlips,
    )..where((s) => s.localImageName.equals(candidate.filename))).getSingleOrNull();
    final retryCount = priorRow == null ? 0 : priorRow.retryCount + 1;

    final rawBytes = await _galleryRepository.readBytes(candidate.id);
    if (rawBytes == null) {
      const failure = UnknownFailure(message: 'Source image is no longer available in the gallery.');
      await _recordFailure(candidate, retryCount, failure);
      return const Left(failure);
    }

    final compressed = await _compress(rawBytes);
    final result = await _apiClient.post<SlipUploadOutcome>(
      '/api/v1/transactions/upload-slip',
      data: FormData.fromMap({
        'local_image_name': candidate.filename,
        'image': MultipartFile.fromBytes(compressed, filename: candidate.filename),
      }),
      parse: _parseUploadOutcome,
    );

    return result.fold(
      (failure) async {
        // The rarer of the two duplicate paths (§ doc comment on
        // SlipUploadOutcome) surfaces as a 409 Left, not a 200 Right — fold
        // it into the same outcome the caller sees either way.
        if (failure is DuplicateRequestFailure) {
          await _recordDuplicate(candidate, retryCount);
          return const Right(SlipDuplicate());
        }
        if (failure is GeminiQuotaExhaustedFailure) {
          await _recordQuotaExceeded(candidate, retryCount, failure);
          return Left(failure);
        }
        await _recordFailure(candidate, retryCount, failure);
        return Left(failure);
      },
      (outcome) async {
        if (outcome is SlipUploaded) {
          await _recordUploaded(candidate, retryCount, outcome.transaction);
        } else {
          await _recordDuplicate(candidate, retryCount);
        }
        return Right(outcome);
      },
    );
  }

  /// `data` is the 201 body's `data` key (a transaction) when present, or
  /// entirely absent (`null`) on the 200 "skipped or duplicate caught
  /// early" path — `response.OkMessage`'s `omitempty` means the key never
  /// appears at all in that case, not just `null`-valued, but decoding
  /// either way lands on `map['data'] == null` here.
  SlipUploadOutcome _parseUploadOutcome(dynamic data) {
    final map = data as Map<String, dynamic>;
    final txJson = map['data'] as Map<String, dynamic>?;
    return txJson == null ? const SlipDuplicate() : SlipUploaded(transactionFromJson(txJson));
  }

  /// Single-pass compress targeting well under the backend's 4MB
  /// `BodyLimit` (CLAUDE.md) — one lower-quality retry only if the first
  /// pass still lands above ~3.5MB. Bounded, not an iterative loop: bank
  /// slip screenshots are small enough in practice that a second pass
  /// should never be needed.
  Future<Uint8List> _compress(Uint8List bytes) async {
    var compressed = await FlutterImageCompress.compressWithList(bytes, quality: 80, minWidth: 1600, minHeight: 1600);
    if (compressed.lengthInBytes > 3.5 * 1024 * 1024) {
      compressed = await FlutterImageCompress.compressWithList(bytes, quality: 50, minWidth: 1280, minHeight: 1280);
    }
    return compressed;
  }

  Future<void> _recordUploaded(SlipCandidate candidate, int retryCount, Transaction transaction) => _db.transaction(() async {
    await _db.into(_db.scannedSlips).insertOnConflictUpdate(
      ScannedSlipsCompanion.insert(
        localImageName: candidate.filename,
        sourceFolder: candidate.sourceAlbum,
        status: SlipStatus.uploaded,
        serverTransactionId: Value(transaction.id),
        retryCount: Value(retryCount),
        scannedAt: DateTime.now(),
      ),
    );
    await _db.into(_db.cachedTransactions).insertOnConflictUpdate(transactionToCompanion(transaction));
  });

  Future<void> _recordDuplicate(SlipCandidate candidate, int retryCount) =>
      _db.into(_db.scannedSlips).insertOnConflictUpdate(
        ScannedSlipsCompanion.insert(
          localImageName: candidate.filename,
          sourceFolder: candidate.sourceAlbum,
          status: SlipStatus.duplicate,
          retryCount: Value(retryCount),
          scannedAt: DateTime.now(),
        ),
      );

  Future<void> _recordFailure(SlipCandidate candidate, int retryCount, Failure failure) =>
      _db.into(_db.scannedSlips).insertOnConflictUpdate(
        ScannedSlipsCompanion.insert(
          localImageName: candidate.filename,
          sourceFolder: candidate.sourceAlbum,
          status: SlipStatus.failed,
          retryCount: Value(retryCount),
          lastErrorCode: Value(_failureLabel(failure)),
          scannedAt: DateTime.now(),
        ),
      );

  /// `GEMINI_QUOTA_EXHAUSTED` special case (CLAUDE.md's retry policy, T15):
  /// distinct from [_recordFailure]'s `failed` status so [diffNewFiles]
  /// keeps offering this file up on the next scan cycle instead of
  /// permanently excluding it. `retryCount` still increments per attempt,
  /// same as any other status — there's no retry cap here by design (spec:
  /// retried indefinitely until it either succeeds or fails for a different,
  /// non-quota reason).
  Future<void> _recordQuotaExceeded(SlipCandidate candidate, int retryCount, Failure failure) =>
      _db.into(_db.scannedSlips).insertOnConflictUpdate(
        ScannedSlipsCompanion.insert(
          localImageName: candidate.filename,
          sourceFolder: candidate.sourceAlbum,
          status: SlipStatus.quotaExceeded,
          retryCount: Value(retryCount),
          lastErrorCode: Value(_failureLabel(failure)),
          scannedAt: DateTime.now(),
        ),
      );

  /// A short, stable label for `scanned_slips.last_error_code` — a
  /// debugging aid only, never shown to the user. Matches on the sealed
  /// [Failure] type itself (exhaustive — the analyzer flags this switch if
  /// a new subtype is ever added) rather than relying on
  /// [UnknownFailure.code] alone, since transport-level failures like
  /// [NoConnectionFailure] never carry a backend error_code at all.
  String _failureLabel(Failure failure) => switch (failure) {
    TimeoutFailure() => 'TIMEOUT',
    GeminiUnavailableFailure() => 'GEMINI_SERVICE_ERROR',
    InternalDbFailure() => 'INTERNAL_ERROR',
    ContextCanceledFailure() => 'REQUEST_CANCELED',
    NoConnectionFailure() => 'NO_CONNECTION',
    NotFoundFailure() => 'NOT_FOUND',
    DuplicateRequestFailure() => 'DUPLICATE_RESOURCE',
    InvalidInputFailure() => 'INVALID_INPUT',
    SlipParseFailedFailure() => 'SLIP_PARSE_FAILED',
    AccountInactiveFailure() => 'ACCOUNT_INACTIVE',
    TransferSameAccountFailure() => 'TRANSFER_SAME_ACCOUNT',
    CategoryNotAllowedForTransferFailure() => 'CATEGORY_NOT_ALLOWED_FOR_TRANSFER',
    GeminiQuotaExhaustedFailure() => 'GEMINI_QUOTA_EXHAUSTED',
    UnknownFailure(code: final code) => code ?? 'UNKNOWN',
  };
}

@riverpod
SlipUploadRepository slipUploadRepository(Ref ref) =>
    SlipUploadRepository(ref.watch(apiClientProvider), ref.watch(appDatabaseProvider), ref.watch(slipGalleryRepositoryProvider));

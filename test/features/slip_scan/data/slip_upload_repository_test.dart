// Same fake-HttpClientAdapter + in-memory drift pattern as
// transactions_repository_test.dart. flutter_image_compress goes through a
// platform channel that doesn't exist in a plain `flutter test` run, so
// FlutterImageCompressPlatform.instance is swapped for a no-op fake that
// just echoes the input bytes back — this test is about upload-outcome
// handling and scanned_slips/cached_transactions bookkeeping, not real
// compression (there's no meaningful compression ratio to assert on a
// synthetic byte array anyway).
import 'dart:convert';
import 'dart:typed_data';

import 'package:cashlog/core/db/app_database.dart';
import 'package:cashlog/core/db/tables/scanned_slips.dart';
import 'package:cashlog/core/network/api_client.dart';
import 'package:cashlog/core/network/dio_client.dart';
import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/slip_scan/data/slip_gallery_repository.dart';
import 'package:cashlog/features/slip_scan/data/slip_upload_repository.dart';
import 'package:cashlog/features/slip_scan/domain/gallery_access_level.dart';
import 'package:cashlog/features/slip_scan/domain/slip_candidate.dart';
import 'package:cashlog/features/slip_scan/domain/slip_upload_outcome.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_image_compress_platform_interface/flutter_image_compress_platform_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _CompressCall {
  const _CompressCall(this.inputLength, this.quality, this.minWidth, this.minHeight);
  final int inputLength;
  final int quality;
  final int minWidth;
  final int minHeight;
}

class _FakeCompressPlatform extends FlutterImageCompressPlatform {
  final List<_CompressCall> calls = [];

  /// Output length per call, indexed by `calls.length` *before* the call
  /// being scripted is recorded (i.e. index 0 = first pass, 1 = second
  /// pass). Defaults to halving the input — enough to prove compression ran
  /// without needing a script. Tests that need to force the repository's
  /// "still oversized after the first pass" fallback path override this to
  /// return an oversized first-pass result.
  int Function(int callIndex, int inputLength) outputLength = (i, inputLength) => inputLength ~/ 2;

  @override
  Future<Uint8List> compressWithList(
    Uint8List image, {
    int minWidth = 1920,
    int minHeight = 1080,
    int quality = 95,
    int rotate = 0,
    int inSampleSize = 1,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
  }) async {
    final index = calls.length;
    calls.add(_CompressCall(image.lengthInBytes, quality, minWidth, minHeight));
    return Uint8List(outputLength(index, image.lengthInBytes));
  }

  @override
  Future<void> showNativeLog(bool value) async {}

  @override
  void ignoreCheckSupportPlatform(bool value) {}

  @override
  FlutterImageCompressValidator get validator => throw UnimplementedError();

  @override
  Future<Uint8List?> compressWithFile(String path, {
    int minWidth = 1920,
    int minHeight = 1080,
    int inSampleSize = 1,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
    int numberOfRetries = 5,
  }) => throw UnimplementedError();

  @override
  Future<XFile?> compressAndGetFile(
    String path,
    String targetPath, {
    int minWidth = 1920,
    int minHeight = 1080,
    int inSampleSize = 1,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
    int numberOfRetries = 5,
  }) => throw UnimplementedError();

  @override
  Future<Uint8List?> compressAssetImage(
    String assetName, {
    int minWidth = 1920,
    int minHeight = 1080,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
  }) => throw UnimplementedError();
}

class _FakeSlipGalleryRepository implements SlipGalleryRepository {
  /// `null` for an asset id simulates the source file having been deleted
  /// from the gallery between the query and the upload attempt.
  Map<String, Uint8List?> bytesById = {};

  @override
  Future<Uint8List?> readBytes(String assetId) async => bytesById[assetId];

  @override
  Future<GalleryAccessLevel> currentAccess() => throw UnimplementedError();
  @override
  Future<GalleryAccessLevel> requestAccess() => throw UnimplementedError();
  @override
  Future<void> presentLimitedSelection() => throw UnimplementedError();
  @override
  Future<void> openSettings() => throw UnimplementedError();
  @override
  Future<List<SlipCandidate>> queryConfiguredAlbums() => throw UnimplementedError();
}

/// Stands in for `POST /api/v1/transactions/upload-slip`'s three real
/// response shapes (confirmed against cashlog-api directly, T10):
///  - 201 + `data`: a new transaction (`uploaded`)
///  - 200, no `data` key at all (`response.OkMessage`'s `omitempty`): the
///    common "already processed" short-circuit (`duplicate`)
///  - 409 `{"error_code":"DUPLICATE_RESOURCE"}`: the rarer DB-race duplicate
///    (also `duplicate`, via a different code path in the repository)
///  - any other `error_code`: a real failure
class _ScriptedUploadAdapter implements HttpClientAdapter {
  String Function()? script;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    lastRequest = options;
    final outcome = script!();
    return switch (outcome) {
      'uploaded' => ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {
              'id': 501,
              'amount': 250,
              'transaction_type': 'expense',
              'account_id': 1,
              'transaction_date': '2026-09-05T00:00:00.000Z',
              'category': null,
            },
            'message': 'Transaction processed successfully',
          }),
          201,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      'duplicate_200' => ResponseBody.fromString(
          jsonEncode({'success': true, 'message': 'Transaction processed successfully (skipped or duplicate caught early)'}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      'duplicate_409' => ResponseBody.fromString(
          jsonEncode({'success': false, 'error_code': 'DUPLICATE_RESOURCE', 'message': 'This data already exists in our system.'}),
          409,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      'slip_parse_failed' => ResponseBody.fromString(
          jsonEncode({'success': false, 'error_code': 'SLIP_PARSE_FAILED', 'message': 'Failed to extract clear transaction details from the slip.'}),
          422,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      'quota_exhausted' => ResponseBody.fromString(
          jsonEncode({'success': false, 'error_code': 'GEMINI_QUOTA_EXHAUSTED', 'message': 'Gemini quota exhausted.'}),
          429,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      _ => throw StateError('unscripted outcome: $outcome'),
    };
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final originalCompressPlatform = FlutterImageCompressPlatform.instance;
  late _FakeCompressPlatform compressPlatform;
  setUpAll(() {
    compressPlatform = _FakeCompressPlatform();
    FlutterImageCompressPlatform.instance = compressPlatform;
  });
  tearDownAll(() => FlutterImageCompressPlatform.instance = originalCompressPlatform);

  late AppDatabase db;
  late _ScriptedUploadAdapter adapter;
  late _FakeSlipGalleryRepository galleryRepository;
  late SlipUploadRepository repository;

  const rawByteCount = 100;
  const candidate = SlipCandidate(id: 'asset-1', filename: 'scb_001.jpg', sourceAlbum: 'SCB EASY');

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    adapter = _ScriptedUploadAdapter();
    compressPlatform.calls.clear();
    compressPlatform.outputLength = (i, inputLength) => inputLength ~/ 2;
    galleryRepository = _FakeSlipGalleryRepository()..bytesById = {'asset-1': Uint8List.fromList(List.filled(rawByteCount, 1))};
    // dioProvider (not a bare Dio()) so the real error/error_code-mapping
    // interceptor (dio_client.dart) is in the request path — a bare Dio()
    // never converts a non-2xx body's error_code into a typed Failure at
    // all, which would make every Left below an untyped UnknownFailure
    // regardless of what Failure.fromErrorCode actually does.
    final dio = ProviderContainer().read(dioProvider)..httpClientAdapter = adapter;
    repository = SlipUploadRepository(ApiClient(dio), db, galleryRepository);
  });

  tearDown(() async => db.close());

  group('diffNewFiles', () {
    test('excludes uploaded/duplicate/failed/junk rows, keeps quotaExceeded and unseen ones eligible', () async {
      await db.into(db.scannedSlips).insert(
        ScannedSlipsCompanion.insert(localImageName: 'already_uploaded.jpg', sourceFolder: 'SCB EASY', status: SlipStatus.uploaded, scannedAt: DateTime.now()),
      );
      await db.into(db.scannedSlips).insert(
        ScannedSlipsCompanion.insert(localImageName: 'already_duplicate.jpg', sourceFolder: 'SCB EASY', status: SlipStatus.duplicate, scannedAt: DateTime.now()),
      );
      await db.into(db.scannedSlips).insert(
        ScannedSlipsCompanion.insert(localImageName: 'previously_failed.jpg', sourceFolder: 'SCB EASY', status: SlipStatus.failed, scannedAt: DateTime.now()),
      );
      await db.into(db.scannedSlips).insert(
        ScannedSlipsCompanion.insert(localImageName: 'previously_junk.jpg', sourceFolder: 'SCB EASY', status: SlipStatus.junk, scannedAt: DateTime.now()),
      );
      await db.into(db.scannedSlips).insert(
        ScannedSlipsCompanion.insert(localImageName: 'previously_quota_exceeded.jpg', sourceFolder: 'SCB EASY', status: SlipStatus.quotaExceeded, scannedAt: DateTime.now()),
      );

      const candidates = [
        SlipCandidate(id: '1', filename: 'already_uploaded.jpg', sourceAlbum: 'SCB EASY'),
        SlipCandidate(id: '2', filename: 'already_duplicate.jpg', sourceAlbum: 'SCB EASY'),
        SlipCandidate(id: '3', filename: 'previously_failed.jpg', sourceAlbum: 'SCB EASY'),
        SlipCandidate(id: '4', filename: 'previously_junk.jpg', sourceAlbum: 'SCB EASY'),
        SlipCandidate(id: '5', filename: 'previously_quota_exceeded.jpg', sourceAlbum: 'SCB EASY'),
        SlipCandidate(id: '6', filename: 'brand_new.jpg', sourceAlbum: 'SCB EASY'),
      ];

      final result = await repository.diffNewFiles(candidates);

      expect(result.map((c) => c.filename).toSet(), {'previously_quota_exceeded.jpg', 'brand_new.jpg'});
    });
  });

  group('uploadOne', () {
    test('201 with data: records uploaded + serverTransactionId, upserts cached_transactions', () async {
      adapter.script = () => 'uploaded';

      final result = await repository.uploadOne(candidate);

      expect(result.isRight(), isTrue, reason: 'expected success, got failure: ${result.fold((f) => f, (_) => null)}');
      result.fold((f) => null, (outcome) => expect(outcome, isA<SlipUploaded>()));

      final row = await db.select(db.scannedSlips).getSingle();
      expect(row.status, SlipStatus.uploaded);
      expect(row.serverTransactionId, 501);
      expect(row.retryCount, 0);

      final txRow = await db.select(db.cachedTransactions).getSingle();
      expect(txRow.id, 501);
      expect(txRow.amount, 250);
    });

    test('200 with no data key: records duplicate, writes no cached_transactions row', () async {
      adapter.script = () => 'duplicate_200';

      final result = await repository.uploadOne(candidate);

      expect(result.isRight(), isTrue);
      result.fold((f) => null, (outcome) => expect(outcome, isA<SlipDuplicate>()));

      final row = await db.select(db.scannedSlips).getSingle();
      expect(row.status, SlipStatus.duplicate);
      expect(row.serverTransactionId, isNull);

      final txRows = await db.select(db.cachedTransactions).get();
      expect(txRows, isEmpty);
    });

    test('409 DUPLICATE_RESOURCE: also folds into the duplicate outcome, not a failure', () async {
      adapter.script = () => 'duplicate_409';

      final result = await repository.uploadOne(candidate);

      expect(result.isRight(), isTrue, reason: 'expected duplicate to be a Right, got: ${result.fold((f) => f, (_) => null)}');
      result.fold((f) => null, (outcome) => expect(outcome, isA<SlipDuplicate>()));

      final row = await db.select(db.scannedSlips).getSingle();
      expect(row.status, SlipStatus.duplicate);
    });

    test('a real error (SLIP_PARSE_FAILED) surfaces as Left and records failed + lastErrorCode', () async {
      adapter.script = () => 'slip_parse_failed';

      final result = await repository.uploadOne(candidate);

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<SlipParseFailedFailure>()), (_) => fail('expected a Left'));

      final row = await db.select(db.scannedSlips).getSingle();
      expect(row.status, SlipStatus.failed);
      expect(row.lastErrorCode, 'SLIP_PARSE_FAILED');
      expect(row.retryCount, 0);
    });

    test('retrying a previously-failed file increments retryCount', () async {
      adapter.script = () => 'slip_parse_failed';
      await repository.uploadOne(candidate);
      await repository.uploadOne(candidate);

      final row = await db.select(db.scannedSlips).getSingle();
      expect(row.retryCount, 1);
    });

    test('GEMINI_QUOTA_EXHAUSTED records quotaExceeded, not failed', () async {
      adapter.script = () => 'quota_exhausted';

      final result = await repository.uploadOne(candidate);

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<GeminiQuotaExhaustedFailure>()), (_) => fail('expected a Left'));

      final row = await db.select(db.scannedSlips).getSingle();
      expect(row.status, SlipStatus.quotaExceeded);
      expect(row.lastErrorCode, 'GEMINI_QUOTA_EXHAUSTED');
      expect(row.retryCount, 0);
    });

    test('retryCount increments across two consecutive quota-exhausted attempts on the same file', () async {
      adapter.script = () => 'quota_exhausted';

      await repository.uploadOne(candidate);
      await repository.uploadOne(candidate);

      final row = await db.select(db.scannedSlips).getSingle();
      expect(row.status, SlipStatus.quotaExceeded);
      expect(row.retryCount, 1);
    });

    test('a quotaExceeded file is picked up again on the next diffNewFiles pass and succeeds', () async {
      adapter.script = () => 'quota_exhausted';
      await repository.uploadOne(candidate);

      var eligible = await repository.diffNewFiles(const [candidate]);
      expect(eligible.map((c) => c.filename), [candidate.filename]);

      adapter.script = () => 'uploaded';
      final result = await repository.uploadOne(candidate);

      expect(result.isRight(), isTrue);
      final row = await db.select(db.scannedSlips).getSingle();
      expect(row.status, SlipStatus.uploaded);
      expect(row.retryCount, 1);

      eligible = await repository.diffNewFiles(const [candidate]);
      expect(eligible, isEmpty, reason: 'now uploaded, no longer eligible for re-scan');
    });

    test('source file missing from the gallery fails without ever hitting the network or compressing', () async {
      galleryRepository.bytesById = {'asset-1': null};

      final result = await repository.uploadOne(candidate);

      expect(result.isLeft(), isTrue);
      expect(adapter.lastRequest, isNull, reason: 'no network call should happen when the source bytes are unavailable');
      expect(compressPlatform.calls, isEmpty);

      final row = await db.select(db.scannedSlips).getSingle();
      expect(row.status, SlipStatus.failed);
    });
  });

  group('uploadManual (T21)', () {
    const manualFilename = 'manual_001.jpg';
    final manualBytes = Uint8List.fromList(List.filled(rawByteCount, 2));

    test('201 with data: records a scanned_slips row with sourceFolder "manual", upserts cached_transactions', () async {
      adapter.script = () => 'uploaded';

      final result = await repository.uploadManual(bytes: manualBytes, filename: manualFilename);

      expect(result.isRight(), isTrue, reason: 'expected success, got failure: ${result.fold((f) => f, (_) => null)}');
      result.fold((f) => null, (outcome) => expect(outcome, isA<SlipUploaded>()));

      final row = await db.select(db.scannedSlips).getSingle();
      expect(row.localImageName, manualFilename);
      expect(row.sourceFolder, 'manual');
      expect(row.status, SlipStatus.uploaded);
      expect(row.serverTransactionId, 501);

      final txRow = await db.select(db.cachedTransactions).getSingle();
      expect(txRow.id, 501);
    });

    test('never touches SlipGalleryRepository — the given bytes are what get compressed and sent', () async {
      adapter.script = () => 'uploaded';

      await repository.uploadManual(bytes: manualBytes, filename: manualFilename);

      expect(compressPlatform.calls, hasLength(1));
      expect(compressPlatform.calls.single.inputLength, rawByteCount);
    });

    test('a real error (SLIP_PARSE_FAILED) surfaces as Left and records failed with sourceFolder "manual"', () async {
      adapter.script = () => 'slip_parse_failed';

      final result = await repository.uploadManual(bytes: manualBytes, filename: manualFilename);

      expect(result.isLeft(), isTrue);
      final row = await db.select(db.scannedSlips).getSingle();
      expect(row.sourceFolder, 'manual');
      expect(row.status, SlipStatus.failed);
      expect(row.lastErrorCode, 'SLIP_PARSE_FAILED');
    });

    test('a duplicate 200 response is recorded as duplicate, not uploaded', () async {
      adapter.script = () => 'duplicate_200';

      final result = await repository.uploadManual(bytes: manualBytes, filename: manualFilename);

      expect(result.isRight(), isTrue);
      result.fold((f) => null, (outcome) => expect(outcome, isA<SlipDuplicate>()));
      final row = await db.select(db.scannedSlips).getSingle();
      expect(row.sourceFolder, 'manual');
      expect(row.status, SlipStatus.duplicate);
    });

    test('retrying the same manually-picked filename increments retryCount, same as an auto-scanned retry', () async {
      adapter.script = () => 'slip_parse_failed';
      await repository.uploadManual(bytes: manualBytes, filename: manualFilename);
      await repository.uploadManual(bytes: manualBytes, filename: manualFilename);

      final row = await db.select(db.scannedSlips).getSingle();
      expect(row.retryCount, 1);
    });
  });

  group('compression', () {
    test('every upload attempt compresses the raw gallery bytes before sending', () async {
      adapter.script = () => 'uploaded';

      await repository.uploadOne(candidate);

      expect(compressPlatform.calls, hasLength(1), reason: 'compression should run exactly once per upload attempt, not per retry-within-a-call');
      final call = compressPlatform.calls.single;
      expect(call.inputLength, rawByteCount, reason: 'should compress the raw gallery bytes, not some already-transformed copy');
      expect(call.quality, 80);
      expect(call.minWidth, 1600);
      expect(call.minHeight, 1600);
    });

    test('normal-sized output never triggers the second, lower-quality pass', () async {
      adapter.script = () => 'uploaded';

      await repository.uploadOne(candidate);
      // The fake halves a 100-byte source by default — nowhere near the
      // ~3.5MB retry threshold, so exactly one pass should run.
      expect(compressPlatform.calls, hasLength(1));
    });

    test('a first pass that is still oversized (>3.5MB) triggers a second, lower-quality pass', () async {
      adapter.script = () => 'uploaded';
      const oversized = 4 * 1024 * 1024;
      compressPlatform.outputLength = (i, inputLength) => i == 0 ? oversized : 500;

      await repository.uploadOne(candidate);

      expect(compressPlatform.calls, hasLength(2));
      final secondPass = compressPlatform.calls[1];
      expect(secondPass.inputLength, rawByteCount, reason: 'the second pass re-compresses the original raw bytes, not the oversized first-pass output');
      expect(secondPass.quality, 50);
      expect(secondPass.minWidth, 1280);
      expect(secondPass.minHeight, 1280);
    });

    test('a failed upload still only compresses once (compression happens before the network call, not retried per failure)', () async {
      adapter.script = () => 'slip_parse_failed';

      await repository.uploadOne(candidate);

      expect(compressPlatform.calls, hasLength(1));
    });
  });
}

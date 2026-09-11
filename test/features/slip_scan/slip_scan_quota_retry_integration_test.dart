// T15 end-to-end check: a real SlipUploadRepository (real diffNewFiles +
// uploadOne, backed by an in-memory drift db) driven through
// SlipScanPipeline.runScan() twice — first pass hits GEMINI_QUOTA_EXHAUSTED,
// second pass (a fresh scan trigger, e.g. app resume per spec §7.2) succeeds.
// This is deliberately NOT built on the pipeline provider test's fake
// SlipUploadRepository, since that fake stubs diffNewFiles to just return
// whatever list a test sets directly — it never exercises the real
// scanned_slips exclusion/eligibility logic this ticket changes.
import 'dart:convert';
import 'dart:typed_data';

import 'package:cashlog/core/db/app_database.dart';
import 'package:cashlog/core/db/tables/scanned_slips.dart';
import 'package:cashlog/core/network/api_client.dart';
import 'package:cashlog/core/network/dio_client.dart';
import 'package:cashlog/features/slip_scan/data/slip_gallery_repository.dart';
import 'package:cashlog/features/slip_scan/data/slip_upload_repository.dart';
import 'package:cashlog/features/slip_scan/domain/gallery_access_level.dart';
import 'package:cashlog/features/slip_scan/domain/slip_candidate.dart';
import 'package:cashlog/features/slip_scan/presentation/providers/slip_scan_pipeline_provider.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_image_compress_platform_interface/flutter_image_compress_platform_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoopCompressPlatform extends FlutterImageCompressPlatform {
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
  }) async => image;

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
  GalleryAccessLevel access = GalleryAccessLevel.full;
  List<SlipCandidate> candidates = const [];
  Map<String, Uint8List?> bytesById = {};

  @override
  Future<GalleryAccessLevel> currentAccess() async => access;
  @override
  Future<List<SlipCandidate>> queryConfiguredAlbums() async => candidates;
  @override
  Future<Uint8List?> readBytes(String assetId) async => bytesById[assetId];

  @override
  Future<GalleryAccessLevel> requestAccess() => throw UnimplementedError();
  @override
  Future<void> presentLimitedSelection() => throw UnimplementedError();
  @override
  Future<void> openSettings() => throw UnimplementedError();
}

/// Scripted per current call count — call 0 is quota-exhausted, call 1
/// (the second `runScan`) succeeds. Mirrors the "server-driven outcome"
/// pattern from slip_upload_repository_test.dart's `_ScriptedUploadAdapter`.
class _SequencedUploadAdapter implements HttpClientAdapter {
  final List<String Function()> scripts;
  int callCount = 0;

  _SequencedUploadAdapter(this.scripts);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final outcome = scripts[callCount]();
    callCount++;
    return switch (outcome) {
      'quota_exhausted' => ResponseBody.fromString(
          jsonEncode({'success': false, 'error_code': 'GEMINI_QUOTA_EXHAUSTED', 'message': 'Gemini quota exhausted.'}),
          429,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      'uploaded' => ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {
              'id': 900,
              'amount': 150,
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
      _ => throw StateError('unscripted outcome: $outcome'),
    };
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final originalCompressPlatform = FlutterImageCompressPlatform.instance;
  setUpAll(() => FlutterImageCompressPlatform.instance = _NoopCompressPlatform());
  tearDownAll(() => FlutterImageCompressPlatform.instance = originalCompressPlatform);

  const candidate = SlipCandidate(id: 'asset-1', filename: 'scb_quota.jpg', sourceAlbum: 'SCB EASY');

  test(
    'quota-exhausted slip is excluded from retry within the same scan, then picked up and '
    'succeeds on the next scan trigger',
    () async {
      final db = AppDatabase.withExecutor(NativeDatabase.memory());
      addTearDown(db.close);

      final adapter = _SequencedUploadAdapter([() => 'quota_exhausted', () => 'uploaded']);
      final dio = ProviderContainer().read(dioProvider)..httpClientAdapter = adapter;
      final galleryRepository = _FakeSlipGalleryRepository()
        ..candidates = const [candidate]
        ..bytesById = {'asset-1': Uint8List.fromList(List.filled(100, 1))};
      final uploadRepository = SlipUploadRepository(ApiClient(dio), db, galleryRepository);

      final container = ProviderContainer(
        overrides: [
          slipGalleryRepositoryProvider.overrideWithValue(galleryRepository),
          slipUploadRepositoryProvider.overrideWithValue(uploadRepository),
        ],
      );
      addTearDown(container.dispose);
      container.listen(slipScanPipelineProvider, (prev, next) {});

      // First scan trigger: quota exhausted.
      await container.read(slipScanPipelineProvider.notifier).runScan(delay: Duration.zero);

      var row = await db.select(db.scannedSlips).getSingle();
      expect(row.status, SlipStatus.quotaExceeded);
      expect(row.retryCount, 0);

      final firstState = container.read(slipScanPipelineProvider);
      expect(firstState.total, 1, reason: 'no retry loop within the same scan pass');
      expect(firstState.results.single.status, SlipUploadStatus.failed);

      // Second scan trigger (simulates cold start/resume per spec §7.2):
      // the same file must be offered again since diffNewFiles now treats
      // quotaExceeded as eligible.
      await container.read(slipScanPipelineProvider.notifier).runScan(delay: Duration.zero);

      expect(adapter.callCount, 2, reason: 'the file must have been re-attempted on the second scan');

      row = await db.select(db.scannedSlips).getSingle();
      expect(row.status, SlipStatus.uploaded);
      expect(row.serverTransactionId, 900);
      expect(row.retryCount, 1);

      final secondState = container.read(slipScanPipelineProvider);
      expect(secondState.total, 1);
      expect(secondState.results.single.status, SlipUploadStatus.uploaded);

      final txRows = await db.select(db.cachedTransactions).get();
      expect(txRows, hasLength(1));
      expect(txRows.single.id, 900);
    },
  );

  test('a genuinely permanent failure is NOT retried on the next scan trigger (regression check)', () async {
    final db = AppDatabase.withExecutor(NativeDatabase.memory());
    addTearDown(db.close);

    final adapter = _PermanentFailureAdapter();
    final dio = ProviderContainer().read(dioProvider)..httpClientAdapter = adapter;
    final galleryRepository = _FakeSlipGalleryRepository()
      ..candidates = const [candidate]
      ..bytesById = {'asset-1': Uint8List.fromList(List.filled(100, 1))};
    final uploadRepository = SlipUploadRepository(ApiClient(dio), db, galleryRepository);

    final container = ProviderContainer(
      overrides: [
        slipGalleryRepositoryProvider.overrideWithValue(galleryRepository),
        slipUploadRepositoryProvider.overrideWithValue(uploadRepository),
      ],
    );
    addTearDown(container.dispose);
    container.listen(slipScanPipelineProvider, (prev, next) {});

    await container.read(slipScanPipelineProvider.notifier).runScan(delay: Duration.zero);
    var row = await db.select(db.scannedSlips).getSingle();
    expect(row.status, SlipStatus.failed);

    await container.read(slipScanPipelineProvider.notifier).runScan(delay: Duration.zero);

    expect(adapter.callCount, 1, reason: 'a permanently failed slip must not be re-attempted on a later scan');
    row = await db.select(db.scannedSlips).getSingle();
    expect(row.status, SlipStatus.failed);
    expect(row.retryCount, 0);
  });
}

class _PermanentFailureAdapter implements HttpClientAdapter {
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    callCount++;
    return ResponseBody.fromString(
      jsonEncode({'success': false, 'error_code': 'SLIP_PARSE_FAILED', 'message': 'Failed to extract clear transaction details from the slip.'}),
      422,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/slip_upload_repository.dart';

part 'auto_scan_status_provider.g.dart';

/// Ticket 09: thin reactive pass-through to
/// `SlipUploadRepository.watchLastSuccessfulAutoScanUpload` — the Home page
/// widget only needs a provider to `ref.watch`, not repository details.
@riverpod
Stream<DateTime?> lastAutoScanUpload(Ref ref) =>
    ref.watch(slipUploadRepositoryProvider).watchLastSuccessfulAutoScanUpload();

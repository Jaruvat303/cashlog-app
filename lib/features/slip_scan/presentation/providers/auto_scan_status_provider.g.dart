// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_scan_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Ticket 09: thin reactive pass-through to
/// `SlipUploadRepository.watchLastSuccessfulAutoScanUpload` — the Home page
/// widget only needs a provider to `ref.watch`, not repository details.

@ProviderFor(lastAutoScanUpload)
final lastAutoScanUploadProvider = LastAutoScanUploadProvider._();

/// Ticket 09: thin reactive pass-through to
/// `SlipUploadRepository.watchLastSuccessfulAutoScanUpload` — the Home page
/// widget only needs a provider to `ref.watch`, not repository details.

final class LastAutoScanUploadProvider
    extends
        $FunctionalProvider<AsyncValue<DateTime?>, DateTime?, Stream<DateTime?>>
    with $FutureModifier<DateTime?>, $StreamProvider<DateTime?> {
  /// Ticket 09: thin reactive pass-through to
  /// `SlipUploadRepository.watchLastSuccessfulAutoScanUpload` — the Home page
  /// widget only needs a provider to `ref.watch`, not repository details.
  LastAutoScanUploadProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastAutoScanUploadProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastAutoScanUploadHash();

  @$internal
  @override
  $StreamProviderElement<DateTime?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DateTime?> create(Ref ref) {
    return lastAutoScanUpload(ref);
  }
}

String _$lastAutoScanUploadHash() =>
    r'93e2b6fc8d0b3e2fa54951edcba14f316f0ed3f5';

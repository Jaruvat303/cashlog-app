// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_scan_processing_indicator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Ticket 10: "a few seconds" per spec — kept as an overridable provider
/// (not a bare constant) so tests can shrink it, same reasoning as
/// [kSlipUploadDelay]'s default-parameter override, just expressed as a
/// provider since this value is read from a widget's `State`, not passed
/// down a call chain.

@ProviderFor(autoScanCompletionHoldDuration)
final autoScanCompletionHoldDurationProvider =
    AutoScanCompletionHoldDurationProvider._();

/// Ticket 10: "a few seconds" per spec — kept as an overridable provider
/// (not a bare constant) so tests can shrink it, same reasoning as
/// [kSlipUploadDelay]'s default-parameter override, just expressed as a
/// provider since this value is read from a widget's `State`, not passed
/// down a call chain.

final class AutoScanCompletionHoldDurationProvider
    extends $FunctionalProvider<Duration, Duration, Duration>
    with $Provider<Duration> {
  /// Ticket 10: "a few seconds" per spec — kept as an overridable provider
  /// (not a bare constant) so tests can shrink it, same reasoning as
  /// [kSlipUploadDelay]'s default-parameter override, just expressed as a
  /// provider since this value is read from a widget's `State`, not passed
  /// down a call chain.
  AutoScanCompletionHoldDurationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoScanCompletionHoldDurationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoScanCompletionHoldDurationHash();

  @$internal
  @override
  $ProviderElement<Duration> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Duration create(Ref ref) {
    return autoScanCompletionHoldDuration(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Duration value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Duration>(value),
    );
  }
}

String _$autoScanCompletionHoldDurationHash() =>
    r'8494e5d4fdee5f40d8d7243b91e298e358738af0';

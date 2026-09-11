// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_slip_attach_button.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(manualSlipImageSource)
final manualSlipImageSourceProvider = ManualSlipImageSourceProvider._();

final class ManualSlipImageSourceProvider
    extends
        $FunctionalProvider<
          ManualSlipImageSource,
          ManualSlipImageSource,
          ManualSlipImageSource
        >
    with $Provider<ManualSlipImageSource> {
  ManualSlipImageSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'manualSlipImageSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$manualSlipImageSourceHash();

  @$internal
  @override
  $ProviderElement<ManualSlipImageSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ManualSlipImageSource create(Ref ref) {
    return manualSlipImageSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ManualSlipImageSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ManualSlipImageSource>(value),
    );
  }
}

String _$manualSlipImageSourceHash() =>
    r'17cb347b61ee53457d07794a3a9a971c66e640c7';

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slip_gallery_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(slipGalleryRepository)
final slipGalleryRepositoryProvider = SlipGalleryRepositoryProvider._();

final class SlipGalleryRepositoryProvider
    extends
        $FunctionalProvider<
          SlipGalleryRepository,
          SlipGalleryRepository,
          SlipGalleryRepository
        >
    with $Provider<SlipGalleryRepository> {
  SlipGalleryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'slipGalleryRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$slipGalleryRepositoryHash();

  @$internal
  @override
  $ProviderElement<SlipGalleryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SlipGalleryRepository create(Ref ref) {
    return slipGalleryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SlipGalleryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SlipGalleryRepository>(value),
    );
  }
}

String _$slipGalleryRepositoryHash() =>
    r'1ca5fe20e72b7cd5dcb1617e9544c848f9665637';

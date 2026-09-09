// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slip_gallery_debug_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Debug-only controller (T9 excludes upload/compression/drift persistence
/// entirely — this never writes anything, it only drives
/// [SlipGalleryRepository]'s read-only `photo_manager` calls for the debug
/// screen). Not `Either<Failure, T>`-shaped — see
/// `gallery_access_level.dart` for why.

@ProviderFor(SlipGalleryDebugController)
final slipGalleryDebugControllerProvider =
    SlipGalleryDebugControllerProvider._();

/// Debug-only controller (T9 excludes upload/compression/drift persistence
/// entirely — this never writes anything, it only drives
/// [SlipGalleryRepository]'s read-only `photo_manager` calls for the debug
/// screen). Not `Either<Failure, T>`-shaped — see
/// `gallery_access_level.dart` for why.
final class SlipGalleryDebugControllerProvider
    extends
        $NotifierProvider<SlipGalleryDebugController, SlipGalleryDebugState> {
  /// Debug-only controller (T9 excludes upload/compression/drift persistence
  /// entirely — this never writes anything, it only drives
  /// [SlipGalleryRepository]'s read-only `photo_manager` calls for the debug
  /// screen). Not `Either<Failure, T>`-shaped — see
  /// `gallery_access_level.dart` for why.
  SlipGalleryDebugControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'slipGalleryDebugControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$slipGalleryDebugControllerHash();

  @$internal
  @override
  SlipGalleryDebugController create() => SlipGalleryDebugController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SlipGalleryDebugState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SlipGalleryDebugState>(value),
    );
  }
}

String _$slipGalleryDebugControllerHash() =>
    r'c71e276ff2c319d3847aec2cd2f40e42bc92db97';

/// Debug-only controller (T9 excludes upload/compression/drift persistence
/// entirely — this never writes anything, it only drives
/// [SlipGalleryRepository]'s read-only `photo_manager` calls for the debug
/// screen). Not `Either<Failure, T>`-shaped — see
/// `gallery_access_level.dart` for why.

abstract class _$SlipGalleryDebugController
    extends $Notifier<SlipGalleryDebugState> {
  SlipGalleryDebugState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SlipGalleryDebugState, SlipGalleryDebugState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SlipGalleryDebugState, SlipGalleryDebugState>,
              SlipGalleryDebugState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slip_upload_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(slipUploadRepository)
final slipUploadRepositoryProvider = SlipUploadRepositoryProvider._();

final class SlipUploadRepositoryProvider
    extends
        $FunctionalProvider<
          SlipUploadRepository,
          SlipUploadRepository,
          SlipUploadRepository
        >
    with $Provider<SlipUploadRepository> {
  SlipUploadRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'slipUploadRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$slipUploadRepositoryHash();

  @$internal
  @override
  $ProviderElement<SlipUploadRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SlipUploadRepository create(Ref ref) {
    return slipUploadRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SlipUploadRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SlipUploadRepository>(value),
    );
  }
}

String _$slipUploadRepositoryHash() =>
    r'852ecaf1803fa40e5d2aa8d76f80ef96360025d0';

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ping_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pingRepository)
final pingRepositoryProvider = PingRepositoryProvider._();

final class PingRepositoryProvider
    extends $FunctionalProvider<PingRepository, PingRepository, PingRepository>
    with $Provider<PingRepository> {
  PingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pingRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pingRepositoryHash();

  @$internal
  @override
  $ProviderElement<PingRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PingRepository create(Ref ref) {
    return pingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PingRepository>(value),
    );
  }
}

String _$pingRepositoryHash() => r'8df8704118477843b13ff6435fa8c86bc7537373';

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_actions_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pendingActionsRepository)
final pendingActionsRepositoryProvider = PendingActionsRepositoryProvider._();

final class PendingActionsRepositoryProvider
    extends
        $FunctionalProvider<
          PendingActionsRepository,
          PendingActionsRepository,
          PendingActionsRepository
        >
    with $Provider<PendingActionsRepository> {
  PendingActionsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingActionsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingActionsRepositoryHash();

  @$internal
  @override
  $ProviderElement<PendingActionsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PendingActionsRepository create(Ref ref) {
    return pendingActionsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PendingActionsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PendingActionsRepository>(value),
    );
  }
}

String _$pendingActionsRepositoryHash() =>
    r'470279690952295692fc9442de2f79f903b4254c';

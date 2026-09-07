// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// No `initialLocation` override — go_router seeds the initial route from the
/// platform's `defaultRouteName`, which is what makes a deep link land on the
/// correct tab even after a hot restart (hot restart preserves that
/// platform-level route info; only a cold process kill resets it).

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// No `initialLocation` override — go_router seeds the initial route from the
/// platform's `defaultRouteName`, which is what makes a deep link land on the
/// correct tab even after a hot restart (hot restart preserves that
/// platform-level route info; only a cold process kill resets it).

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// No `initialLocation` override — go_router seeds the initial route from the
  /// platform's `defaultRouteName`, which is what makes a deep link land on the
  /// correct tab even after a hot restart (hot restart preserves that
  /// platform-level route info; only a cold process kill resets it).
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'd47c7183194be83a0c56ef8bc9d92f86578ab0be';

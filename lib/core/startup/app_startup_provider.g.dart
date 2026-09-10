// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_startup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Syncs the small, frequently-cross-referenced caches (accounts,
/// categories) exactly once per app run, regardless of which bottom-nav tab
/// the user opens first.
///
/// Root-cause fix: `go_router`'s `StatefulShellBranch` entries don't set
/// `preload: true` (app_router.dart), so a branch only builds — and only
/// then runs its own `initState` sync (`AccountsPage`/`CategoriesPage`) —
/// once the user actually navigates to it. Every *other* screen that reads
/// `activeAccountsProvider`/`allCategoriesProvider` (the transaction feed,
/// T6's create/edit form, and any future call site) was silently at the
/// mercy of whichever tab the user happened to open first, rather than
/// having its own copy-pasted refresh call — this provider is the single
/// place that guarantees both caches, so none of those screens need one.
///
/// `keepAlive: true`: this is a one-time-per-app-session action, not a
/// value anything re-derives from — nothing should ever cause it to
/// re-run just because its last watcher went away.

@ProviderFor(appStartup)
final appStartupProvider = AppStartupProvider._();

/// Syncs the small, frequently-cross-referenced caches (accounts,
/// categories) exactly once per app run, regardless of which bottom-nav tab
/// the user opens first.
///
/// Root-cause fix: `go_router`'s `StatefulShellBranch` entries don't set
/// `preload: true` (app_router.dart), so a branch only builds — and only
/// then runs its own `initState` sync (`AccountsPage`/`CategoriesPage`) —
/// once the user actually navigates to it. Every *other* screen that reads
/// `activeAccountsProvider`/`allCategoriesProvider` (the transaction feed,
/// T6's create/edit form, and any future call site) was silently at the
/// mercy of whichever tab the user happened to open first, rather than
/// having its own copy-pasted refresh call — this provider is the single
/// place that guarantees both caches, so none of those screens need one.
///
/// `keepAlive: true`: this is a one-time-per-app-session action, not a
/// value anything re-derives from — nothing should ever cause it to
/// re-run just because its last watcher went away.

final class AppStartupProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Syncs the small, frequently-cross-referenced caches (accounts,
  /// categories) exactly once per app run, regardless of which bottom-nav tab
  /// the user opens first.
  ///
  /// Root-cause fix: `go_router`'s `StatefulShellBranch` entries don't set
  /// `preload: true` (app_router.dart), so a branch only builds — and only
  /// then runs its own `initState` sync (`AccountsPage`/`CategoriesPage`) —
  /// once the user actually navigates to it. Every *other* screen that reads
  /// `activeAccountsProvider`/`allCategoriesProvider` (the transaction feed,
  /// T6's create/edit form, and any future call site) was silently at the
  /// mercy of whichever tab the user happened to open first, rather than
  /// having its own copy-pasted refresh call — this provider is the single
  /// place that guarantees both caches, so none of those screens need one.
  ///
  /// `keepAlive: true`: this is a one-time-per-app-session action, not a
  /// value anything re-derives from — nothing should ever cause it to
  /// re-run just because its last watcher went away.
  AppStartupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appStartupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appStartupHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return appStartup(ref);
  }
}

String _$appStartupHash() => r'aaeb74eb0609ede37b921b067012099fb8dd000b';

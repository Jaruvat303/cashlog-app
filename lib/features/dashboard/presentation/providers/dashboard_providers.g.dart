// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Plain `autoDispose` family (default — no `keepAlive`, no drift table
/// backing it): spec §11/§8 are explicit that the dashboard summary is
/// in-memory Riverpod state only, refetched per (year, month) rather than
/// persisted, so letting it drop once nothing watches it is the correct
/// behavior here, not an oversight.
///
/// [DashboardRepository.fetchSummary] itself stays `Either`-only (never
/// throws, independently unit-testable) per CLAUDE.md's repository/usecase
/// rule. This provider is the one narrow, deliberate seam that turns a
/// `Left(Failure)` into a value Riverpod's own `Future`/`AsyncValue`
/// machinery can carry as `AsyncError` — the only way to get `.when()`
/// loading/error/data states out of a `Future`-shaped provider. The
/// `Failure` itself is what surfaces as the error object, not some new
/// exception type, so `error is Failure` still works in the UI.
///
/// `(failure) => throw failure` (not `Future.error(failure)`) deliberately —
/// its inferred return type is `Never`, which unifies cleanly with the
/// other branch's `DashboardSummary` for `fold`'s shared type parameter.
/// Returning a `Future` from one branch instead made `fold`'s inferred type
/// collapse to `Object`, and the resulting `Future`-wrapped-in-a-`Future`
/// never flattened — `.future` hung indefinitely instead of rejecting.
///
/// `retry: _noRetry`: Riverpod 3's own `ProviderContainer.defaultRetry`
/// auto-retries any thrown, non-`Error` value up to 10 times with
/// exponential backoff — since a thrown [Failure] is exactly that shape,
/// leaving the default on would silently re-run a *permanent* failure
/// (e.g. `ErrNotFound`) up to 10 times, directly contradicting spec §4's
/// retry table. Retry policy is already fully handled once, correctly, at
/// `dio_client.dart`'s interceptor (transient-only, max 2) — this provider
/// must not add a second, policy-blind retry layer on top of it.

@ProviderFor(dashboardSummary)
final dashboardSummaryProvider = DashboardSummaryFamily._();

/// Plain `autoDispose` family (default — no `keepAlive`, no drift table
/// backing it): spec §11/§8 are explicit that the dashboard summary is
/// in-memory Riverpod state only, refetched per (year, month) rather than
/// persisted, so letting it drop once nothing watches it is the correct
/// behavior here, not an oversight.
///
/// [DashboardRepository.fetchSummary] itself stays `Either`-only (never
/// throws, independently unit-testable) per CLAUDE.md's repository/usecase
/// rule. This provider is the one narrow, deliberate seam that turns a
/// `Left(Failure)` into a value Riverpod's own `Future`/`AsyncValue`
/// machinery can carry as `AsyncError` — the only way to get `.when()`
/// loading/error/data states out of a `Future`-shaped provider. The
/// `Failure` itself is what surfaces as the error object, not some new
/// exception type, so `error is Failure` still works in the UI.
///
/// `(failure) => throw failure` (not `Future.error(failure)`) deliberately —
/// its inferred return type is `Never`, which unifies cleanly with the
/// other branch's `DashboardSummary` for `fold`'s shared type parameter.
/// Returning a `Future` from one branch instead made `fold`'s inferred type
/// collapse to `Object`, and the resulting `Future`-wrapped-in-a-`Future`
/// never flattened — `.future` hung indefinitely instead of rejecting.
///
/// `retry: _noRetry`: Riverpod 3's own `ProviderContainer.defaultRetry`
/// auto-retries any thrown, non-`Error` value up to 10 times with
/// exponential backoff — since a thrown [Failure] is exactly that shape,
/// leaving the default on would silently re-run a *permanent* failure
/// (e.g. `ErrNotFound`) up to 10 times, directly contradicting spec §4's
/// retry table. Retry policy is already fully handled once, correctly, at
/// `dio_client.dart`'s interceptor (transient-only, max 2) — this provider
/// must not add a second, policy-blind retry layer on top of it.

final class DashboardSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<DashboardSummary>,
          DashboardSummary,
          FutureOr<DashboardSummary>
        >
    with $FutureModifier<DashboardSummary>, $FutureProvider<DashboardSummary> {
  /// Plain `autoDispose` family (default — no `keepAlive`, no drift table
  /// backing it): spec §11/§8 are explicit that the dashboard summary is
  /// in-memory Riverpod state only, refetched per (year, month) rather than
  /// persisted, so letting it drop once nothing watches it is the correct
  /// behavior here, not an oversight.
  ///
  /// [DashboardRepository.fetchSummary] itself stays `Either`-only (never
  /// throws, independently unit-testable) per CLAUDE.md's repository/usecase
  /// rule. This provider is the one narrow, deliberate seam that turns a
  /// `Left(Failure)` into a value Riverpod's own `Future`/`AsyncValue`
  /// machinery can carry as `AsyncError` — the only way to get `.when()`
  /// loading/error/data states out of a `Future`-shaped provider. The
  /// `Failure` itself is what surfaces as the error object, not some new
  /// exception type, so `error is Failure` still works in the UI.
  ///
  /// `(failure) => throw failure` (not `Future.error(failure)`) deliberately —
  /// its inferred return type is `Never`, which unifies cleanly with the
  /// other branch's `DashboardSummary` for `fold`'s shared type parameter.
  /// Returning a `Future` from one branch instead made `fold`'s inferred type
  /// collapse to `Object`, and the resulting `Future`-wrapped-in-a-`Future`
  /// never flattened — `.future` hung indefinitely instead of rejecting.
  ///
  /// `retry: _noRetry`: Riverpod 3's own `ProviderContainer.defaultRetry`
  /// auto-retries any thrown, non-`Error` value up to 10 times with
  /// exponential backoff — since a thrown [Failure] is exactly that shape,
  /// leaving the default on would silently re-run a *permanent* failure
  /// (e.g. `ErrNotFound`) up to 10 times, directly contradicting spec §4's
  /// retry table. Retry policy is already fully handled once, correctly, at
  /// `dio_client.dart`'s interceptor (transient-only, max 2) — this provider
  /// must not add a second, policy-blind retry layer on top of it.
  DashboardSummaryProvider._({
    required DashboardSummaryFamily super.from,
    required (int, int) super.argument,
  }) : super(
         retry: _noRetry,
         name: r'dashboardSummaryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dashboardSummaryHash();

  @override
  String toString() {
    return r'dashboardSummaryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<DashboardSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DashboardSummary> create(Ref ref) {
    final argument = this.argument as (int, int);
    return dashboardSummary(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is DashboardSummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dashboardSummaryHash() => r'88cebd8d53fc7f47e28268ce9df84cfde516b721';

/// Plain `autoDispose` family (default — no `keepAlive`, no drift table
/// backing it): spec §11/§8 are explicit that the dashboard summary is
/// in-memory Riverpod state only, refetched per (year, month) rather than
/// persisted, so letting it drop once nothing watches it is the correct
/// behavior here, not an oversight.
///
/// [DashboardRepository.fetchSummary] itself stays `Either`-only (never
/// throws, independently unit-testable) per CLAUDE.md's repository/usecase
/// rule. This provider is the one narrow, deliberate seam that turns a
/// `Left(Failure)` into a value Riverpod's own `Future`/`AsyncValue`
/// machinery can carry as `AsyncError` — the only way to get `.when()`
/// loading/error/data states out of a `Future`-shaped provider. The
/// `Failure` itself is what surfaces as the error object, not some new
/// exception type, so `error is Failure` still works in the UI.
///
/// `(failure) => throw failure` (not `Future.error(failure)`) deliberately —
/// its inferred return type is `Never`, which unifies cleanly with the
/// other branch's `DashboardSummary` for `fold`'s shared type parameter.
/// Returning a `Future` from one branch instead made `fold`'s inferred type
/// collapse to `Object`, and the resulting `Future`-wrapped-in-a-`Future`
/// never flattened — `.future` hung indefinitely instead of rejecting.
///
/// `retry: _noRetry`: Riverpod 3's own `ProviderContainer.defaultRetry`
/// auto-retries any thrown, non-`Error` value up to 10 times with
/// exponential backoff — since a thrown [Failure] is exactly that shape,
/// leaving the default on would silently re-run a *permanent* failure
/// (e.g. `ErrNotFound`) up to 10 times, directly contradicting spec §4's
/// retry table. Retry policy is already fully handled once, correctly, at
/// `dio_client.dart`'s interceptor (transient-only, max 2) — this provider
/// must not add a second, policy-blind retry layer on top of it.

final class DashboardSummaryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DashboardSummary>, (int, int)> {
  DashboardSummaryFamily._()
    : super(
        retry: _noRetry,
        name: r'dashboardSummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Plain `autoDispose` family (default — no `keepAlive`, no drift table
  /// backing it): spec §11/§8 are explicit that the dashboard summary is
  /// in-memory Riverpod state only, refetched per (year, month) rather than
  /// persisted, so letting it drop once nothing watches it is the correct
  /// behavior here, not an oversight.
  ///
  /// [DashboardRepository.fetchSummary] itself stays `Either`-only (never
  /// throws, independently unit-testable) per CLAUDE.md's repository/usecase
  /// rule. This provider is the one narrow, deliberate seam that turns a
  /// `Left(Failure)` into a value Riverpod's own `Future`/`AsyncValue`
  /// machinery can carry as `AsyncError` — the only way to get `.when()`
  /// loading/error/data states out of a `Future`-shaped provider. The
  /// `Failure` itself is what surfaces as the error object, not some new
  /// exception type, so `error is Failure` still works in the UI.
  ///
  /// `(failure) => throw failure` (not `Future.error(failure)`) deliberately —
  /// its inferred return type is `Never`, which unifies cleanly with the
  /// other branch's `DashboardSummary` for `fold`'s shared type parameter.
  /// Returning a `Future` from one branch instead made `fold`'s inferred type
  /// collapse to `Object`, and the resulting `Future`-wrapped-in-a-`Future`
  /// never flattened — `.future` hung indefinitely instead of rejecting.
  ///
  /// `retry: _noRetry`: Riverpod 3's own `ProviderContainer.defaultRetry`
  /// auto-retries any thrown, non-`Error` value up to 10 times with
  /// exponential backoff — since a thrown [Failure] is exactly that shape,
  /// leaving the default on would silently re-run a *permanent* failure
  /// (e.g. `ErrNotFound`) up to 10 times, directly contradicting spec §4's
  /// retry table. Retry policy is already fully handled once, correctly, at
  /// `dio_client.dart`'s interceptor (transient-only, max 2) — this provider
  /// must not add a second, policy-blind retry layer on top of it.

  DashboardSummaryProvider call(int year, int month) =>
      DashboardSummaryProvider._(argument: (year, month), from: this);

  @override
  String toString() => r'dashboardSummaryProvider';
}

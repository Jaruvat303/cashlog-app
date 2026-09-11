// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_invalidator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// T14: the one place that knows both T7's feed cache
/// (`monthTransactionsProvider`, drift-backed) and T8's dashboard cache
/// (`dashboardSummaryProvider`, in-memory only, spec §8/§11) need to be
/// invalidated together per (year, month) after a successful mutation
/// (CLAUDE.md's "Cache invalidation" rule). Lives in `core/` rather than
/// either feature since it's the aggregation point both T6 (transactions)
/// and T10 (slip_scan) call into — neither feature should have to import
/// the other's providers directly for this.
///
/// `ref.invalidate` only marks a family instance stale: a currently-watched
/// instance rebuilds immediately, one nobody's watching just gets dropped
/// and lazily refetches next time it's watched — never an eager background
/// refetch for months not in view.

@ProviderFor(cacheInvalidator)
final cacheInvalidatorProvider = CacheInvalidatorProvider._();

/// T14: the one place that knows both T7's feed cache
/// (`monthTransactionsProvider`, drift-backed) and T8's dashboard cache
/// (`dashboardSummaryProvider`, in-memory only, spec §8/§11) need to be
/// invalidated together per (year, month) after a successful mutation
/// (CLAUDE.md's "Cache invalidation" rule). Lives in `core/` rather than
/// either feature since it's the aggregation point both T6 (transactions)
/// and T10 (slip_scan) call into — neither feature should have to import
/// the other's providers directly for this.
///
/// `ref.invalidate` only marks a family instance stale: a currently-watched
/// instance rebuilds immediately, one nobody's watching just gets dropped
/// and lazily refetches next time it's watched — never an eager background
/// refetch for months not in view.

final class CacheInvalidatorProvider
    extends
        $FunctionalProvider<
          CacheInvalidator,
          CacheInvalidator,
          CacheInvalidator
        >
    with $Provider<CacheInvalidator> {
  /// T14: the one place that knows both T7's feed cache
  /// (`monthTransactionsProvider`, drift-backed) and T8's dashboard cache
  /// (`dashboardSummaryProvider`, in-memory only, spec §8/§11) need to be
  /// invalidated together per (year, month) after a successful mutation
  /// (CLAUDE.md's "Cache invalidation" rule). Lives in `core/` rather than
  /// either feature since it's the aggregation point both T6 (transactions)
  /// and T10 (slip_scan) call into — neither feature should have to import
  /// the other's providers directly for this.
  ///
  /// `ref.invalidate` only marks a family instance stale: a currently-watched
  /// instance rebuilds immediately, one nobody's watching just gets dropped
  /// and lazily refetches next time it's watched — never an eager background
  /// refetch for months not in view.
  CacheInvalidatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cacheInvalidatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cacheInvalidatorHash();

  @$internal
  @override
  $ProviderElement<CacheInvalidator> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CacheInvalidator create(Ref ref) {
    return cacheInvalidator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CacheInvalidator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CacheInvalidator>(value),
    );
  }
}

String _$cacheInvalidatorHash() => r'3d8eafcc12ee6dc71fdbffb73f5797ac4b6f7f59';

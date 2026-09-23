// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trend_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `keepAlive: true` — unlike [dashboardSummaryProvider]'s `autoDispose`,
/// every (granularity, year) a session has viewed stays cached for instant
/// re-display when the trend page's user toggles รายเดือน/รายปี or steps
/// through years and back (spec's "previously loaded years reappear
/// instantly" user story). [TrendQuery.year]'s `year` is always normalized
/// to `null`, so every caller in yearly mode must pass `const TrendQuery
/// .year()` rather than a query carrying a stale selected year — otherwise
/// this cache would grow one redundant entry per year the UI had selected
/// before switching modes, all fetching the exact same data.
///
/// Same `retry: _noRetry` reasoning as [dashboardSummaryProvider]: dio's own
/// interceptor already retries transient failures (max 2, spec §4); a second,
/// policy-blind retry layer on top would just re-run a *permanent* failure
/// pointlessly.

@ProviderFor(trend)
final trendProvider = TrendFamily._();

/// `keepAlive: true` — unlike [dashboardSummaryProvider]'s `autoDispose`,
/// every (granularity, year) a session has viewed stays cached for instant
/// re-display when the trend page's user toggles รายเดือน/รายปี or steps
/// through years and back (spec's "previously loaded years reappear
/// instantly" user story). [TrendQuery.year]'s `year` is always normalized
/// to `null`, so every caller in yearly mode must pass `const TrendQuery
/// .year()` rather than a query carrying a stale selected year — otherwise
/// this cache would grow one redundant entry per year the UI had selected
/// before switching modes, all fetching the exact same data.
///
/// Same `retry: _noRetry` reasoning as [dashboardSummaryProvider]: dio's own
/// interceptor already retries transient failures (max 2, spec §4); a second,
/// policy-blind retry layer on top would just re-run a *permanent* failure
/// pointlessly.

final class TrendProvider
    extends
        $FunctionalProvider<
          AsyncValue<TrendSummary>,
          TrendSummary,
          FutureOr<TrendSummary>
        >
    with $FutureModifier<TrendSummary>, $FutureProvider<TrendSummary> {
  /// `keepAlive: true` — unlike [dashboardSummaryProvider]'s `autoDispose`,
  /// every (granularity, year) a session has viewed stays cached for instant
  /// re-display when the trend page's user toggles รายเดือน/รายปี or steps
  /// through years and back (spec's "previously loaded years reappear
  /// instantly" user story). [TrendQuery.year]'s `year` is always normalized
  /// to `null`, so every caller in yearly mode must pass `const TrendQuery
  /// .year()` rather than a query carrying a stale selected year — otherwise
  /// this cache would grow one redundant entry per year the UI had selected
  /// before switching modes, all fetching the exact same data.
  ///
  /// Same `retry: _noRetry` reasoning as [dashboardSummaryProvider]: dio's own
  /// interceptor already retries transient failures (max 2, spec §4); a second,
  /// policy-blind retry layer on top would just re-run a *permanent* failure
  /// pointlessly.
  TrendProvider._({
    required TrendFamily super.from,
    required TrendQuery super.argument,
  }) : super(
         retry: _noRetry,
         name: r'trendProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$trendHash();

  @override
  String toString() {
    return r'trendProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TrendSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TrendSummary> create(Ref ref) {
    final argument = this.argument as TrendQuery;
    return trend(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TrendProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$trendHash() => r'b7295acaf5ae8b216890d33a00f6140182064826';

/// `keepAlive: true` — unlike [dashboardSummaryProvider]'s `autoDispose`,
/// every (granularity, year) a session has viewed stays cached for instant
/// re-display when the trend page's user toggles รายเดือน/รายปี or steps
/// through years and back (spec's "previously loaded years reappear
/// instantly" user story). [TrendQuery.year]'s `year` is always normalized
/// to `null`, so every caller in yearly mode must pass `const TrendQuery
/// .year()` rather than a query carrying a stale selected year — otherwise
/// this cache would grow one redundant entry per year the UI had selected
/// before switching modes, all fetching the exact same data.
///
/// Same `retry: _noRetry` reasoning as [dashboardSummaryProvider]: dio's own
/// interceptor already retries transient failures (max 2, spec §4); a second,
/// policy-blind retry layer on top would just re-run a *permanent* failure
/// pointlessly.

final class TrendFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TrendSummary>, TrendQuery> {
  TrendFamily._()
    : super(
        retry: _noRetry,
        name: r'trendProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// `keepAlive: true` — unlike [dashboardSummaryProvider]'s `autoDispose`,
  /// every (granularity, year) a session has viewed stays cached for instant
  /// re-display when the trend page's user toggles รายเดือน/รายปี or steps
  /// through years and back (spec's "previously loaded years reappear
  /// instantly" user story). [TrendQuery.year]'s `year` is always normalized
  /// to `null`, so every caller in yearly mode must pass `const TrendQuery
  /// .year()` rather than a query carrying a stale selected year — otherwise
  /// this cache would grow one redundant entry per year the UI had selected
  /// before switching modes, all fetching the exact same data.
  ///
  /// Same `retry: _noRetry` reasoning as [dashboardSummaryProvider]: dio's own
  /// interceptor already retries transient failures (max 2, spec §4); a second,
  /// policy-blind retry layer on top would just re-run a *permanent* failure
  /// pointlessly.

  TrendProvider call(TrendQuery query) =>
      TrendProvider._(argument: query, from: this);

  @override
  String toString() => r'trendProvider';
}

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/dashboard_repository.dart';
import '../../domain/trend_summary.dart';
import '../../domain/yearly_summary.dart';

part 'yearly_summary_provider.g.dart';

/// Fetched once while the annual page is alive; disposed when it is popped.
@Riverpod(retry: _noRetry)
Future<int?> earliestTrendYear(Ref ref) async {
  final result = await ref
      .watch(dashboardRepositoryProvider)
      .fetchTrend(const TrendQuery.year());
  final trend = result.fold((failure) => throw failure, (value) => value);
  if (trend.buckets.isEmpty) return null;
  return trend.buckets
      .map((bucket) => bucket.year)
      .reduce((earliest, year) => year < earliest ? year : earliest);
}

@Riverpod(retry: _noRetry)
Future<YearlySummary> yearlySummary(Ref ref, int year) async {
  final earliestYear = await ref.watch(earliestTrendYearProvider.future);
  if (earliestYear == null) return YearlySummary.empty(year);

  final repository = ref.watch(dashboardRepositoryProvider);
  final trendFuture = repository.fetchTrend(TrendQuery.month(year));
  final summaryFuture = repository.fetchYearlySummary(year: year);
  final trendResult = await trendFuture;
  final summaryResult = await summaryFuture;

  final trend = trendResult.fold((failure) => throw failure, (value) => value);
  final summary = summaryResult.fold(
    (failure) => throw failure,
    (value) => value,
  );

  return YearlySummary(year: year, trend: trend, summary: summary);
}

Duration? _noRetry(int retryCount, Object error) => null;

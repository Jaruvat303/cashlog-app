import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/dashboard_repository.dart';
import '../../domain/trend_summary.dart';

part 'trend_providers.g.dart';

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
@Riverpod(keepAlive: true, retry: _noRetry)
Future<TrendSummary> trend(Ref ref, TrendQuery query) async {
  final result = await ref.watch(dashboardRepositoryProvider).fetchTrend(query);
  return result.fold((failure) => throw failure, (summary) => summary);
}

Duration? _noRetry(int retryCount, Object error) => null;

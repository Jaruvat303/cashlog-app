import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/dashboard/domain/trend_summary.dart';
import '../../features/dashboard/presentation/providers/dashboard_providers.dart';
import '../../features/dashboard/presentation/providers/trend_providers.dart';
import '../../features/transactions/presentation/providers/transactions_feed_providers.dart';

part 'cache_invalidator.g.dart';

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
///
/// F2: a mutation at (year, month) also changes that year's month-mode trend
/// buckets, and (since one year's total changed) the single year-mode entry
/// — so both ride along here too, on the same "invalidate, don't eagerly
/// refetch" semantics, rather than each of `invalidateMonth`'s four call
/// sites needing its own trend-invalidation call.
@riverpod
CacheInvalidator cacheInvalidator(Ref ref) => CacheInvalidator(ref);

class CacheInvalidator {
  CacheInvalidator(this._ref);

  final Ref _ref;

  void invalidateMonth(int year, int month) {
    _ref.invalidate(monthTransactionsProvider(year, month));
    _ref.invalidate(dashboardSummaryProvider(year, month));
    _ref.invalidate(trendProvider(TrendQuery.month(year)));
    _ref.invalidate(trendProvider(const TrendQuery.year()));
  }

  void invalidateMonths(Set<(int year, int month)> months) {
    for (final (year, month) in months) {
      invalidateMonth(year, month);
    }
  }
}

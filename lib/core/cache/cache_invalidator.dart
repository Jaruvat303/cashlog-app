import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/dashboard/presentation/providers/dashboard_providers.dart';
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
@riverpod
CacheInvalidator cacheInvalidator(Ref ref) => CacheInvalidator(ref);

class CacheInvalidator {
  CacheInvalidator(this._ref);

  final Ref _ref;

  void invalidateMonth(int year, int month) {
    _ref.invalidate(monthTransactionsProvider(year, month));
    _ref.invalidate(dashboardSummaryProvider(year, month));
  }

  void invalidateMonths(Set<(int year, int month)> months) {
    for (final (year, month) in months) {
      invalidateMonth(year, month);
    }
  }
}

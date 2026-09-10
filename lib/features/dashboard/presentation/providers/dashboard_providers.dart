import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/dashboard_repository.dart';
import '../../domain/dashboard_summary.dart';

part 'dashboard_providers.g.dart';

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
@Riverpod(retry: _noRetry)
Future<DashboardSummary> dashboardSummary(Ref ref, int year, int month) async {
  final result = await ref.watch(dashboardRepositoryProvider).fetchSummary(year: year, month: month);
  return result.fold((failure) => throw failure, (summary) => summary);
}

Duration? _noRetry(int retryCount, Object error) => null;

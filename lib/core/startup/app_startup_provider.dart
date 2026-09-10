import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/accounts/presentation/providers/accounts_providers.dart';
import '../../features/categories/presentation/providers/categories_providers.dart';

part 'app_startup_provider.g.dart';

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
@Riverpod(keepAlive: true)
Future<void> appStartup(Ref ref) async {
  // Riverpod forbids a provider from mutating another provider's state
  // while it's still synchronously "building" — and AccountsRefresh/
  // CategoriesRefresh.refresh() does exactly that (`state = AsyncLoading()`)
  // as its first line. Yielding once via a zero-duration delay before
  // touching them moves that call out of appStartup's own build phase, so
  // it's no longer a same-frame provider-modifies-provider violation.
  await Future<void>.delayed(Duration.zero);

  // Independent caches, no ordering dependency between them — run
  // concurrently. Both refresh methods already swallow failures into an
  // `Either` (never throw), so a startup sync failing offline can't crash
  // app boot; every screen reading these caches already renders whatever's
  // currently there (however stale/empty) without depending on this
  // succeeding.
  await Future.wait([
    ref.read(accountsRefreshProvider.notifier).refresh(),
    ref.read(categoriesRefreshProvider.notifier).refresh(),
  ]);
}

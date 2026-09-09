import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/accounts/presentation/pages/accounts_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/slip_scan/presentation/pages/slip_gallery_debug_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import 'app_shell.dart';

part 'app_router.g.dart';

/// No `initialLocation` override — go_router seeds the initial route from the
/// platform's `defaultRouteName`, which is what makes a deep link land on the
/// correct tab even after a hot restart (hot restart preserves that
/// platform-level route info; only a cold process kill resets it).
@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    routes: [
      // T9 debug tool, not one of the 4 bottom-nav tabs — deliberately
      // outside the StatefulShellRoute so it pushes as a normal screen
      // rather than becoming a 5th branch. Reachable only via the
      // kDebugMode-gated button in DashboardPage's AppBar.
      GoRoute(path: '/debug/slip-scan', builder: (context, state) => const SlipGalleryDebugPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/dashboard', builder: (context, state) => const DashboardPage())]),
          StatefulShellBranch(routes: [GoRoute(path: '/transactions', builder: (context, state) => const TransactionsPage())]),
          StatefulShellBranch(routes: [GoRoute(path: '/accounts', builder: (context, state) => const AccountsPage())]),
          StatefulShellBranch(routes: [GoRoute(path: '/categories', builder: (context, state) => const CategoriesPage())]),
        ],
      ),
    ],
    redirect: (context, state) => state.uri.path == '/' ? '/dashboard' : null,
  );
}

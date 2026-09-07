import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/accounts/presentation/pages/accounts_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
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

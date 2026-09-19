import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../features/slip_scan/presentation/widgets/manual_slip_attach_button.dart';
import '../theme/app_theme.dart';

/// Bottom nav scaffold for the 4 top-level tabs (mockup screens 1a/1b's nav
/// bar). Each branch keeps its own Navigator stack via
/// `StatefulShellRoute.indexedStack` in app_router.dart.
///
/// The mockup's 5th visual slot — the raised center camera button — isn't a
/// branch: it's [ManualSlipAttachButton] (T21's manual capture entry point,
/// moved here from the Transactions AppBar per the mockup, since the design
/// treats it as a single global entry point reachable from every tab, not a
/// per-page action) rendered as a [FloatingActionButton] and docked over the
/// nav bar via `centerDocked`, which — with exactly 4 destinations — lands
/// it dead center between "ดูสรุป" and "บัญชี", matching the mockup's layout
/// without needing a dummy 5th destination slot.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      floatingActionButton: const ManualSlipAttachButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        height: 74,
        backgroundColor: AppColors.surface,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        selectedIndex: currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: [
          _destination(RemixIcon.home5Line, RemixIcon.home5Fill, 'หน้าแรก', currentIndex == 0),
          _destination(RemixIcon.listCheck2, RemixIcon.listCheck2, 'ดูสรุป', currentIndex == 1),
          _destination(RemixIcon.wallet3Line, RemixIcon.wallet3Fill, 'บัญชี', currentIndex == 2),
          _destination(RemixIcon.moreLine, RemixIcon.moreFill, 'เพิ่มเติม', currentIndex == 3),
        ],
      ),
    );
  }

  NavigationDestination _destination(IconData icon, IconData selectedIcon, String label, bool selected) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return NavigationDestination(
      icon: Icon(icon, color: color),
      selectedIcon: Icon(selectedIcon, color: color),
      label: label,
    );
  }
}

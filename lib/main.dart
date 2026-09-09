import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/startup/app_startup_provider.dart';
import 'features/slip_scan/presentation/providers/slip_scan_lifecycle_provider.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Fire-and-forget: kicks off once for the whole app session regardless
    // of which bottom-nav tab builds first (see app_startup_provider.dart).
    // No screen needs to await this — each already renders whatever's
    // currently cached and updates reactively once this lands.
    ref.read(appStartupProvider);
    // T11: cold-start/resume scan triggers (spec §7.2) — all observer logic
    // lives in slip_scan_lifecycle_provider.dart, this is just the bootstrap
    // read, same pattern as appStartupProvider above.
    ref.read(slipScanLifecycleProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cashlog',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}

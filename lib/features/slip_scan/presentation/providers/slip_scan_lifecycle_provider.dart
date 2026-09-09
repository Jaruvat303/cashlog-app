import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'slip_scan_pipeline_provider.dart';

part 'slip_scan_lifecycle_provider.g.dart';

/// Wires spec §7.2's two scan triggers (cold start + resume) to T10's
/// `SlipScanPipeline.runScan()` — this provider owns no scan logic itself,
/// only *when* to call it (T10's pipeline internals are untouched). Doesn't
/// extend `State`/mix into a widget: a `WidgetsBindingObserver` only needs
/// to be registered with `WidgetsBinding.instance`, which works from a plain
/// object just as well, so this can live entirely under `slip_scan/`
/// instead of requiring a dedicated widget mounted somewhere in the tree.
///
/// `keepAlive: true` + reading this exactly once from `main.dart`'s
/// `initState()` (same bootstrap pattern as `appStartupProvider`) is what
/// makes this fire "regardless of which tab opens first" — same reasoning
/// as CLAUDE.md's App Startup section, extended to lifecycle resume.
@Riverpod(keepAlive: true)
Future<void> slipScanLifecycle(Ref ref) async {
  // slipScanPipelineProvider is plain `@riverpod` (autoDispose) — nothing
  // else keeps it alive except T10's debug page's own `ref.watch`, which
  // only holds while that page happens to be open. Without a listener here
  // too, whenever nothing else is watching it (the common case: user on any
  // other tab), it gets disposed the moment its listener count hits zero —
  // and `ref.read(...)` alone never counts as a listener. The *next*
  // `ref.read(slipScanPipelineProvider.notifier)` (e.g. a later resumed
  // trigger) then silently rebuilds a *fresh* `SlipScanPipeline`, whose
  // `state.isScanning` starts back at `false` — defeating T10's
  // re-entrancy guard for exactly the case this ticket's DoD cares about
  // (a resume firing while a scan triggered moments earlier is still
  // mid-flight). `ref.listen` (not `ref.watch`) is what's needed: it
  // subscribes, keeping the provider alive for this provider's own
  // `keepAlive: true` lifetime, without making *this* provider rebuild
  // every time scan progress changes (which `ref.watch` would). Found via
  // a failing test, not by inspection — see main_test.dart's "resume
  // firing while mid-flight" case.
  ref.listen(slipScanPipelineProvider, (previous, next) {});

  final observer = _SlipScanLifecycleObserver(ref);
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() => WidgetsBinding.instance.removeObserver(observer));

  // Riverpod forbids a provider from mutating another provider's state
  // while it's still synchronously "building" — and `runScan()`'s very
  // first line does exactly that (claims `isScanning` via a synchronous
  // `state = ...` write, before its own first `await`). Same fix, same
  // reasoning as `app_startup_provider.dart`'s identical yield: moving the
  // call out of this provider's own build phase via a zero-duration delay
  // is what makes it no longer a same-frame provider-modifies-provider
  // violation.
  await Future<void>.delayed(Duration.zero);

  // Cold start (spec §7.2's first trigger). Fire-and-forget, same as
  // appStartupProvider — no screen awaits this, everything already renders
  // from cache and updates reactively if/when this lands.
  ref.read(slipScanPipelineProvider.notifier).runScan();
}

/// A plain `WidgetsBindingObserver`, not a `State` — registering with
/// `WidgetsBinding.instance` doesn't require being part of the widget tree.
/// [didChangeAppLifecycleState] fires for every transition; only `resumed`
/// (spec §7.2's second trigger) re-triggers a scan. `SlipScanPipeline.
/// runScan()`'s own re-entrancy guard (claims `isScanning` synchronously
/// before any `await`) is what keeps a `resumed` event firing right on top
/// of the cold-start trigger above from causing a double scan — not
/// duplicated here.
class _SlipScanLifecycleObserver extends WidgetsBindingObserver {
  _SlipScanLifecycleObserver(this._ref);

  final Ref _ref;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ref.read(slipScanPipelineProvider.notifier).runScan();
    }
  }
}

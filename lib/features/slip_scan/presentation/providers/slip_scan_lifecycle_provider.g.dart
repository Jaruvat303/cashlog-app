// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slip_scan_lifecycle_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(slipScanLifecycle)
final slipScanLifecycleProvider = SlipScanLifecycleProvider._();

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

final class SlipScanLifecycleProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
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
  SlipScanLifecycleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'slipScanLifecycleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$slipScanLifecycleHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return slipScanLifecycle(ref);
  }
}

String _$slipScanLifecycleHash() => r'2e71413387b8ea5c3148d546f1dd6577c826696d';

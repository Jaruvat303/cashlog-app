// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_month_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The month/year that drives both the transaction feed (T7) and the
/// dashboard summary (T8) — lives in `core/` (moved here from
/// `transactions/presentation/providers/` as T7's own comment anticipated)
/// so neither feature reaches into the other's presentation layer to share
/// it (CLAUDE.md: no cross-feature layer sharing except through
/// `core/`/`shared/`).
///
/// `keepAlive: true` so the selection survives switching away to another
/// bottom-nav tab and back.

@ProviderFor(SelectedMonth)
final selectedMonthProvider = SelectedMonthProvider._();

/// The month/year that drives both the transaction feed (T7) and the
/// dashboard summary (T8) — lives in `core/` (moved here from
/// `transactions/presentation/providers/` as T7's own comment anticipated)
/// so neither feature reaches into the other's presentation layer to share
/// it (CLAUDE.md: no cross-feature layer sharing except through
/// `core/`/`shared/`).
///
/// `keepAlive: true` so the selection survives switching away to another
/// bottom-nav tab and back.
final class SelectedMonthProvider
    extends $NotifierProvider<SelectedMonth, DateTime> {
  /// The month/year that drives both the transaction feed (T7) and the
  /// dashboard summary (T8) — lives in `core/` (moved here from
  /// `transactions/presentation/providers/` as T7's own comment anticipated)
  /// so neither feature reaches into the other's presentation layer to share
  /// it (CLAUDE.md: no cross-feature layer sharing except through
  /// `core/`/`shared/`).
  ///
  /// `keepAlive: true` so the selection survives switching away to another
  /// bottom-nav tab and back.
  SelectedMonthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedMonthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedMonthHash();

  @$internal
  @override
  SelectedMonth create() => SelectedMonth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$selectedMonthHash() => r'53fc0be47f380cba3a1f2d61830381f314487945';

/// The month/year that drives both the transaction feed (T7) and the
/// dashboard summary (T8) — lives in `core/` (moved here from
/// `transactions/presentation/providers/` as T7's own comment anticipated)
/// so neither feature reaches into the other's presentation layer to share
/// it (CLAUDE.md: no cross-feature layer sharing except through
/// `core/`/`shared/`).
///
/// `keepAlive: true` so the selection survives switching away to another
/// bottom-nav tab and back.

abstract class _$SelectedMonth extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

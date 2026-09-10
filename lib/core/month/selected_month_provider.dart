import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_month_provider.g.dart';

/// The month/year that drives both the transaction feed (T7) and the
/// dashboard summary (T8) — lives in `core/` (moved here from
/// `transactions/presentation/providers/` as T7's own comment anticipated)
/// so neither feature reaches into the other's presentation layer to share
/// it (CLAUDE.md: no cross-feature layer sharing except through
/// `core/`/`shared/`).
///
/// `keepAlive: true` so the selection survives switching away to another
/// bottom-nav tab and back.
@Riverpod(keepAlive: true)
class SelectedMonth extends _$SelectedMonth {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime.utc(now.year, now.month);
  }

  /// `DateTime.utc(year, month +/- 1)` normalizes the Dec/Jan year rollover
  /// on its own — no manual carry needed either direction.
  void next() => state = DateTime.utc(state.year, state.month + 1);

  void previous() => state = DateTime.utc(state.year, state.month - 1);
}

const List<String> _kMonthNames = [
  'January', 'February', 'March', 'April', 'May', 'June', //
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Shared by `TransactionsPage` and `DashboardPage` so both month selectors
/// render the exact same label for the exact same shared [SelectedMonth].
String monthYearLabel(DateTime month) => '${_kMonthNames[month.month - 1]} ${month.year}';

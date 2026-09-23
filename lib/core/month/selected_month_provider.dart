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

  /// Jumps directly to a given year/month — backs the Home/Summary
  /// month-year picker dropdown (mockup: tapping a month in the grid), as
  /// opposed to [next]/[previous]'s one-step-at-a-time arrows.
  void set(int year, int month) => state = DateTime.utc(year, month);
}

const List<String> _kMonthNames = [
  'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน', //
  'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
];

const List<String> _kMonthAbbreviationsTh = [
  'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', //
  'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
];

/// Thai calendar convention: Buddhist Era = Gregorian year + 543.
int buddhistYear(int gregorianYear) => gregorianYear + 543;

/// Shared by `TransactionsPage` and `DashboardPage` so both month selectors
/// render the exact same label for the exact same shared [SelectedMonth] —
/// full Thai month name + Buddhist-era year, matching the mockup
/// ("สิงหาคม 2569").
String monthYearLabel(DateTime month) =>
    '${_kMonthNames[month.month - 1]} ${buddhistYear(month.year)}';

/// Short form used for the Transactions header chip ("ส.ค. 2569").
String monthYearShortLabel(DateTime month) =>
    '${_kMonthAbbreviationsTh[month.month - 1]} ${buddhistYear(month.year)}';

/// Short Thai month abbreviation for a 1-indexed [month] — backs the
/// Summary Topbar's month+year picker grid (post-launch UI polish ticket
/// 07), which needs the abbreviation independent of any particular year.
String monthAbbreviationTh(int month) => _kMonthAbbreviationsTh[month - 1];

/// Mockup screen 1b's date-group headers: "วันนี้"/"เมื่อวาน" for the two most
/// recent days, a full Thai short date otherwise. Compares by
/// year/month/day only — [date] may carry a time-of-day component.
String relativeDayLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = today.difference(target).inDays;
  if (diff == 0) return 'วันนี้';
  if (diff == 1) return 'เมื่อวาน';
  return '${date.day} ${_kMonthAbbreviationsTh[date.month - 1]} ${buddhistYear(date.year)}';
}

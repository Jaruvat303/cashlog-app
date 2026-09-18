import '../../core/month/selected_month_provider.dart';

/// Ticket 09: "readable date/time text" for the on-device-only last
/// successful auto-scan upload signal. Reuses `relativeDayLabel`'s existing
/// Thai vocabulary ("วันนี้"/"เมื่อวาน") — the same one the transaction feed's
/// day-group headers already use — plus a 24h time-of-day suffix, since a
/// bare day label alone can't distinguish "a few minutes ago" from "this
/// morning" for a status readout meant to catch a stalled background scan.
String dateTimeLabel(DateTime dateTime) {
  final local = dateTime.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${relativeDayLabel(local)} $hour:$minute น.';
}

/// Client-side mirror of the backend's `ErrTransferSameAccount` rule (spec
/// §4) — checked before any request is sent, so a bad transfer never makes
/// a round trip just to be rejected. Returns `null` while the form is still
/// mid-entry (either side unset) rather than erroring early.
String? validateTransferAccounts(int? fromAccountId, int? toAccountId) {
  if (fromAccountId == null || toAccountId == null) return null;
  if (fromAccountId == toAccountId) return 'Source and destination account must be different';
  return null;
}

/// T14/CLAUDE.md's cache-invalidation rule: a create (`originalDate` null)
/// or an edit that keeps the same month only touches that one month; an
/// edit that moves `transaction_date` across a month boundary must
/// invalidate both the old and the new month.
Set<(int year, int month)> monthsAffectedByEdit(DateTime? originalDate, DateTime newDate) {
  if (originalDate != null && (originalDate.year != newDate.year || originalDate.month != newDate.month)) {
    return {(originalDate.year, originalDate.month), (newDate.year, newDate.month)};
  }
  return {(newDate.year, newDate.month)};
}

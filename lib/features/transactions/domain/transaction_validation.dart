/// Client-side mirror of the backend's `ErrTransferSameAccount` rule (spec
/// §4) — checked before any request is sent, so a bad transfer never makes
/// a round trip just to be rejected. Returns `null` while the form is still
/// mid-entry (either side unset) rather than erroring early.
String? validateTransferAccounts(int? fromAccountId, int? toAccountId) {
  if (fromAccountId == null || toAccountId == null) return null;
  if (fromAccountId == toAccountId) return 'Source and destination account must be different';
  return null;
}

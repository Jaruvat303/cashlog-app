# cashlog-app: Bug Fixes, List/Edit Redesign & Slip Preview — Tickets

Source spec: `cashlog-app-fixes-spec.md`. 8 tickets total; work the frontier — tickets with no blockers can all start in parallel, ticket 08 is the only one gated.

---

### `01` — Fix income categories not syncing

**Parent**: cashlog-app-fixes-spec.md § Bug 2

**What to build**: Opening the Categories screen shows income categories alongside expense categories, and the category dropdown on an income transaction (new or edit) lists them too.

**Acceptance criteria**:
- [ ] Category sync fetches both income and expense categories (not just the implicit default) and both end up in the local cache
- [ ] Categories screen lists income categories the user has created in the backend
- [ ] Creating or editing an income transaction shows income categories in the category dropdown
- [ ] Existing expense-category behavior is unchanged

**Blocked by**: None — can start immediately

---

### `02` — Show pending-sync status on transaction rows

**Parent**: cashlog-app-fixes-spec.md § Bug 3 follow-up

**What to build**: A transaction row whose create/update/delete failed transiently and is sitting in the retry queue shows a small "pending sync" indicator, so a delete/edit that silently queued no longer looks identical to one that succeeded. The indicator disappears once the queued action is retried successfully from the Pending Actions page.

**Acceptance criteria**:
- [ ] A transaction with an open queued action shows the pending-sync indicator in the transaction list
- [ ] A transaction with no queued action shows no indicator
- [ ] Successfully retrying the queued action from the Pending Actions page removes the indicator
- [ ] No change to when/how actions get queued or retried — this is display-only

**Blocked by**: None — can start immediately

---

### `03` — Category picker sheet: scroll instead of resize

**Parent**: cashlog-app-fixes-spec.md § Design 2

**What to build**: The half-screen quick category-assign sheet stays half-screen height when the category list overflows it, and becomes scrollable (with a visible scrollbar) instead of growing or clipping content.

**Acceptance criteria**:
- [ ] Sheet height is unchanged from today (still half-screen) regardless of category count
- [ ] A category list too long to fit is reachable via scroll
- [ ] A scrollbar is visible during scroll
- [ ] Selecting a category still closes the sheet and assigns it, same as today

**Blocked by**: None — can start immediately

---

### `04` — Transaction list: tap row to edit, move delete into edit page

**Parent**: cashlog-app-fixes-spec.md § Design 1

**What to build**: Tapping anywhere on a transaction row (junk or normal) opens its edit page directly, with no separate edit/delete icons on the row itself. Deleting a transaction is now done from a delete action on the edit page, using the same confirmation dialog and delete flow that exists today.

**Acceptance criteria**:
- [ ] Tapping a transaction row (junk or non-junk) opens the edit page for that transaction
- [ ] No edit or delete icon remains on any transaction row
- [ ] The edit page shows a delete action only when editing an existing transaction (not when creating a new one)
- [ ] Delete on the edit page shows the same confirmation dialog copy as today, and on confirm performs the same delete + cache-invalidation + pending-queue-on-transient-failure behavior as today
- [ ] Category and Account management screens are unaffected

**Blocked by**: None — can start immediately

---

### `05` — Show the original slip image on the transaction edit page

**Parent**: cashlog-app-fixes-spec.md § Addition

**What to build**: Opening the edit page for a transaction that came from a scanned slip shows the original slip screenshot, looked up live from the device's photo library by filename. A transaction with no associated slip, or one whose slip image can no longer be found on-device, shows a "no image" placeholder instead — never an error or a stuck loading state.

**Acceptance criteria**:
- [ ] A transaction with a slip filename that still matches a file in the configured albums shows that image on the edit page
- [ ] A transaction with no slip filename shows the "no image" placeholder immediately, with no gallery query attempted
- [ ] A transaction whose slip filename no longer matches anything (renamed, moved, deleted) shows the "no image" placeholder, not an error
- [ ] No backend or schema changes; the lookup is on-device only and re-run each time the edit page opens (no caching required)

**Blocked by**: None — can start immediately

---

### `06` — Home page: gallery-permission banner + attention feed

**Parent**: cashlog-app-fixes-spec.md § Bug 1, Design 3 (Home half)

**What to build**: The Dashboard/Home tab stops showing the pie chart and instead shows, at the top, a banner when photo-library access needs the user's attention (fully denied, or limited access without the bank screenshot albums included) with a button to fix it in place; below that, a feed of transactions that still need attention (primarily scanned transactions still missing a category).

**Acceptance criteria**:
- [ ] With full photo access already granted, no permission banner appears
- [ ] With access denied, a banner appears explaining why and offering a button that triggers the system permission request
- [ ] With limited access that excludes the configured bank-screenshot albums, a banner appears offering a button that opens the OS's "manage selected photos" picker
- [ ] Below the banner (or at the top, if no banner), the Home tab lists transactions needing attention (junk / missing category), most recent first
- [ ] Auto-scan on cold start and app resume continues to work exactly as today — this ticket only adds visible entry points to permission actions that already exist in code, it doesn't change the scan trigger logic
- [ ] The old pie-chart summary is removed from this page (it is not deleted from the codebase — see ticket 07 — just no longer shown here)

**Blocked by**: None — can start immediately

---

### `07` — Transaction List: Income & Expense summary tabs with drill-through

**Parent**: cashlog-app-fixes-spec.md § Design 3 (summary half)

**What to build**: The Transaction List page gains a summary section above the list with Income/Expense/Transfer tabs (Transfer tab itself is ticket 08). The Income and Expense tabs each show a list of categories with their total amounts for the current scope; tapping a category filters the transaction list below to just that category's transactions.

**Acceptance criteria**:
- [ ] Transaction List page shows a tabbed summary section (Income / Expense / Transfer tabs present, Transfer tab may be a placeholder for this ticket)
- [ ] Income tab lists income categories with correct total amounts for the current month/scope
- [ ] Expense tab lists expense categories with correct total amounts for the current month/scope
- [ ] Category names are shown as text in the list rows (not as pie-chart labels)
- [ ] Tapping a category row filters the transaction list below to only that category's transactions
- [ ] A way exists to clear the filter and return to the unfiltered transaction list
- [ ] Figures match what the existing dashboard summary data source already returns (no new backend calls)

**Blocked by**: None — can start immediately

---

### `08` — Transaction List: Transfer summary tab

**Parent**: cashlog-app-fixes-spec.md § Design 3 (summary half)

**What to build**: The Transfer tab (added as a placeholder in ticket 07) shows a flat, ungrouped list of the current scope's transfer transactions — no grouping by account pair, no per-row total beyond what's already on each transaction.

**Acceptance criteria**:
- [ ] Transfer tab shows every transfer transaction for the current month/scope
- [ ] No grouping or aggregation by account pair (or any other dimension) is applied
- [ ] Switching between Income/Expense/Transfer tabs preserves each tab's own state (filter, scroll position) independently

**Blocked by**: `07` — Transaction List: Income & Expense summary tabs with drill-through (adds the third tab to the tab shell that ticket introduces)

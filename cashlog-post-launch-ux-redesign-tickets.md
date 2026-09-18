# Cashlog Post-Launch UX & Navigation Redesign — Tickets

Eleven tracer-bullet tickets implementing [`cashlog-post-launch-ux-redesign-spec.md`](./cashlog-post-launch-ux-redesign-spec.md) (ticket 11 was discovered mid-implementation, not part of the original scope — see its own note). Work the frontier: tickets with no blockers can start immediately, in any order, in parallel.

**Status as of this write-up**: `01` done directly by Jar. `03` has been implemented and verified (wired in, tests passing). `02` was reported as implemented as a patch during a prior session but not yet confirmed applied to Jar's working tree — treat it as done only once verified, not by default.

---

### `01` — Allow transaction type change on update

**Parent**: [spec](./cashlog-post-launch-ux-redesign-spec.md).

**What to build**: Editing an existing transaction and changing its type (e.g. expense → transfer, transfer → income) saves successfully end-to-end, with the right fields required/cleared for the new type.

**Acceptance criteria**:
- [x] Changing a transaction's type to `transfer` during edit succeeds when `from_account_id` and `to_account_id` are provided and differ; `category_id` is cleared on save.
- [x] Changing a transaction's type to `income` or `expense` during edit succeeds when `category_id` and a single `account_id` are provided; `from_account_id`/`to_account_id` are cleared on save.
- [x] The existing validation error (400, `INVALID_INPUT_PARAMETERS`) still fires for genuinely invalid combinations (e.g. `from_account_id == to_account_id`), unchanged from today.
- [x] No stored-balance migration step is needed or added, since balances are computed dynamically.
- [x] A user can go into the edit screen, change type from expense to transfer, fill in the transfer fields, save, and see it persisted correctly with no popup error.

**Blocked by**: None. **Status**: Done.

---

### `02` — Fix income category icons

**Parent**: [spec](./cashlog-post-launch-ux-redesign-spec.md).

**What to build**: Each income category shows its own distinct icon instead of the same fallback icon.

**Acceptance criteria**:
- [ ] The icon resolver maps all 10 real income `icon_key` values (`wallet-3-fill`, `gift-fill`, `tools-fill`, `store-2-fill`, `line-chart-fill`, `trophy-fill`, `key-2-fill`, `hand-heart-fill`, `coins-fill`, `money-dollar-circle-fill`) to distinct, correct icons — none fall through to the generic fallback icon.
- [ ] Any key that doesn't exist verbatim in the icon library in use (e.g. `coins-fill`) is aliased to the closest real icon, following the existing precedent elsewhere in the codebase for a prior similar mismatch.
- [ ] The category create/edit icon picker offers these same 10 icons as choices for income categories going forward, and only income icons when the category's type is income (expense icons only for expense) — not a single mixed list.
- [ ] No backend change is made — this is a frontend-only fix.
- [ ] Viewing the categories list or any transaction list with income categories shows visibly different icons per category.

**Blocked by**: None. **Status**: Implemented as a patch this session — apply and verify before treating as done.

---

### `03` — Restore Pie Chart on the Summary page

**Parent**: [spec](./cashlog-post-launch-ux-redesign-spec.md).

**What to build**: The category Pie Chart is visible again on the summary view for both income and expense tabs, sitting above the existing category text list (not replacing it), with small slices decluttered from the legend.

**Acceptance criteria**:
- [x] The existing (previously unused) pie-chart component is wired into both the income and expense summary tabs, showing real category-breakdown data for the selected month.
- [x] The existing category text list stays below the chart, unchanged, including its existing tap-to-filter behavior.
- [x] Any category whose share is under 10% of the total has its entire legend row (icon, name, percentage) omitted from the chart's legend.
- [x] The chart's slices always sum to a full circle representing true proportions, regardless of which legend rows are hidden.

**Blocked by**: None. **Status**: Done.

---

### `04` — Summary page consolidation ("รายการ" → "ดูสรุป")

**Parent**: [spec](./cashlog-post-launch-ux-redesign-spec.md).

**What to build**: The tab currently labeled "รายการ" is relabeled "ดูสรุป" and reorganized to match what it actually is — a summary page — gaining the account-info strip (moved off Home) and a centered AppBar month switcher, and losing its now-redundant manual-entry button.

**Acceptance criteria**:
- [ ] The bottom-nav label reads "ดูสรุป" instead of "รายการ"; the route/page identity is otherwise unchanged.
- [ ] The account-info strip is removed from the Home page and now renders on this page.
- [ ] The month switcher moves from the AppBar's secondary row into the center of the main AppBar row.
- [ ] The page-level "+" (manual transaction entry) button is removed from this page's AppBar.
- [ ] Switching months here still correctly updates the account info, the summary tabs, and the list below.

**Blocked by**: None — can start immediately.

---

### `05` — Replace camera FAB with create-menu FAB

**Parent**: [spec](./cashlog-post-launch-ux-redesign-spec.md).

**What to build**: The bottom navigation's central camera button is replaced with a single FAB that opens a choice of three actions: create a transaction manually, pick a slip photo from the gallery, or take a slip photo.

**Acceptance criteria**:
- [ ] Tapping the FAB from any tab opens a menu with exactly these three options.
- [ ] "Create manually" opens the existing manual transaction entry screen.
- [ ] "Pick from gallery" and "Take photo" continue to feed the existing OCR slip-upload pipeline, unchanged in behavior from today's camera button.
- [ ] The camera-only FAB is fully removed; there is one FAB, reachable from every tab.

**Blocked by**: None — can start immediately.

---

### `06` — Home becomes the full monthly transaction ledger

**Parent**: [spec](./cashlog-post-launch-ux-redesign-spec.md).

**What to build**: The Home page's transaction list shows every transaction for the selected month (not just ones needing attention), grouped by day, defaulting to the current month on open — matching the query/pagination model already used by the summary page's list.

**Acceptance criteria**:
- [ ] Home's list is backed by the same full, paginated, per-month transaction query the summary page uses, not the "needs attention" filtered query.
- [ ] Transactions are grouped by day within the selected month.
- [ ] Opening the app lands on the current month by default.
- [ ] Assigning a category to a transaction no longer removes it from the list — it stays visible with its new category shown.
- [ ] The account-info strip is not present on this page (already moved in ticket 04).

**Blocked by**: `04` — Summary page consolidation (must remove account info from Home first so this ticket only touches the list).

---

### `07` — Home: this-month expense-total widget with built-in month switcher

**Parent**: [spec](./cashlog-post-launch-ux-redesign-spec.md).

**What to build**: A widget on Home showing this month's total expenses as a plain number, with the month switcher (moved off Home's AppBar title) folded into the same widget.

**Acceptance criteria**:
- [ ] The widget displays the total expense amount for the currently selected month as a number only (no chart, no breakdown).
- [ ] The month switcher (prev/next + label) lives inside this widget instead of in Home's AppBar title.
- [ ] Changing the month via this widget updates the widget's total and the transaction list below it together.
- [ ] The widget sits above the transaction list.

**Blocked by**: `06` — Home ledger rebuild.

---

### `08` — Home: pending-items banner

**Parent**: [spec](./cashlog-post-launch-ux-redesign-spec.md).

**What to build**: A small single-line banner on Home showing the count of transactions still needing attention (junk/uncategorized), linking to the existing pending-actions page.

**Acceptance criteria**:
- [ ] The banner shows a live count sourced from the existing pending-actions query.
- [ ] The banner sits beneath the expense-total widget and above the transaction list.
- [ ] Tapping the banner opens the existing pending-actions page, unchanged.
- [ ] No duplicate count/badge is added anywhere else on Home.
- [ ] The banner is hidden or shows a zero/empty state when there are no pending items (no dead space or confusing "0" left prominently displayed — implementer's discretion on exact empty treatment, consistent with the rest of the app's empty states).

**Blocked by**: `06` — Home ledger rebuild.

---

### `09` — Auto-scan: last successful upload timestamp

**Parent**: [spec](./cashlog-post-launch-ux-redesign-spec.md).

**What to build**: A local (device-only) timestamp tracking the last time the background auto-scan pipeline successfully uploaded a slip, displayed as text on Home.

**Acceptance criteria**:
- [ ] The timestamp updates only when a slip upload inside the auto-scan pipeline resolves as successfully uploaded (a genuinely new, successfully-processed slip).
- [ ] The timestamp does NOT update when a scan cycle runs but finds no new files, and does NOT update on manually-created transactions.
- [ ] The timestamp is persisted locally on the device (no backend column, no sync).
- [ ] Home displays this timestamp as readable date/time text.
- [ ] If auto-scan runs repeatedly with no new slips, the displayed timestamp stays fixed at its last real success, visibly not advancing.

**Blocked by**: `06` — Home ledger rebuild.

---

### `10` — Home: live auto-scan processing indicator

**Parent**: [spec](./cashlog-post-launch-ux-redesign-spec.md).

**What to build**: A live indicator on Home showing progress while the background auto-scan pipeline is uploading slips (e.g. "processing 2/5"), briefly holding a completion state before disappearing.

**Acceptance criteria**:
- [x] While auto-scan is active, the indicator shows current progress (completed count / total count) sourced from the existing slip-scan-progress state.
- [x] When the batch finishes, the indicator shows a brief completion state (e.g. "5 done") for a few seconds before clearing.
- [x] When auto-scan is idle, no indicator is shown.
- [x] The indicator reflects both auto-scan batches and any manual gallery/photo uploads triggered from the new FAB (ticket 05), since both go through the same upload state.

**Blocked by**: `06` — Home ledger rebuild. **Status**: Done.

---

### `11` — Backend: accept icon_key/color_hex on Create/Update Category

**Parent**: [spec](./cashlog-post-launch-ux-redesign-spec.md) (discovered during ticket 02 implementation, not in the original scope).

**What to build**: The Create/Update Category API accepts `icon_key` and `color_hex` as real input fields and persists them, so the app's existing category create/edit icon-and-color picker actually takes effect instead of being silently discarded.

**Acceptance criteria**:
- [ ] Create Category accepts an optional `icon_key`/`color_hex`; when provided, both are persisted on the new category. When omitted, behavior is unchanged from today.
- [ ] Update Category accepts optional `icon_key`/`color_hex` the same way, updating only the fields provided.
- [ ] A malformed `color_hex` is rejected with the existing `INVALID_INPUT_PARAMETERS` error contract; `icon_key` is accepted as a plain string with no backend-side whitelist.
- [ ] Creating a category in the app with a chosen icon/color, then re-fetching it, shows the same icon/color the user picked — not a default.
- [ ] Editing an existing category's icon/color in the app persists correctly and survives a re-fetch.

**Blocked by**: None — can start immediately.

# Cashlog Post-Launch UX & Navigation Redesign — Spec

2026-09-17 · Jar

## Problem Statement

After using cashlog-app in real day-to-day tracking, Jar hit four concrete system problems and identified five navigation/layout changes plus two new features that would make the app fit how they actually use it:

- Editing a transaction to change its type to "transfer" fails with an "Invalid Parameter" popup — the app lets the user attempt this, but there's no way to actually save it.
- Every income category renders with the exact same icon, even though each one is visually distinct in concept (salary vs. bonus vs. rental income, etc.).
- The category Pie Chart that used to exist on the summary view disappeared during a previous redesign and was never brought back — a past redesign misunderstood the spec and dropped it.
- The Home page's transaction list is a "needs attention" queue: once a transaction gets a category assigned, it vanishes from the list. Jar wants Home to instead be a reliable, complete transaction list grouped by month, so it behaves like a proper ledger rather than a disappearing to-do list.
- The bottom navigation's camera button, the "รายการ" (List) tab's real purpose, the month switcher's location, and the account info's placement don't match how Jar actually uses the app day to day.
- Jar has no visibility into whether the app is actively saving/processing something, and no way to tell whether the background slip auto-scan is actually still working.

## Solution

A combined bug-fix + navigation redesign of cashlog-app:

- **Backend**: allow `UpdateTransaction` to change a transaction's type (income/expense/transfer), clearing/populating the fields each type requires. Separately, allow `CreateCategory`/`UpdateCategory` to accept `icon_key`/`color_hex`, since the app's category icon/color picker currently submits both and has them silently discarded.
- **Frontend**: turn the Home tab into the real all-transactions ledger (single month + arrows, grouped by day within the month, defaulting to the current month), and turn the "รายการ" tab into what it already functionally is — a summary view — renaming it "ดูสรุป" and giving it the restored Pie Chart, the account info strip, and a centered month switcher in its AppBar.
- Replace the bottom-nav camera FAB with a single FAB offering a choice of manual entry / pick from gallery / take photo, removing the now-redundant page-level "+" button.
- Fix the income category icon gap by teaching the icon resolver and picker about the 10 real `icon_key` values the backend already returns for income categories.
- Add three small always-visible status/awareness pieces to Home: a this-month expense total widget (with the month switcher folded into it), a "last successful auto-scan upload" timestamp, and a small pending-items banner; plus a live "processing N/M slips" indicator while the background auto-scan pipeline runs.

## User Stories

1. As Jar, I want to change a transaction's type from expense to transfer (or any other type) when editing it, so that I can correct a mis-categorized entry without deleting and recreating it.
2. As Jar, I want changing a transaction's type during edit to correctly clear the fields the old type required and populate the fields the new type requires, so that the data stays consistent (e.g. no leftover `category_id` on a transfer).
3. As Jar, I want each income category to show its own distinct icon, so that I can visually scan my income sources the same way I already can for expenses.
4. As Jar, I want the category Pie Chart back on the summary view for both income and expense tabs, so that I can see my spending/earning distribution at a glance, not just as a text list.
5. As Jar, I want each pie slice's legend row hidden when it's under 10% of the total, so that the legend doesn't get cluttered with tiny slivers.
6. As Jar, I want the pie chart's slices to still represent true proportions (summing to 100%) even when some legend rows are hidden, so that the chart itself never looks wrong.
7. As Jar, I want the Home page to show every transaction for the selected month, grouped by day, so that assigning a category to a transaction no longer makes it disappear.
8. As Jar, I want Home to default to the current month every time I open the app, so that I land on the most relevant view without extra navigation.
9. As Jar, I want a small banner on Home telling me how many transactions still need attention (junk/uncategorized), so that I don't lose visibility into that just because Home is no longer a filtered queue.
10. As Jar, I want tapping that banner to take me to the existing pending-actions page, so that I can resolve those items the same way I do today.
11. As Jar, I want the bottom navigation's camera button replaced with a single button that lets me create a transaction manually, so that I have quick access to manual entry without it being mistaken for the OCR/slip flow.
12. As Jar, I want that same button to still offer "pick from gallery" and "take photo" as secondary options, so that I don't lose the ability to manually attach a slip that the background auto-scan missed.
13. As Jar, I want the account info that currently lives on Home moved to the "ดูสรุป" (summary) page, so that Home can focus purely on the transaction ledger.
14. As Jar, I want the "รายการ" tab renamed to "ดูสรุป", so that its label matches what it actually shows (a summary), not a raw list.
15. As Jar, I want the redundant "+" button removed from the summary page's AppBar now that the same action is available from the global FAB, so that the UI isn't cluttered with two buttons that do the same thing.
16. As Jar, I want the summary page's month switcher moved into the middle of the actual AppBar (not a secondary row below it), so that it's consistent with how Home's month switcher is already positioned.
17. As Jar, I want a widget on Home showing this month's total expenses as a plain number, so that I can see my spending at a glance without opening the summary page.
18. As Jar, I want the month switcher for Home folded into that same expense-total widget, so that switching months and seeing the total live in one place.
19. As Jar, I want a text on Home showing the date and time of the last successful auto-scan upload, so that I can tell at a glance whether the background scanning pipeline is still working.
20. As Jar, I want that timestamp to update only when a slip is actually uploaded successfully by auto-scan — not just when a scan cycle runs and finds nothing new, and not when I create a transaction manually — so that a stale timestamp reliably means auto-scan has stopped working.
21. As Jar, I want to see a live indicator (e.g. "processing 2/5") while the background auto-scan pipeline is uploading slips, so that I know the app is actively working and not stuck.
22. As Jar, I want that indicator to briefly show a completion state (e.g. "5 done") for a few seconds before disappearing, so that I have confidence the batch actually finished.
23. As Jar, I want the icon and color I pick when creating or editing a category to actually be saved, so that the picker in the app isn't just a cosmetic no-op.

## Inplementation Decisions

**Backend — transaction type change on update**

- Extend the update-transaction use case/DTO to accept a `transaction_type` change.
- When the new type is `transfer`: require `from_account_id` and `to_account_id` (with `from_account_id != to_account_id`), and clear `category_id`.
- When the new type is `income` or `expense`: require `category_id` and a single `account_id`, and clear `from_account_id`/`to_account_id`.
- Account balances are computed dynamically (not stored), so a type change on an existing transaction does not require any balance-migration step.
- The existing validation error contract (400, `INVALID_INPUT_PARAMETERS`) stays as the failure mode for genuinely invalid combinations; it should no longer fire for a well-formed type change.

**Backend — accept icon\_key/color\_hex on Create/Update Category**

- Discovered mid-implementation: the Create/Update Category API currently only accepts `name`/`type`; the client already sends `icon_key`/`color_hex` in both calls today, and the backend silently drops them. All 30 existing categories got their icon/color from a direct DB seed, never through this API.
- Extend both DTOs to accept optional `icon_key`/`color_hex`; omitted stays as today's default behavior.
- Validate `color_hex` as a `#RRGGBB` string when provided, rejecting malformed values with the existing `INVALID_INPUT_PARAMETERS` contract.
- Accept `icon_key` as a plain string with no backend-side enum/whitelist — the client already tolerates an unrecognized key by falling back to a generic icon, so the backend doesn't need to police the value.

**Frontend — Home page**

- Replace the "needs attention" filtered query backing Home's list with the same full, paginated, per-month transaction query the summary page already uses (grouped by day within the month), defaulting to the current month on open.
- Add an expense-total-this-month widget above the list; fold the month switcher (currently in Home's AppBar title) into this widget.
- Add a local-only (device-persisted, not backend) "last successful auto-scan upload" timestamp, updated only on a successful upload result inside the auto-scan pipeline — not on scan cycles that find no new files, and not on manual transaction creation.
- Add a small single-line pending-items banner beneath the expense-total widget and above the transaction list, showing the count from the existing pending-actions query; tapping it opens the existing pending-actions page. No duplicate badge/count elsewhere on Home.
- Add a live processing indicator driven by the existing slip-scan-progress state (already exposes scanning flag, total, completed count, current filename); hold the completed state on screen briefly before clearing.

**Frontend — Summary page ("ดูสรุป", formerly "รายการ")**

- Rename the NavBar label from "รายการ" to "ดูสรุป"; no change to the route/page identity itself.
- Move the account-info strip from Home onto this page.
- Move the month switcher out of the AppBar's secondary row and into the center of the main AppBar row.
- Remove the page-level "+" (manual entry) button now that the global FAB covers the same action.
- Reinstate the existing (already-built, currently unused) category pie-chart component into the income/expense summary tabs, positioned above the existing category text list — the list stays, it isn't replaced, and its existing tap-to-filter behavior is preserved.
- In the pie chart's legend, omit the row entirely (icon, name, and percentage) for any category under 10% of the total; the chart's slices continue to reflect true proportions regardless of which legend rows are shown.

**Frontend — global navigation**

- Replace the bottom-nav camera FAB with a FAB that opens a choice menu: create transaction manually, pick a slip from gallery, take a slip photo. The manual-create option opens the existing manual transaction entry screen; gallery/photo continue to feed the existing OCR upload pipeline.

**Frontend — income category icons**

- Add the 10 real `icon_key` values the backend already returns for income categories into the icon resolver's lookup table (and the create/edit category icon picker) so each maps to its own distinct icon, instead of falling through to the generic fallback icon: `wallet-3-fill`, `gift-fill`, `tools-fill`, `store-2-fill`, `line-chart-fill`, `trophy-fill`, `key-2-fill`, `hand-heart-fill`, `coins-fill`, `money-dollar-circle-fill`.
- Verify each key resolves to a real icon in the icon library in use; if any name (e.g. `coins-fill`) doesn't exist under that exact name, alias it to the closest real icon, following the precedent already established elsewhere in the codebase for a prior similar mismatch.
- The icon/color picker in the create/edit category form should offer only the icons relevant to the category type currently selected (income vs. expense), not a single mixed list.

## Testing Decisions

- Backend: unit-test the update-transaction use case for each type-change combination (expense→transfer, transfer→expense, income→transfer, transfer→income, no-op same-type update) covering both the accepted field set and the correctly-cleared field set; test the still-rejected invalid combinations (e.g. `from_account_id == to_account_id`) continue to fail with the existing error contract. Prior art: existing transaction usecase validation-path tests.
- Backend: unit-test Create/Update Category with and without `icon_key`/`color_hex` provided, and with a malformed `color_hex`. Prior art: existing category usecase tests.
- Frontend: test behavior, not internal widget structure.
  - Home's transaction list: verify a transaction remains visible after its category is set (regression test for the original bug), and that the list defaults to the current month.
  - Pie chart legend: verify rows under 10% are omitted while slice proportions still sum to 100%.
  - Icon resolver: table-test each of the 10 income `icon_key` values resolves to a non-fallback icon, and that the create/edit icon grid only offers icons matching the selected category type.
  - Auto-scan timestamp: verify it updates only on a successful upload, not on a no-new-files cycle and not on manual creation.
  - FAB menu: verify each of the three options routes to the correct existing screen/flow.

## Out of Scope

- Any change to how the background auto-scan pipeline itself detects or matches slip photos (MediaStore album watching) — only the addition of a status readout on top of it.
- Adding a `created_at` column to the backend transaction schema — the "last saved" signal is local-device-only for now.
- Any new income-category creation/naming — this only fixes icon rendering for existing and future income categories using the same picker.
- Redesigning the pending-actions page itself, or the manual transaction entry form itself — both are reused as-is.
- Multi-month infinite-scroll on Home — the list stays single-month-with-arrows, matching the existing query/pagination model.
- A pre-existing, unrelated bug noticed while reading the category update code: `UpdateCategory`'s usecase reads a `type` change from the request but never applies it to the category before saving, so changing a category's type via update is silently a no-op today. Not part of this spec; worth its own ticket if it matters.

## Further Notes

- This spec was produced from a `/grill-me` design session that included direct investigation of both repos (`cashlog-api`, `cashlog-app`); several items initially reported as bugs turned out to be intentional-but-undocumented design decisions (e.g. transaction type immutability on update) or a previously incomplete migration (the pie chart was already built and simply never wired in), or a client/server contract mismatch nobody had noticed (the category icon/color picker submitting fields the backend silently ignores).
- The rename of "รายการ" → "ดูสรุป" and the Home/Summary content swap are two sides of one change and should land together to avoid a confusing in-between state where the tab label doesn't match either page's content.

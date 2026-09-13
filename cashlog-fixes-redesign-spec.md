# cashlog-app: Bug Fixes, List/Edit Redesign & Slip Preview — Spec

## Problem Statement

Jar has been dogfeeding the cashlog-app Flutter client against the live cashlog-api backend and found it unusable in three concrete ways, plus three design pain points and one missing capability:

- **Auto-scan silently does nothing.** The app never actually ingests new slip screenshots. The transaction feed only ever shows rows Jar seeded manually via Postman during backend testing, which reads as "the scanner is broken" with no error, no log, and no indication of why.
- **Income categories are invisible.** The Categories screen and the category picker on income transactions show nothing for `type=income` — Jar can create income categories but never sees or assigns them anywhere in the app.
- **Delete feels unreliable.** Tapping delete on a junk transaction sometimes appears to do nothing on the first tap; a second tap deletes it. There's no visual difference between "deleted," "delete failed," and "delete queued for retry," so a failed delete is indistinguishable from a working one that just hasn't refreshed yet.
- **The transaction list is cluttered and indirect.** Every row carries edit/delete icons, and getting to "delete" requires going through the same tap targets as everything else.
- **The category-picker sheet is a full-screen takeover** for what should be a quick, in-context choice.
- **The Home dashboard buries the thing Jar actually needs to see.** A pie chart with per-category names dominates the home screen, while the actual transactions that need attention (freshly scanned, still uncategorized) get pushed below the fold.
- **There's no way to review a slip image after the fact.** Once a transaction is created from a scanned slip, there's no way to pull that slip screenshot back up while editing the transaction to double check amounts, sender/receiver, etc.

## Solution

Fix the three system bugs at their root cause (all confirmed by reading the app's source, not by speculation), then ship the three design changes and one addition Jar specced out:

1. **Auto-scan**: surface Android photo-library permission as a real, reachable, in-app request (currently the only code path that requests it is a hidden `/debug/slip-scan` route never exposed in normal navigation), covering both the fully-denied case and the Android 14 "limited selection doesn't include the bank's screenshot album" case.
2. **Income categories**: fix the category sync call to fetch both `type=income` and `type=expense` instead of only the implicit default (`expense`).
3. **Delete reliability**: no code fix needed for delete itself — it's already correct — but add a small "pending sync" indicator on any transaction row that has a queued, not-yet-retried mutation, so a transient failure is visible instead of silent.
4. Redesign the transaction list: remove per-row edit/delete icons; tapping a row opens the edit page directly; delete moves into the edit page.
5. Keep the category-picker bottom sheet at half-screen height (unchanged), add a scrollbar for overflow instead of making it draggable/expandable.
6. Move the category/amount summary off the Home page and onto the Transaction List page; replace the current all-history pie chart with three tabs (Income / Expense / Transfer); Income and Expense tabs show a category-total list with names shown in the list (not on the chart itself) and tapping a category opens the filtered transaction list; the Transfer tab shows a flat, ungrouped transaction list. Home becomes a single actionable feed of transactions needing attention (mainly: newly-scanned rows still missing a category), plus the new permission-request banner from (1).
7. On the transaction edit page, show the original slip screenshot when it can still be located on-device by filename; otherwise show a "no image" placeholder. No backend storage of the image — this is a 100% on-device, best-effort lookup.

## User Stories

### Auto-scan / gallery permission
1. As the sole user of the app, I want the app to ask me for photo-library access somewhere I can actually see and respond to, so that auto-scan can ever run at all.
2. As a user who denied photo access, I want a persistent, clear banner on the Home page explaining why the app wants it and a button to grant it, so that I can turn scanning on when I'm ready.
3. As a user on Android 14 "select photos" limited access who didn't include the SCB EASY or Dime! screenshot albums, I want the app to tell me that's why nothing is being found, and a shortcut to add those albums to my selection, so that I don't mistake "wrong album selected" for "the scanner is broken."
4. As a user who has already granted full access, I want to never see the permission banner, so that it doesn't clutter my Home screen once scanning already works.
5. As a user, I want auto-scan to keep running automatically on cold start and app resume exactly as it does today once permission is granted, so that I don't have to manually trigger anything.

### Income categories
6. As a user with income categories defined in the backend, I want them to show up on the Categories screen, so that I can see and manage them the same way I manage expense categories.
7. As a user creating or editing an income transaction, I want the category dropdown to list my income categories, so that I can actually categorize income transactions.
8. As a user, I want this to work from the existing local-first cache/sync pattern (no new screens, no new endpoints), so that the fix is minimal and low-risk.

### Delete reliability / pending sync visibility
9. As a user who deletes a junk transaction while the backend is slow to respond (e.g. a cold-started Cloud Run instance), I want to see that my delete is queued and retrying rather than seeing nothing happen, so that I don't lose confidence in the delete action or retry redundantly.
10. As a user, I want the same "pending sync" indicator to apply to queued creates and updates, not just deletes, so that any transient failure is equally visible.
11. As a user, I want the indicator to disappear automatically once the queued action succeeds (via manual retry from the Pending Actions page), so that it never becomes a stale, misleading badge.
12. As a user, I want this to be a purely visual/read-only addition, so that existing retry behavior (manual, user-initiated, no background/reconnect retry) doesn't change.

### Transaction list redesign
13. As a user, I want to tap anywhere on a transaction row to go straight to its edit page, so that I don't need a separate edit icon.
14. As a user, I want the delete action moved to the edit page, so that the list itself is cleaner and I can't accidentally delete from a list swipe/tap.
15. As a user, I want this change scoped to the Transaction List only, so that Category and Account management screens keep their current edit/delete affordances unless I ask for that separately.
16. As a user, I want the delete confirmation dialog on the edit page to behave exactly as it does today (same confirm/cancel copy and flow), so that deleting a transaction still requires an explicit, unambiguous confirmation.

### Category picker sheet
17. As a user assigning a category via the quick-assign sheet, I want it to keep opening at half-screen height (not full screen), so that I keep visual context of the transaction I'm categorizing.
18. As a user with more categories than fit on half a screen, I want to scroll within the sheet via a visible scrollbar, so that I can reach every category without the sheet resizing.

### Home / Transaction List summary redesign
19. As a user, I want the Home page to show me the list of transactions that still need attention (primarily: scanned transactions missing a category), so that Home is an actionable inbox, not a static chart.
20. As a user, I want the gallery-permission banner (see stories 1–4) to appear at the top of this same Home page when relevant, so that "why isn't scanning working" and "here's what needs fixing" live in one place.
21. As a user, I want the category/amount summary to move to the Transaction List page instead of Home, so that summary and detail live together.
22. As a user, I want the summary to be split into three tabs — Income, Expense, Transfer — so that I'm never looking at a mixed total that conflates money coming in, going out, and moving between my own accounts.
23. As a user viewing the Income or Expense tab, I want a list of categories with their total amounts (category names visible in the list, not crammed onto pie-chart slices), so that I can read exact figures at a glance.
24. As a user, I want to tap a category row in the Income or Expense tab and land on the Transaction List filtered to that category, so that I can immediately see which transactions make up that total.
25. As a user viewing the Transfer tab, I want a flat, ungrouped list of transfer transactions (no grouping by account pair), so that I can see every transfer without an extra aggregation step I didn't ask for.
26. As a user, I want the existing Dashboard-page color palette/visual redesign already in progress to extend naturally to this relocated summary, so that it's visually consistent with the rest of the redesigned app.

### Slip image preview
27. As a user reviewing/editing a transaction that came from an auto-scanned slip, I want to see the original slip screenshot on the edit page, so that I can visually double-check the amount, sender, and receiver against the source image.
28. As a user editing a transaction that was created manually or via Postman (no slip involved), I want to see a clear "no image" placeholder instead of a broken image or a crash, so that the absence of a slip is obvious and expected.
29. As a user, I want this to work with zero new backend storage — the app already keeps a `local_image_name` (the gallery asset's filename, not a stable ID) per transaction — so that no privacy/storage tradeoff is introduced for a feature I only need occasionally.
30. As a user, I want the app to gracefully fall back to the "no image" placeholder if the file was renamed, moved out of the configured albums, or deleted since it was scanned, so that a missing file never causes an error or a stuck loading state.

## Implementation Decisions

### Gallery permission surfacing (Bug 1)
- The lifecycle-triggered scan path (`slipScanLifecycle`, firing on cold start and app resume) continues to call `runScan()` unchanged; it still no-ops immediately when access is `denied`, and still returns whatever `queryConfiguredAlbums()` finds when access is `limited`.
- New: a Home-page banner reads the current `GalleryAccessLevel` (already exposed on `SlipScanProgress.accessLevel` after the first scan attempt) and renders one of three states:
  - `full`: no banner.
  - `denied`: banner with a short explanation + a button that calls the existing `requestAccess()` (currently only invoked from the debug page) to trigger the system permission dialog.
  - `limited`: banner explains that partial photo access is on and the bank screenshot albums may not be included, with a button that calls the existing `presentLimitedSelection()` so the user can add them without leaving the app.
- No change to the underlying `SlipGalleryRepository`, `GalleryAccessLevel` enum, or the debug page — this is purely a new, reachable entry point for methods that already exist.
- Because this is a single-user app, no onboarding sequencing, permission-priming copy A/B, or multi-user consent tracking is needed — a static banner with a clear call to action is sufficient.

### Income category sync (Bug 2)
- `CategoriesRepository.refreshFromApi()` currently issues one unparameterized `GET /api/v1/categories` call. Change it to issue two calls — `type=income` and `type=expense` — and merge both result lists before the single `insertAllOnConflictUpdate` batch upsert into `cached_categories`.
- No change to `Category`, `CategoryType`, the mapper, the drift table, or any consuming widget (`CategoriesPage`, `TransactionFormPage`'s type-filtered dropdown, `category_quick_assign_sheet.dart`) — they already correctly key off `CategoryType` once both types are present in the cache.
- No backend change needed; `type=income` and `type=expense` are already valid, working query params.

### Pending-sync indicator (Bug 3 follow-up)
- No change to `TransactionsRepository.delete/create/update`, `ApiClient`, the dio retry interceptor, or `PendingActionsRepository`'s "transient failures only, user-initiated retry only" policy — that behavior is confirmed correct and intentional.
- New: a small badge/indicator on any `TransactionListTile` (and equivalent row in the redesigned category-filtered lists) whose transaction id has a matching open row in `pending_manual_actions`. Source this from `PendingActionsRepository.watchAll()`, keyed by `targetTransactionId`.
- The indicator disappears when its `pending_manual_actions` row is removed (i.e. on successful manual retry from the Pending Actions page) — no separate dismiss/expiry logic needed since `PendingActionsRepository.remove()` already handles that.

### Transaction list tap-to-edit (Design 1)
- Scope: `TransactionListTile` only (Transaction List). Category and Account management list items are unchanged.
- Remove the always-visible edit/delete `IconButton`s from the non-junk row layout; wrap the row in a tap target that pushes `TransactionFormPage` (the same page already used for edit today).
- Junk-row handling: the existing junk-specific edit/delete icons (`junkEditButton`/`junkDeleteButton`) are superseded by the same tap-to-edit behavior; delete moves to a button on `TransactionFormPage` itself.
- `TransactionFormPage` gains a delete action (visible only when editing an existing transaction, not when creating a new one) that reuses the existing confirm dialog copy and the existing `TransactionsRepository.delete` + `recordIfTransient` + `cacheInvalidatorProvider.invalidateMonth` flow currently in `TransactionListTile._confirmDelete`.

### Category picker sheet (Design 2)
- No structural change to `category_quick_assign_sheet.dart`'s height (stays at its current half-screen sizing) — only add scroll affordance (visible scrollbar) for when the category list overflows the available height.

### Home / Transaction List summary relocation (Design 3)
- Home page becomes a single feed: gallery-permission banner (when applicable) at the top, followed by the list of transactions needing attention (junk/uncategorized-from-scan first). This reuses the existing `isJunk`/category-null signal already present on `Transaction`.
- Dashboard's current summary widget (`expense_pie_chart.dart`, `dashboard_page.dart`, `dashboard_repository.dart`/`dashboard_mapper.dart`) moves to the Transaction List page as a new top section with three tabs: Income, Expense, Transfer.
- Income/Expense tabs: replace the pie-chart-with-labels visualization with a plain list of `{category_name, total_amount}` rows, sourced from the existing `DashboardSummaryResponse` per-category breakdown arrays (already returns both income and expense arrays — no backend change needed). Tapping a row navigates to the Transaction List filtered by that `category_id`.
- Transfer tab: a flat list of transfer transactions for the current scope (month/year), with no grouping by account pair — sourced directly from existing transfer transactions, not from the dashboard summary endpoint (which has no transfer breakdown by category, since transfers carry no `category_id`).
- The existing Dashboard-page palette work (background `#FCF2E5`, text `#524646`, accent `#EC5B38`) carries over to this relocated summary section as-is.

### Slip image preview (Addition)
- On `TransactionFormPage` (edit mode only), add an image section that:
  1. Reads `transaction.localImageName`. If null/empty, render the "no image" placeholder immediately.
  2. Otherwise, calls `SlipGalleryRepository.queryConfiguredAlbums()` and looks for a `SlipCandidate` whose `filename` matches `localImageName`.
  3. If found, calls `SlipGalleryRepository.readBytes(candidate.id)` and renders the resulting bytes as an image.
  4. If not found, or `readBytes` returns null (asset deleted since), render the same "no image" placeholder — no error state, no retry button, no loading stall.
- No new drift table, no new backend field, no new domain model field — `localImageName` already exists end-to-end (`cached_transactions.local_image_name` → `Transaction.localImageName` → mapper).
- Explicitly not building any caching/thumbnailing of this lookup for v1 — it happens once when the edit page opens.

## Testing Decisions

- Tests should assert observable behavior (what's rendered, what request is sent, what's persisted locally), never internal call sequencing, matching the existing test style in this codebase (e.g. `transactions_repository_test.dart`, `categories_repository_test.dart` fake the `HttpClientAdapter` and assert on resulting DB state / returned `Either`).
- **Gallery permission banner**: widget test driving `SlipScanProgress.accessLevel` through `full`/`limited`/`denied` and asserting the correct banner state (or its absence) renders on the Home page; a tap on each button asserts the corresponding repository method (`requestAccess`/`presentLimitedSelection`) is invoked. Prior art: `slip_gallery_debug_page.dart`'s own existing widget coverage for the same repository calls.
- **Category sync**: repository-level test asserting `refreshFromApi()` issues two requests with the two `type` query values and that both income and expense rows end up upserted into `cached_categories`. Prior art: `categories_repository_test.dart`'s existing fake-adapter pattern.
- **Pending-sync indicator**: widget test seeding a `pending_manual_actions` row for a given transaction id and asserting the badge renders on that row and not on others; a second test removing the row and asserting the badge disappears. Prior art: `cache_invalidator_test.dart`'s pattern of seeding drift tables directly and asserting reactive `watch()` output.
- **Tap-to-edit / delete moved to edit page**: widget tests on `TransactionListTile` asserting a tap anywhere on the row navigates to `TransactionFormPage`, and that no delete/edit icon exists in the non-junk row anymore; a `TransactionFormPage` test asserting the delete button and confirm dialog only appear in edit mode, and that confirming triggers the existing delete flow. Prior art: `transaction_list_tile_test.dart`, `transaction_form_page_test.dart`.
- **Summary relocation**: repository/mapper-level tests reusing the existing `dashboard_mapper_test.dart`/`dashboard_repository_test.dart` fixtures, re-pointed at the new category-list rendering instead of the old pie chart; a navigation test asserting a tapped category row lands on the Transaction List pre-filtered by `category_id`. Prior art: `dashboard_page_test.dart`.
- **Slip image preview**: widget test with a fake `SlipGalleryRepository` returning a matching candidate (image renders), a non-matching candidate (placeholder renders), and a null `localImageName` (placeholder renders immediately, no gallery query made).

## Out of Scope

- Any change to the cashlog-api backend — every fix above is client-side only; the `/api/v1/categories?type=` and dashboard summary endpoints already behave correctly.
- Automatic/background retry of queued `pending_manual_actions` (e.g. on reconnect or on a timer) — the indicator only makes the existing manual-retry model visible, it doesn't change the retry model itself.
- Any redesign of Category or Account management screens' edit/delete affordances — those keep their current icons/flow.
- Caching, thumbnailing, or persisting the on-device slip image lookup — each edit-page open re-queries the gallery live.
- Any storage of slip images on the backend, or any change to the 30-day OCR idempotency TTL/filename-keying scheme.
- Multi-user or multi-device permission/consent handling — this app is single-user by design.
- Visual redesign of the Dashboard/summary beyond adopting the palette already in progress and swapping pie-chart-with-labels for a category-total list.

## Further Notes

- Bugs 1 and 2 were root-caused directly against the `cashlog-app` repo source (not diagnosed from logs/screenshots), so both fixes above should be implementable without further reproduction steps from Jar.
- Bug 3 required no repository/network-layer changes — the only actionable follow-up is the visibility improvement (pending-sync indicator), which Jar confirmed wanting.
- The Home-page redesign (permission banner + attention feed) and the Transaction-List summary relocation are related but independently shippable; recommend sequencing the three bug fixes first (they unblock real data — scanning, income categories — flowing through the app at all), then the transaction-list tap-to-edit change, then the summary relocation and slip-preview feature last, since both of those benefit from having real scanned/categorized data to design and test against.

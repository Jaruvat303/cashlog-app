# Cashlog Mobile — Task Set (T1–T19)

Each block below is ready to paste as the first message of a Claude Code
session for that ticket (per `TASK_TEMPLATE.md`'s Plan → Approve → Verify
flow). Where the original tickets doc gave no explicit acceptance criteria,
it's flagged — confirm/refine before starting that ticket instead of letting
Claude invent one.

Add `@CLAUDE.md @cashlog-frontend-spec.md` at the top of your actual message
so both are loaded — that part isn't repeated in every block below.

---

## Foundation

### T1 — Project scaffold + networking core
**Blocked by:** none

**Context Dependencies**
- required: CLAUDE.md (full), spec §3 (Project Structure), §4 (Networking,
  error handling, retry policy table), §5 (Environment/Config)
- exclude: §7 (slip scan), §8 (drift schema) — not needed yet

**Objective:** Flutter skeleton with dio client, X-API-Key interceptor,
Failure/Either error pattern, dev/prod env config. No feature code yet.

**Definition of Done**
- One GET request (e.g. `/health` or `/accounts`) succeeds from a dev build
- An unrecognized error does not crash the app
- A sample repository method returns `Either<Failure, T>` correctly for
  both success and failure

---

### T2 — Drift database + schema
**Blocked by:** T1

**Context Dependencies**
- required: CLAUDE.md, spec §8 (full — all 5 table definitions)
- related: T1's `core/env` setup (same project scaffold)
- exclude: everything outside persistence — no UI, no networking logic here

**Objective:** `core/db/app_database.dart` with all 5 tables
(`ScannedSlips`, `CachedTransactions`, `CachedAccounts`,
`CachedCategories`, `PendingManualActions`) exactly as specified in §8.
`build_runner` runs clean.

**Definition of Done**
- Can write to and read from all 5 tables via a simple unit test

---

### T3 — Navigation shell
**Blocked by:** T1 (can run in parallel with T2)

**Context Dependencies**
- required: CLAUDE.md, spec §13 (Routing)
- exclude: feature screens — placeholder pages only

**Objective:** `go_router` + bottom nav with 4 tabs (Dashboard /
Transactions / Accounts / Categories) as empty placeholder pages that
navigate correctly.

**Definition of Done**
- Can switch between all 4 tabs without crashing
- Deep link returns to the correct tab after a hot restart

---

## Core CRUD

### T4 — Accounts CRUD (end-to-end)
**Blocked by:** T1, T2, T3

**Context Dependencies**
- required: CLAUDE.md, spec §7.9 (Bank icon mapping — client-owned), §12
  (Accounts scope), §12.1 (no dedicated detail endpoint), §12.2 (upsert-only
  cache sync — `is_active=true` filter caveat), §8 `CachedAccounts` schema
- related: T2's drift setup
- exclude: §12.3 (quick category assignment — that's T18, not this ticket),
  categories feature entirely

**Objective:** Full list (cache + API refresh) → create → edit → delete via
UI, writing to `cached_accounts`. Local static bank-icon map (name + logo +
color) for account creation, with fallback icon for unrecognized codes.
Cache sync is upsert-only — never delete a local row just because it's
missing from a `GET /accounts` response. Account detail screen reads from
`cached_accounts` directly, no new network call.

**Definition of Done**
- Create/edit/delete an account from the app and see the result reflected
  on the backend (verifiable via Postman)
- Selecting a bank from the list shows the correct logo/color on redisplay
- After closing (soft-deleting) an account, transactions still linked to it
  keep showing the correct name/logo — never falls back to "unknown"

---

### T5 — Categories CRUD (end-to-end)
**Blocked by:** T1, T2, T3

**Context Dependencies**
- required: CLAUDE.md, spec §12.4 (Category delete guard, FR-2.2), §8
  `CachedCategories` schema
- related: T2's drift setup
- exclude: accounts feature, bank icon logic (not relevant here)

**Objective:** Same shape as T4 but for categories, plus a delete guard:
before deleting, count `cached_transactions` locally where
`categoryId == X` and warn the user with that count before they confirm.
No new backend endpoint — count from local cache only.

**Definition of Done**
- Deleting a category that has linked transactions shows a dialog stating
  how many will be affected, before the delete is confirmed
- After deletion, those transactions become uncategorized (not deleted)

---

### T6 — Manual transaction create/edit
**Blocked by:** T4, T5 (needs accounts/categories to select from)

**Context Dependencies**
- required: CLAUDE.md, spec §4 (error codes — specifically
  `ErrTransferSameAccount`, `ErrCategoryNotAllowedForTransfer`), §8
  `CachedTransactions` schema
- related: T4/T5's account and category pickers
- exclude: slip scan flow, junk detection (T12)

**Objective:** A form for manually creating/editing a transaction (not from
a slip) with account + category selection.

**Definition of Done**
- Can create all 3 transaction types: income, expense, transfer
- Client-side validation matches backend rules (e.g. rejects a transfer
  with the same source/destination account, rejects a category not valid
  for transfers)

---

### T7 — Transaction feed
**Blocked by:** T2, T3, T6 (needs a way to create transactions first)

**Context Dependencies**
- required: CLAUDE.md, spec §10 (Transaction Feed — pagination), §8
  `CachedTransactions` schema
- related: T6 (source of data to display)
- exclude: §7.7 (junk badge UI — that's T12's job, don't build it here even
  though the feed will need to accommodate it later)

**Objective:** Main list screen with infinite-scroll pagination per month,
plus a month selector.

**Definition of Done**
- Scrolling loads the next page of transactions
- Switching month updates the list correctly

---

### T8 — Dashboard summary
**Blocked by:** T7

**Context Dependencies**
- required: CLAUDE.md, spec §11 (Dashboard — monthly scope, in-memory
  Riverpod cache only, no disk persistence)
- related: T7's month/year state (must be shared, not duplicated)

**Objective:** Summary screen driven by the same month/year state as T7.

**Definition of Done**
- *Not explicitly stated in the tickets doc.* Draft before starting:
  summary updates correctly when month/year changes in T7's selector, and
  summary data is never persisted to disk. Confirm this matches intent
  before treating it as final.

---

## Slip Auto-Scan

### T9 — Gallery permission + album query
**Blocked by:** T1

**Context Dependencies**
- required: CLAUDE.md, spec §7.3 (Permission — `READ_MEDIA_IMAGES` +
  fallback), §7.4 (photo_manager), §7.5 (folder filter — config list, not
  hardcoded)
- exclude: upload logic (T10), compression, drift writes

**Objective:** Request permission, query the "SCB EASY" and "Dime!" albums
via `photo_manager`, and show a debug screen listing matched filenames.
Album names must be a config list, not hardcoded deep in logic.

**Definition of Done**
- Tested on a real Android 14 device: sees the full, correct filename list
  matching what's actually in both albums

---

### T10 — Slip upload pipeline
**Blocked by:** T9, T2, T7

**Context Dependencies**
- required: CLAUDE.md, spec §7.6 (scan sequence), §7.6.1 (rate limit —
  sequential + ~7s delay), §4 (body size limit, retry policy table), §8
  `ScannedSlips` schema
- related: T9 (album query), T7 (feed refresh target)
- exclude: junk detection logic (T12), lifecycle wiring (T11) — this ticket
  is upload-triggered manually or from a single scan pass, not tied to app
  lifecycle yet

**Objective:** Diff new files against `scanned_slips` → compress with
`flutter_image_compress` → upload sequentially with ~7s delay per file →
`POST /upload-slip` → handle the 3 outcomes (uploaded/duplicate/failed) →
write results to `scanned_slips` and refresh the feed. Show a progress
indicator during multi-file uploads.

**Definition of Done**
- Scanning 1 real slip produces a new transaction in the feed
- Re-scanning the same file doesn't duplicate it (skipped by local diff,
  client-side — before ever hitting the network)
- Scanning >10 files doesn't trigger a 429 from the backend

---

### T11 — Scan trigger lifecycle
**Blocked by:** T10

**Context Dependencies**
- required: CLAUDE.md, spec §7.2 (scan trigger — cold start + resume via
  `WidgetsBindingObserver` / `AppLifecycleState.resumed`)
- related: T10 (the pipeline being triggered)

**Objective:** Wire T10's pipeline to app cold start and resume events.

**Definition of Done**
- Switching to the banking app and back triggers a new scan automatically

---

### T12 — Junk detection + badge UI
**Blocked by:** T10, T7

**Context Dependencies**
- required: CLAUDE.md, spec §7.7 (junk detection rule + UX — badge, delete,
  manual edit; never auto-delete)
- related: T10 (where junk transactions originate), T7 (feed display)

**Objective:** Rule: `amount == 0 && senderName.isEmpty &&
receiverName.isEmpty` → `isJunk = true`. Show a warning badge in the normal
feed (not a separate list), with delete and manual-edit options.

**Definition of Done**
- A slip that can't be read (test with a random non-slip image in the
  album) shows the badge correctly
- Can be deleted
- After manual edit, the badge disappears

---

## Resilience

### T13 — Pending manual actions retry queue
**Blocked by:** T6, T2

**Context Dependencies**
- required: CLAUDE.md, spec §9 (Offline behavior — `pending_manual_actions`
  as a lightweight retry queue, not a full sync engine), §8
  `PendingManualActions` schema
- related: T6 (source of failures to queue)

**Objective:** When a T6 create/update/delete fails due to network/error,
store the attempt in `pending_manual_actions` and show a "stuck — tap to
retry" affordance in the UI.

**Definition of Done**
- *Not explicitly stated in the tickets doc.* Draft before starting: a
  failed manual action appears in a retry-able list; tapping retries it;
  this is explicitly not a full sync queue, so don't build automatic
  background retry here.

---

### T14 — Cache invalidation
**Blocked by:** T6, T7, T8, T10

**Context Dependencies**
- required: CLAUDE.md, spec §9 (Cache invalidation — per-month, cross-month
  edit case)
- related: T6, T7, T8, T10 (all mutation sources that must trigger this)

**Objective:** After a successful mutation (scan success / manual
create / update / delete), invalidate only the affected month's cache. If a
transaction's date is edited across a month boundary, invalidate both the
old and new month.

**Definition of Done**
- *Not explicitly stated in the tickets doc.* Draft before starting: editing
  a transaction's date across a month boundary correctly refreshes both the
  old and new month's feed and dashboard without a manual pull-to-refresh.

---

### T15 — Gemini quota retry
**Blocked by:** T10

**Context Dependencies**
- required: CLAUDE.md, spec §4 (special case: `ErrGeminiQuotaExhausted`)
- related: T10 (upload pipeline this modifies)

**Objective:** On `ErrGeminiQuotaExhausted`, mark the slip `failed` in
`scanned_slips` without retrying immediately — let the next scan cycle
pick it up naturally.

**Definition of Done**
- *Not explicitly stated in the tickets doc.* Draft before starting:
  simulating this error code marks the slip failed and does not retry
  until the next scan cycle runs (cold start/resume), with no retry loop
  in between.

---

## Non-blocking (can run anytime, don't block main sequence)

### T16 — SRS reconciliation
**Blocked by:** none — ideally done before T6

**Context Dependencies**
- required: full `SRS-cashlog-system-v2.docx`, full
  `cashlog-frontend-spec.md`

**Objective:** Read the complete SRS and compare against the frontend spec
to find any business-rule gaps the spec might have missed.

**Definition of Done:** A written list of gaps/discrepancies found (non-code
deliverable — this ticket doesn't touch the app).

---

### T17 — Real-device scoped storage validation
**Blocked by:** T9

**Context Dependencies**
- required: CLAUDE.md, spec §7.3, §7.5 (permission + folder filter edge
  cases)
- related: T9 (the feature being stress-tested)

**Objective:** Test `photo_manager` against Android scoped-storage edge
cases on a real device — e.g. deleting a photo from the album while the app
is open.

**Definition of Done**
- *Not explicitly stated in the tickets doc.* Draft before starting: define
  2–3 specific edge cases to test (e.g. mid-scan deletion, album renamed,
  permission revoked mid-session) and confirm expected behavior for each
  before running them.

---

### T18 — Quick category assignment (BR-9, FR-5.3)
**Blocked by:** T5, T7

**Context Dependencies**
- required: CLAUDE.md, spec §12.3 (Quick category assignment — primary path
  vs T6's full-edit escape hatch)
- related: T5 (category list), T7 (feed row UI)
- exclude: T6's full edit form — don't touch it, this is a separate flow

**Objective:** Tap a chip/button on a transaction row in the feed → bottom
sheet to pick a category → `PATCH /transactions/:id` immediately, without
leaving the feed. This is the primary way to assign categories; T6 remains
an escape hatch for abnormal data only.

**Definition of Done**
- Tapping the chip, picking a category, and seeing the update reflected in
  the feed immediately, without navigating away

---

### T19 — SRS document sync (non-code)
**Blocked by:** none — do whenever, no dev impact

**Context Dependencies**
- required: spec §14 (Open Items — specifically the two flagged doc/code
  mismatches)

**Objective:** Update the SRS document to match decisions already made in
code: (1) BR-8/FR-4.8 — change from "backend skips silently" to "backend
creates a normal transaction; frontend detects it, badges it, and allows
delete/edit" (2) section 6.1 (Account fields) — change `icon_key` /
`color_hex` to `bank_icon` to match the actual schema.

**Definition of Done**
- SRS document text matches the decisions above (non-code — no dev impact)

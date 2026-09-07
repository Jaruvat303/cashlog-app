# CLAUDE.md — Cashlog Mobile (Flutter client)

This file is project-wide context for Claude Code. It reflects decisions already
finalized in `cashlog-frontend-spec.md` and `cashlog-frontend-tickets.md`.
Do not re-litigate these — if something here conflicts with a request, flag it
instead of silently overriding.

## Project scope

- Single-owner (single-user) Flutter app. No login, no multi-tenant logic.
- Android only for v1, minSdk 26, tested on real Android 14 devices.
- Backend is `cashlog-api` (Go/Fiber, Cloud Run). **Never modify backend code
  or propose new endpoints** — if something seems to need a new endpoint,
  say so explicitly instead of working around it silently.

## Stack & architecture

- **State management:** Riverpod + `riverpod_generator` (`@riverpod` codegen).
  `build_runner` is part of the dev workflow.
- **Folder structure:** feature-first, not layer-first.
  ```
  lib/
  ├── core/{network,db,env,router}/
  ├── features/{slip_scan,transactions,dashboard,accounts,categories}/{data,domain,presentation}/
  └── shared/widgets/
  ```
  Each feature owns its own data/domain/presentation. No cross-feature layer
  sharing except through `core/` and `shared/`.
- **Networking:** `dio`, with `X-API-Key` injected via interceptor
  (compile-time constant from `--dart-define`).
- **Error handling:** `dartz` — repository/usecase methods **always** return
  `Either<Failure, T>`. Never throw exceptions across layers. `dio`
  interceptor converts errors into `Failure` at the boundary.
- **Local persistence:** `drift` (typed sqlite). Five tables: `ScannedSlips`,
  `CachedTransactions`, `CachedAccounts`, `CachedCategories`,
  `PendingManualActions`. See spec §8 for exact schema — don't invent new
  columns without checking there first.
- **Routing:** `go_router`.

## Environments

- `dev` and `prod`, both on Cloud Run, separate API keys.
- Use `--dart-define-from-file=env/dev.json` / `env/prod.json`.
- **No Flutter flavors** — intentionally out of scope, don't add them.

## Non-negotiable business rules

- **Body size limit:** backend `BodyLimit` is 4MB. Always compress images
  with `flutter_image_compress` (~1–2MB target) before upload.
- **Rate limits:** `/api/v1/*` general = 60 req/60s. `/upload-slip` = 10
  req/60s specifically. Slip uploads must be sequential with a fixed ~7s
  delay between files — never fire uploads concurrently.
- **Retry policy** (see spec §4 for the full error_code table):
  - Transient (`ErrTimeout`, `ErrGeminiUnavailable`, `ErrInternalDB`,
    `ErrContextCanceled`) → auto-retry.
  - Permanent (`ErrNotFound`, `ErrDuplicateRequest`, `ErrInvalidInput`,
    `ErrGeminiEmptyResponse`, `ErrSlipParseFailed`, `ErrAccountInactive`,
    `ErrTransferSameAccount`, `ErrCategoryNotAllowedForTransfer`) → surface
    to user, no auto-retry.
  - `ErrGeminiQuotaExhausted` → mark `failed` in `scanned_slips`, do **not**
    retry immediately; let the next scan cycle pick it up.
- **Junk detection:** a transaction with `amount == 0 && senderName.isEmpty
  && receiverName.isEmpty` → client sets `isJunk = true`. Show it in the
  normal feed with a warning badge; offer delete or manual edit. Never
  auto-delete or hide it silently.
- **Bank icon ownership:** the client owns bank name/logo/color as a local
  static map. Backend only stores/returns a `bank_icon` code string (e.g.
  `"scb"`, `"dime"`) — no `color_hex` in the backend schema. If a code isn't
  in the local map, fall back to a generic icon and show the raw code.
- **Accounts cache sync is upsert-only.** `GET /accounts` filters to
  `is_active = true` only, so closed accounts never come back in the list.
  Never delete a `CachedAccounts` row just because it's missing from a
  sync response — closed accounts must stay in local cache so old
  transactions can still resolve a name/logo. Filter `WHERE isActive = true`
  only at read time (e.g. the accounts list screen), never at sync time.
- **No `GET /accounts/:id`.** It doesn't exist and isn't needed — the list
  response already has every field. Account detail screens query
  `cached_accounts` locally, never a new network call.
- **Category quick-assign is the primary path** (not the full edit form):
  tap a chip/button on the feed row → bottom sheet → `PATCH
  /transactions/:id` immediately, no navigation away from the feed. The
  full edit screen (T6) is an escape hatch for abnormal data (e.g. junk
  transactions, fixing amount/account/note), not the main flow.
- **Category delete guard:** before deleting a category, count affected
  `cached_transactions` locally (`categoryId == X`) and warn the user with
  that count. No new backend endpoint for this — count from local cache.
- **Offline behavior:** online-only + read cache. Reads work offline from
  `drift` cache; writes (create/edit) require network. Failed manual
  create/update/delete go into `pending_manual_actions` as a lightweight
  "stuck — tap to retry" queue — this is not a full sync engine.
- **Cache invalidation:** invalidate only the affected month's cache after a
  successful mutation. If a transaction's date is edited across a month
  boundary, invalidate both the old and new month.

## What NOT to do

- Don't add Flutter flavors, JWT/login flows, or multi-user logic.
- Don't invent new backend endpoints or modify backend code.
- Don't persist dashboard summaries to disk — in-memory Riverpod state only
  (backend already has Redis caching with a 1h TTL).
- Don't do full offline-first sync — this app is online-only + read cache
  by design.
- Don't throw exceptions across architectural layers — always `Either`.

## Reference documents

- `SRS-cashlog-system-v2.docx` — source of truth for backend business rules
  (note: as of the last check, a few sections are stale — see "Open Items"
  in the frontend spec for known doc/code mismatches).
- `cashlog-frontend-spec.md` — this file's source; consult it for anything
  not covered here (full drift schema, sequence diagrams, etc).
- `cashlog-frontend-tickets.md` — the T1–T19 implementation plan and
  dependency graph. Work ticket-by-ticket; check "Blocked by" before
  starting one.

# Tickets: Income vs Expense Trend Page (app)

Builds the monthly/yearly income-vs-expense bar chart page. Spec: planning/specs/income-expense-bar-chart-page.md

Sliced by layer per Jar's choice in the grill session. Backend tickets B1 and B2 live in the cashlog-api repo.

Work the frontier: F1 and F2 can run in parallel (F2 once backend B2 is on dev); F3 comes last.

---

### F1 — `FinanceColors` theme extension

**Parent**: planning/specs/income-expense-bar-chart-page.md

**What to build**: Income green and expense red become shared theme colors. The create-transaction screen reads them from `FinanceColors` instead of its own values and looks exactly the same as before.

**Acceptance criteria**:
- [ ] `FinanceColors` `ThemeExtension` with `income` and `expense`, registered on the main theme, with `copyWith` and `lerp`
- [ ] Values equal the colors the create-transaction screen uses today
- [ ] Create-transaction screen reads income/expense colors from `FinanceColors`; no hardcoded copies remain there
- [ ] Test confirms the screen still renders the same income/expense colors
- [ ] No visible change on device

**Blocked by**: None — can start immediately.

---

### F2 — Trend data layer

**Parent**: planning/specs/income-expense-bar-chart-page.md

**What to build**: The app can fetch and hold trend data for any (granularity, year) from the live dev endpoint, returning a typed `TrendSummary` or a `Failure`. No UI yet.

**Acceptance criteria**:
- [ ] `TrendSummary`, `TrendBucket` (`int?` month) and `TrendGranularity` domain types in the dashboard feature
- [ ] Mapper handles monthly (12 buckets, top-level year set) and yearly (`month: null`, top-level `year: null`) responses
- [ ] `DashboardRepository.fetchTrend({granularity, year})` → `Either<Failure, TrendSummary>` via `ApiClient`, calling `/api/v1/transactions/trend`
- [ ] `trendProvider(granularity, year)` family provider (codegen), in-memory only, no drift table
- [ ] Mapper, repository and provider tests pass
- [ ] Response shape confirmed against the dev swagger / a real dev response before merging

**Blocked by**: backend B2 — Trend endpoint for month and year modes (deployed on dev).

---

### F3 — Trend page, bar chart and entry point

**Parent**: planning/specs/income-expense-bar-chart-page.md

**What to build**: From the "ดูสรุป" tab, Jar taps a chart icon on the AppBar and sees a grouped green/red bar chart of income vs expense. He can toggle รายเดือน / รายปี, switch years with arrows in monthly mode, and tap a bar for a tooltip with income, expense and net.

**Acceptance criteria**:
- [ ] `ri-bar-chart-2-line` icon button on the "ดูสรุป" AppBar pushes route `/summary/trend`; back returns to the tab
- [ ] Page opens in monthly mode for the current year
- [ ] `SegmentedButton` [รายเดือน | รายปี]; ◀ year ▶ switcher shown only in monthly mode, not beyond the current year
- [ ] Grouped bar chart with `fl_chart`: income and expense from `FinanceColors`, legend shown
- [ ] Monthly mode always shows 12 slots; future months of the current year have no bars and faded labels
- [ ] Tap a bar → tooltip with income, expense, net; Y axis abbreviated K/M
- [ ] Loading state, and error state with a retry action
- [ ] AppBar, toggle and switcher follow the app's gradient theme
- [ ] Widget tests: mode toggle, year arrows change the request, future-month rendering, error + retry
- [ ] Checked on device against dev data

**Blocked by**: F1 — `FinanceColors` theme extension; F2 — Trend data layer.

---

## Follow-ups (not scheduled)

Found during F1's exploration. Outside this feature's scope; pick up later as separate work.

### FU-1 — Make the transfer color consistent and add it to `FinanceColors`

**What to build**: Transfers show the same color on the create/edit form and in the transaction feed, and that color comes from `FinanceColors.transfer`.

**Context**: The form maps `TransactionType.transfer` to `AppColors.accentA` (brand blue `#4F8EF7`) in `transaction_form_fields.dart:84-88`. The feed row uses `AppColors.transfer` (purple `#6C5CE7`) in `transaction_list_tile.dart:50-51,73`.

**Acceptance criteria**:
- [ ] Jar picks one transfer color (this is an intentional visible change on one of the two screens)
- [ ] `FinanceColors` gains `transfer` (constructor, `light`, `copyWith`, `lerp`)
- [ ] Form and feed both read the transfer color from `FinanceColors`
- [ ] Tests updated

**Blocked by**: F1.

### FU-2 — Dedicated `danger` color token

**What to build**: Destructive actions and error text use their own `danger` color, so they no longer change if the expense color is retuned.

**Context**: 5 places borrow `AppColors.expense` as a danger color:
- `transaction_form_page.dart:271` (delete icon button)
- `transaction_form_page.dart:313` (inline error text)
- `transaction_form_fields.dart:273` (transfer-validation error text)
- `account_detail_page.dart:133` (close-account pill)
- `category_form_page.dart:234` (delete-category button)

**Acceptance criteria**:
- [ ] Add a `danger` token (decide: `AppColors.danger` constant vs mapping to `colorScheme.error` in the theme)
- [ ] Initial value equals the current `AppColors.expense`, so there is no visible change
- [ ] All 5 usages migrated; `AppColors.expense` then means expense amounts only
- [ ] `flutter analyze` and `flutter test` pass

**Blocked by**: None.

### FU-3 — Feed amounts use `FinanceColors`

**What to build**: The transaction feed row reads income/expense amount colors from `FinanceColors` instead of `AppColors` directly.

**Context**: `transaction_list_tile.dart:90,112` use `AppColors.income` / `AppColors.expense`.

**Acceptance criteria**:
- [ ] Feed row amount colors come from `context.financeColors`
- [ ] No visible change
- [ ] Tests updated or added

**Blocked by**: F1.
# Spec: Income vs Expense Trend Page (app)

> Paired with the backend spec in `cashlog-api` → planning/specs/income-expense-bar-chart-api.md
> Source: grill-me session, Sept 2026 (Q1–Q16)

## Problem Statement

On the "ดูสรุป" tab Jar can only see one month at a time: totals plus the category pie chart. There is no way to see how income and expense move across a year, to spot months where spending exceeded income, or to compare one year with the next. Separately, the green/red income/expense colors exist only inside the create-transaction screen, so any new screen that needs them would have to copy the values.

## Solution

A new page, "เปรียบเทียบรายรับ–รายจ่าย", opened from an icon button on the "ดูสรุป" AppBar. It shows a grouped bar chart (income green, expense red) with a toggle between:

- **รายเดือน**: 12 month slots for a chosen year, with a ◀ year ▶ switcher
- **รายปี**: one pair of bars per year the app has data for

Tapping a bar shows a tooltip with income, expense and net. The data comes from the new backend endpoint `GET /api/v1/transactions/trend` in a single request. Income/expense colors move into a shared `FinanceColors` theme extension used by both the chart and the create-transaction screen; everything else on the page follows the app's blue–purple gradient theme.

## User Stories

1. As Jar, I want an icon button on the "ดูสรุป" AppBar, so that I can open the trend chart from where I already look at my summary.
2. As Jar, I want the trend page to open in monthly mode for the current year, so that the most useful view shows immediately.
3. As Jar, I want to see income and expense as two side-by-side bars for each month, so that I can compare them at a glance.
4. As Jar, I want income bars green and expense bars red, matching the create-transaction screen, so that the color meaning is consistent across the app.
5. As Jar, I want a legend on the chart, so that the meaning doesn't rely on color alone.
6. As Jar, I want to switch the year with ◀ ▶ arrows, so that I can look at previous years the same way I switch months elsewhere.
7. As Jar, I want the year arrows to stop at sensible bounds, so that I can't navigate into years that can't have data.
8. As Jar, I want to toggle between รายเดือน and รายปี with a segmented control, so that switching views is one tap.
9. As Jar, I want the year switcher hidden in yearly mode, so that there's only one time control relevant to what I'm seeing.
10. As Jar, I want yearly mode to show one pair of bars per year I've used the app, so that I can compare year over year.
11. As Jar, I want all 12 month labels shown even for future months, so that the X axis looks the same every year.
12. As Jar, I want future months shown with faded labels and no bars, so that I can tell "not yet" apart from "zero".
13. As Jar, I want months with no transactions shown as empty (zero) slots with normal labels, so that I know nothing happened that month.
14. As Jar, I want to tap a bar and see a tooltip with income, expense and net for that period, so that I can read exact numbers without cluttering the chart.
15. As Jar, I want the Y axis abbreviated as K/M, so that large amounts stay readable on a phone screen.
16. As Jar, I want a loading state while the data is fetched, so that I know the page is working.
17. As Jar, I want a clear error state with a retry action when the request fails, so that a network hiccup doesn't leave a blank page.
18. As Jar, I want previously loaded years to reappear instantly when I switch back during the same session, so that toggling feels fast.
19. As Jar, I want the page to use the app's gradient theme for the AppBar, toggle and switcher, so that it looks like the rest of the app.
20. As Jar, I want the create-transaction screen to keep exactly the same colors after the refactor, so that nothing visibly changes there.
21. As Jar, I want the back button to return me to the "ดูสรุป" tab where I was, so that navigation feels natural.

## Implementation Decisions

**Placement**

- Everything lives inside the existing `dashboard` feature (same domain as the summary), not a new feature folder
- New go_router route `/summary/trend`, pushed from an icon button (`ri-bar-chart-2-line`) on the "ดูสรุป" AppBar

**Theme**

- New `FinanceColors` `ThemeExtension` with `income` and `expense` colors, registered on the main theme
- Values are taken from the colors the create-transaction screen already uses for income/expense; that screen is refactored to read from `FinanceColors`
- All other UI on the page uses the existing theme (blue–purple gradient)

**Domain**

- `TrendSummary` (granularity, optional year, list of buckets) and `TrendBucket` (year, `int?` month, totalIncome, totalExpense, net), plus a `TrendGranularity` enum (month, year)
- Type shape agreed in the grill session, mirroring the API contract:

```
TrendResponse {
  granularity: "month" | "year"
  year: int | null
  buckets: [{ year, month: int | null, total_income, total_expense, net }]
}
```

**Data**

- `DashboardRepository` gains `fetchTrend({granularity, year})` → `Either<Failure, TrendSummary>`, calling `GET /api/v1/transactions/trend` through the existing `ApiClient`
- A new mapper converts the JSON envelope into the domain type (same style as the dashboard mapper)
- No drift table: data is in-memory only, consistent with the summary (online-only network model)

**State**

- `trendProvider(granularity, year)` Riverpod family provider (codegen); keeping each family entry in memory for the session gives instant re-display when switching back
- The page holds the selected granularity and year as local UI state

**UI**

- `SegmentedButton` [รายเดือน | รายปี]; year switcher ◀ year ▶ visible only in monthly mode
- Year switcher bounds: not beyond the current year going forward; going back is bounded by the backend's allowed range
- Grouped bar chart widget built with the existing `fl_chart` dependency (no new package)
- Monthly mode: 12 slots always; future months of the current year are detected on the app side (bucket after the current Bangkok month) and render no bars with faded labels
- Tap a bar → tooltip with income, expense, net; Y axis abbreviated K/M
- Legend for income/expense
- Loading, error (with retry), and data states driven by the provider

**Backend dependency**

- Relies on the backend's zero-filled 12 buckets in monthly mode and the at-least-one-bucket guarantee in yearly mode, so the app has no calendar-filling logic and no empty-array special case
- `net` is taken from the backend, not recomputed

## Testing Decisions

- Good tests check visible behaviour and returned values, not widget tree internals or provider wiring.
- **Mapper**: JSON → `TrendSummary`, including `month: null` in yearly mode and `year: null` at the top level
- **Repository**: `fetchTrend` calls the right path with the right query params and maps success and `Failure` correctly, using a faked `ApiClient`
- **Provider**: exposes loading / data / error from a fake repository; different (granularity, year) arguments produce independent results
- **Page (widget test)**: toggle switches modes and hides/shows the year switcher; year arrows change the requested year; error state shows retry; future months render faded with no bars
- **Theme**: the create-transaction screen renders the same income/expense colors via `FinanceColors`
- Prior art: the existing dashboard tests (mapper, repository, providers, page)

## Out of Scope

- Tapping a bar to jump to that month on the "ดูสรุป" tab (deferred, not dropped)
- Per-category trend, transfers as a series, custom date ranges, rolling 12-month window
- Disk caching of trend data
- Dark-mode values for `FinanceColors` (the extension makes this easy later)
- Backend work (see the cashlog-api spec)

## Further Notes

- Data exists only from July 2026, so yearly mode will show a single year for now; this is expected.
- `FinanceColors` can later be reused for income/expense amounts in the transaction feed and the Home expense widget.

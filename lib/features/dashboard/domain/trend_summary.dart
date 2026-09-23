/// `GET /api/v1/transactions/trend`'s two modes: `month` (12 buckets for one
/// year, ascending) and `year` (one bucket per year the app has data for).
/// [queryValue] is the exact `granularity` query-string value the backend
/// expects — confirmed live against dev (see `trend_mapper.dart`).
enum TrendGranularity {
  month('month'),
  year('year');

  const TrendGranularity(this.queryValue);
  final String queryValue;
}

/// The one legal (granularity, year) pairing, as a value type — replaces a
/// raw `(TrendGranularity, int? year)` family key so an illegal combination
/// (e.g. year-mode carrying a non-null year) can't be constructed at all.
/// [TrendQuery.year] always normalizes `year` to `null`, which is also what
/// keeps `trendProvider`'s cache from growing a duplicate entry per
/// previously-selected year once the UI switches into yearly mode — every
/// caller in yearly mode must go through this constructor rather than
/// passing a stale year along, since the family's cache key is this object's
/// `==`/`hashCode`, not the constructor used to build it.
class TrendQuery {
  const TrendQuery.month(int this.year) : granularity = TrendGranularity.month;
  const TrendQuery.year() : granularity = TrendGranularity.year, year = null;

  final TrendGranularity granularity;
  final int? year;

  @override
  bool operator ==(Object other) =>
      other is TrendQuery &&
      other.granularity == granularity &&
      other.year == year;

  @override
  int get hashCode => Object.hash(granularity, year);
}

/// One bucket of [TrendSummary.buckets] — `month` is `null` only in
/// [TrendGranularity.year] mode.
class TrendBucket {
  const TrendBucket({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.net,
  });

  final int year;
  final int? month;
  final double totalIncome;
  final double totalExpense;
  final double net;
}

/// `GET /api/v1/transactions/trend`'s response `data` — [year] is the
/// top-level requested year in month mode, `null` in year mode (mirrors
/// [TrendBucket.month]'s null-in-year-mode shape one level up). `net` is
/// always taken from the backend per bucket, never recomputed client-side.
class TrendSummary {
  const TrendSummary({
    required this.granularity,
    required this.year,
    required this.buckets,
  });

  final TrendGranularity granularity;
  final int? year;
  final List<TrendBucket> buckets;
}

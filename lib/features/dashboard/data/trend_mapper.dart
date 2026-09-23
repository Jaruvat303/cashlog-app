import '../domain/trend_summary.dart';

/// Wire shape confirmed live against dev (`GET
/// /api/v1/transactions/trend?granularity=month&year=2026` and
/// `?granularity=year`) before F2 merged — matches the documented contract
/// exactly: envelope is `response.Success` (`success`/`message`/`data`, no
/// request_id/timestamp meta), `data.year` and each bucket's `month` are
/// `null` outside their respective mode, and every amount arrives as a JSON
/// int or double (`num` → `toDouble()` below tolerates either, even though
/// live data was all-int at confirmation time).
TrendSummary trendSummaryFromJson(Map<String, dynamic> json) => TrendSummary(
  granularity: json['granularity'] == 'year'
      ? TrendGranularity.year
      : TrendGranularity.month,
  year: json['year'] as int?,
  buckets: (json['buckets'] as List)
      .map((e) => _bucketFromJson(e as Map<String, dynamic>))
      .toList(),
);

TrendBucket _bucketFromJson(Map<String, dynamic> json) => TrendBucket(
  year: json['year'] as int,
  month: json['month'] as int?,
  totalIncome: (json['total_income'] as num).toDouble(),
  totalExpense: (json['total_expense'] as num).toDouble(),
  net: (json['net'] as num).toDouble(),
);

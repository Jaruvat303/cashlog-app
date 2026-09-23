// Fixtures mirror the exact shape confirmed live against dev before F2
// merged (see trend_mapper.dart's doc comment) — amounts here are made up
// (this repo is public), but the field set, nesting, and int-vs-double mix
// match what the backend actually returns.
import 'package:cashlog/features/dashboard/data/trend_mapper.dart';
import 'package:cashlog/features/dashboard/domain/trend_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trendSummaryFromJson parses month mode: 12 ascending buckets, top-level year set', () {
    final summary = trendSummaryFromJson({
      'granularity': 'month',
      'year': 2026,
      'buckets': [
        {
          'year': 2026,
          'month': 1,
          'total_income': 45000,
          'total_expense': 32000,
          'net': 13000,
        },
        {
          'year': 2026,
          'month': 2,
          'total_income': 0,
          'total_expense': 0,
          'net': 0,
        },
        {
          'year': 2026,
          'month': 3,
          'total_income': 38250.75,
          'total_expense': 8250.75,
          'net': 30000.0,
        },
        {
          'year': 2026,
          'month': 4,
          'total_income': 41000,
          'total_expense': 29000,
          'net': 12000,
        },
        {
          'year': 2026,
          'month': 5,
          'total_income': 39500,
          'total_expense': 27500,
          'net': 12000,
        },
        {
          'year': 2026,
          'month': 6,
          'total_income': 42000,
          'total_expense': 31000,
          'net': 11000,
        },
        {
          'year': 2026,
          'month': 7,
          'total_income': 47000,
          'total_expense': 33000,
          'net': 14000,
        },
        {
          'year': 2026,
          'month': 8,
          'total_income': 46000,
          'total_expense': 30000,
          'net': 16000,
        },
        {
          'year': 2026,
          'month': 9,
          'total_income': 48000,
          'total_expense': 34000,
          'net': 14000,
        },
        {
          'year': 2026,
          'month': 10,
          'total_income': 0,
          'total_expense': 0,
          'net': 0,
        },
        {
          'year': 2026,
          'month': 11,
          'total_income': 0,
          'total_expense': 0,
          'net': 0,
        },
        {
          'year': 2026,
          'month': 12,
          'total_income': 0,
          'total_expense': 0,
          'net': 0,
        },
      ],
    });

    expect(summary.granularity, TrendGranularity.month);
    expect(summary.year, 2026);
    expect(summary.buckets, hasLength(12));
    expect(
      summary.buckets.map((b) => b.month),
      List.generate(12, (i) => i + 1),
    );
    expect(summary.buckets.every((b) => b.year == 2026), isTrue);
  });

  test('trendSummaryFromJson parses year mode: month null on the bucket, top-level year null', () {
    final summary = trendSummaryFromJson({
      'granularity': 'year',
      'year': null,
      'buckets': [
        {
          'year': 2026,
          'month': null,
          'total_income': 610250.75,
          'total_expense': 356000,
          'net': 254250.75,
        },
      ],
    });

    expect(summary.granularity, TrendGranularity.year);
    expect(summary.year, isNull);
    expect(summary.buckets, hasLength(1));
    expect(summary.buckets.single.month, isNull);
    expect(summary.buckets.single.year, 2026);
  });

  test(
    'trendSummaryFromJson parses a JSON int amount (including 0) as a double',
    () {
      final summary = trendSummaryFromJson({
        'granularity': 'year',
        'year': null,
        'buckets': [
          {
            'year': 2026,
            'month': null,
            'total_income': 0,
            'total_expense': 356000,
            'net': -356000,
          },
        ],
      });

      final bucket = summary.buckets.single;
      expect(bucket.totalIncome, isA<double>());
      expect(bucket.totalIncome, 0);
      expect(bucket.totalExpense, isA<double>());
      expect(bucket.totalExpense, 356000);
      expect(bucket.net, -356000);
    },
  );

  test('trendSummaryFromJson parses a JSON decimal amount as a double', () {
    final summary = trendSummaryFromJson({
      'granularity': 'month',
      'year': 2026,
      'buckets': [
        {
          'year': 2026,
          'month': 3,
          'total_income': 38250.75,
          'total_expense': 8250.75,
          'net': 30000.0,
        },
      ],
    });

    final bucket = summary.buckets.single;
    expect(bucket.totalIncome, 38250.75);
    expect(bucket.totalExpense, 8250.75);
    expect(bucket.net, 30000.0);
  });
}

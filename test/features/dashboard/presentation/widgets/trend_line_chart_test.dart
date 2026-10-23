import 'package:cashlog/features/dashboard/domain/trend_summary.dart';
import 'package:cashlog/features/dashboard/presentation/widgets/trend_line_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('plots every month through the latest data point', (
    tester,
  ) async {
    final summary = TrendSummary(
      granularity: TrendGranularity.month,
      year: 2024,
      buckets: [
        for (var month = 1; month <= 5; month++)
          TrendBucket(
            year: 2024,
            month: month,
            totalIncome: month <= 3 ? month * 100 : 0,
            totalExpense: month <= 3 ? month * 50 : 0,
            net: month <= 3 ? month * 50 : 0,
          ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TrendLineChart(summary: summary)),
      ),
    );
    await tester.pumpAndSettle();

    final chart = tester.widget<LineChart>(
      find.byKey(const Key('trendLineChart')),
    );
    expect(chart.data.maxX, 2);
    expect(chart.data.lineBarsData, hasLength(2));
    expect(chart.data.lineBarsData.first.spots, hasLength(3));
    expect(chart.data.lineBarsData.first.spots.last.x, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders a single month without error', (tester) async {
    const summary = TrendSummary(
      granularity: TrendGranularity.month,
      year: 2024,
      buckets: [
        TrendBucket(
          year: 2024,
          month: 5,
          totalIncome: 100,
          totalExpense: 50,
          net: 50,
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TrendLineChart(summary: summary)),
      ),
    );
    await tester.pumpAndSettle();

    final chart = tester.widget<LineChart>(
      find.byKey(const Key('trendLineChart')),
    );
    expect(chart.data.maxX, 1);
    expect(chart.data.lineBarsData.first.spots, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders when there are no monthly buckets', (tester) async {
    const summary = TrendSummary(
      granularity: TrendGranularity.month,
      year: 2024,
      buckets: [],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TrendLineChart(summary: summary)),
      ),
    );
    await tester.pumpAndSettle();

    final chart = tester.widget<LineChart>(
      find.byKey(const Key('trendLineChart')),
    );
    expect(chart.data.maxX, 1);
    expect(chart.data.lineBarsData, isEmpty);
    expect(tester.takeException(), isNull);
  });

  group('formatCompactAmount', () {
    test('0 stays a plain whole number', () {
      expect(formatCompactAmount(0), '0');
    });

    test('999 stays a plain whole number', () {
      expect(formatCompactAmount(999), '999');
    });

    test('1000 becomes a whole 1K', () {
      expect(formatCompactAmount(1000), '1K');
    });

    test('1500 becomes 1.5K', () {
      expect(formatCompactAmount(1500), '1.5K');
    });

    test('999999 rolls over to 1M', () {
      expect(formatCompactAmount(999999), '1M');
    });

    test('1000000 becomes a whole 1M', () {
      expect(formatCompactAmount(1000000), '1M');
    });

    test('1200000 becomes 1.2M', () {
      expect(formatCompactAmount(1200000), '1.2M');
    });

    test('negative values keep their sign', () {
      expect(formatCompactAmount(-1500), '-1.5K');
    });
  });
}

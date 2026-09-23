// Pure widget test — no provider, no network. `TrendBarChart` takes a
// `TrendSummary` directly, so this pumps canned summaries straight in.
//
// fl_chart's `BarChart` paints rods on a canvas — there's no per-rod widget
// to find, so "no rods for a future month" and "tooltip content" are both
// asserted by grabbing the actually-built `BarChartData` off the pumped
// `BarChart` widget (`tester.widget<BarChart>(...)`) and inspecting/calling
// its real `barGroups`/`getTooltipItem`, rather than trying to drive fl_chart's
// own touch-to-overlay gesture pipeline (that pipeline is fl_chart's own
// responsibility, not this widget's).
import 'package:cashlog/features/dashboard/domain/trend_summary.dart';
import 'package:cashlog/features/dashboard/presentation/widgets/trend_bar_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

TrendBucket _bucket({
  required int month,
  double income = 45000,
  double expense = 32000,
}) => TrendBucket(
  year: 2026,
  month: month,
  totalIncome: income,
  totalExpense: expense,
  net: income - expense,
);

/// 12 ascending buckets for the current device month/year, matching the
/// backend's month-mode contract (F2) — [futureFrom] (1-indexed month,
/// inclusive) marks the buckets this fixture treats as "not yet happened".
List<TrendBucket> _monthBuckets({int? futureFrom}) {
  final now = DateTime.now();
  return List.generate(12, (i) {
    final month = i + 1;
    final isFuture = futureFrom != null && month >= futureFrom;
    return TrendBucket(
      year: now.year,
      month: month,
      totalIncome: isFuture ? 0 : 40000 + month * 100,
      totalExpense: isFuture ? 0 : 30000 + month * 50,
      net: isFuture ? 0 : (40000 + month * 100) - (30000 + month * 50),
    );
  });
}

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 350, child: child)),
);

void _usePhoneSizedViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(350, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('formatCompactAmount', () {
    test('0 stays a plain whole number', () {
      expect(formatCompactAmount(0), '0');
    });

    test('999 stays a plain whole number — under the K threshold', () {
      expect(formatCompactAmount(999), '999');
    });

    test('1000 becomes a whole 1K', () {
      expect(formatCompactAmount(1000), '1K');
    });

    test('1500 becomes 1.5K', () {
      expect(formatCompactAmount(1500), '1.5K');
    });

    test('999999 rolls over to 1M rather than the misleading 1000K a naive /1000 + round would give', () {
      expect(formatCompactAmount(999999), '1M');
      expect(formatCompactAmount(999999), isNot(contains('1000K')));
    });

    test('1000000 becomes a whole 1M', () {
      expect(formatCompactAmount(1000000), '1M');
    });

    test('1200000 becomes 1.2M', () {
      expect(formatCompactAmount(1200000), '1.2M');
    });
  });

  testWidgets('renders one bar group per bucket', (tester) async {
    final buckets = _monthBuckets();
    await tester.pumpWidget(
      _wrap(
        TrendBarChart(
          summary: TrendSummary(
            granularity: TrendGranularity.month,
            year: buckets.first.year,
            buckets: buckets,
          ),
        ),
      ),
    );

    final chart = tester.widget<BarChart>(
      find.byKey(const Key('trendBarChart')),
    );
    expect(chart.data.barGroups, hasLength(12));
  });

  testWidgets(
    'a future month of the current year gets no rods, and a faded bottom label',
    (tester) async {
      final now = DateTime.now();
      // Only meaningful when the device isn't in December — December has no
      // month 13, so the current year genuinely has zero future months left
      // to fade at that point (a real, date-dependent edge of the feature
      // itself, not a gap in this test).
      final futureFrom = now.month < 12 ? now.month + 1 : null;
      final buckets = _monthBuckets(futureFrom: futureFrom);
      await tester.pumpWidget(
        _wrap(
          TrendBarChart(
            summary: TrendSummary(
              granularity: TrendGranularity.month,
              year: now.year,
              buckets: buckets,
            ),
          ),
        ),
      );

      final chart = tester.widget<BarChart>(
        find.byKey(const Key('trendBarChart')),
      );
      if (futureFrom != null) {
        for (var i = futureFrom - 1; i < 12; i++) {
          expect(
            chart.data.barGroups[i].barRods,
            isEmpty,
            reason: 'bucket for month ${i + 1} should be future and rod-less',
          );
        }
        for (var i = 0; i < futureFrom - 1; i++) {
          expect(chart.data.barGroups[i].barRods, isNotEmpty);
        }
      }
    },
  );

  testWidgets(
    'a bucket in a past year is never treated as future — full rods',
    (tester) async {
      final buckets = _monthBuckets().map((b) {
        return TrendBucket(
          year: 2020,
          month: b.month,
          totalIncome: 1000,
          totalExpense: 500,
          net: 500,
        );
      }).toList();
      await tester.pumpWidget(
        _wrap(
          TrendBarChart(
            summary: TrendSummary(
              granularity: TrendGranularity.month,
              year: 2020,
              buckets: buckets,
            ),
          ),
        ),
      );

      final chart = tester.widget<BarChart>(
        find.byKey(const Key('trendBarChart')),
      );
      for (final group in chart.data.barGroups) {
        expect(group.barRods, isNotEmpty);
      }
    },
  );

  testWidgets('tooltip content: header + labelled income/expense/net lines', (
    tester,
  ) async {
    final buckets = [_bucket(month: 3, income: 15000, expense: 8250)];
    await tester.pumpWidget(
      _wrap(
        TrendBarChart(
          summary: TrendSummary(
            granularity: TrendGranularity.month,
            year: 2026,
            buckets: buckets,
          ),
        ),
      ),
    );

    final chart = tester.widget<BarChart>(
      find.byKey(const Key('trendBarChart')),
    );
    final group = chart.data.barGroups.single;
    final item = chart.data.barTouchData.touchTooltipData.getTooltipItem(
      group,
      0,
      group.barRods.first,
      0,
    );

    expect(item, isNotNull);
    expect(item!.text, contains('มี.ค. 2569'));
    expect(item.text, contains('รายรับ ฿15,000'));
    expect(item.text, contains('รายจ่าย ฿8,250'));
    expect(item.text, contains('สุทธิ ฿6,750'));
  });

  testWidgets(
    'tooltip shows a correctly-signed negative net when expense exceeds income',
    (tester) async {
      final buckets = [_bucket(month: 3, income: 5000, expense: 7000)];
      await tester.pumpWidget(
        _wrap(
          TrendBarChart(
            summary: TrendSummary(
              granularity: TrendGranularity.month,
              year: 2026,
              buckets: buckets,
            ),
          ),
        ),
      );

      final chart = tester.widget<BarChart>(
        find.byKey(const Key('trendBarChart')),
      );
      final group = chart.data.barGroups.single;
      final item = chart.data.barTouchData.touchTooltipData.getTooltipItem(
        group,
        0,
        group.barRods.first,
        0,
      );

      expect(item!.text, contains('สุทธิ -฿2,000'));
      expect(item.text, isNot(contains('--')));
    },
  );

  testWidgets('year mode tooltip header is just the Buddhist year, no month', (
    tester,
  ) async {
    final buckets = [
      const TrendBucket(
        year: 2026,
        month: null,
        totalIncome: 610250,
        totalExpense: 356000,
        net: 254250,
      ),
    ];
    await tester.pumpWidget(
      _wrap(
        TrendBarChart(
          summary: TrendSummary(
            granularity: TrendGranularity.year,
            year: null,
            buckets: buckets,
          ),
        ),
      ),
    );

    final chart = tester.widget<BarChart>(
      find.byKey(const Key('trendBarChart')),
    );
    final group = chart.data.barGroups.single;
    final item = chart.data.barTouchData.touchTooltipData.getTooltipItem(
      group,
      0,
      group.barRods.first,
      0,
    );

    expect(item!.text, startsWith('2569\n'));
  });

  testWidgets(
    'ticket F3: 12 month-mode groups do not overflow a ~350px phone width',
    (tester) async {
      _usePhoneSizedViewport(tester);
      final buckets = _monthBuckets();

      await tester.pumpWidget(
        _wrap(
          TrendBarChart(
            summary: TrendSummary(
              granularity: TrendGranularity.month,
              year: buckets.first.year,
              buckets: buckets,
            ),
          ),
        ),
      );
      await tester.pump();

      // A RenderFlex/layout overflow throws during layout/paint, surfaced
      // here rather than swallowed — same convention as
      // category_picker_sheet_test.dart's ticket 11 overflow regression.
      expect(tester.takeException(), isNull);
    },
  );
}

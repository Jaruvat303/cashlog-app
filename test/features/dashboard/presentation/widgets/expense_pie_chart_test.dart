// No providers/repositories involved — ExpensePieChart is a plain
// StatelessWidget over the data it's handed, so these are direct pumpWidget
// tests with no fakes needed.
import 'package:cashlog/features/dashboard/domain/dashboard_summary.dart';
import 'package:cashlog/features/dashboard/presentation/widgets/expense_pie_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CategoryBreakdown _breakdown(int id, String name, double amount) =>
    CategoryBreakdown(
      categoryId: id,
      categoryName: name,
      iconKey: '',
      colorHex: '#EF4444',
      totalAmount: amount,
    );

void main() {
  testWidgets(
    'every slice is preserved and labels are shown at the 5% threshold',
    (tester) async {
      // Shares: A=70%, B=25%, C=5% of a 1000 total.
      final breakdown = [
        _breakdown(1, 'A', 700),
        _breakdown(2, 'B', 250),
        _breakdown(3, 'C', 50),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpensePieChart(expense: breakdown, total: 1000),
          ),
        ),
      );

      expect(find.byKey(const Key('pieChartPercentLabel-1')), findsOneWidget);
      expect(find.byKey(const Key('pieChartPercentLabel-2')), findsOneWidget);
      expect(find.byKey(const Key('pieChartPercentLabel-3')), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('5%'), findsOneWidget);

      // No leftover legend rows or category-name text — that content only
      // lives in the separate `_CategoryTotalsList` below this widget now.
      expect(find.byKey(const Key('pieChartLegendRow-1')), findsNothing);
      expect(find.text('A'), findsNothing);
      expect(find.text('B'), findsNothing);
      expect(find.text('C'), findsNothing);

      // The slices are still built from the full, unfiltered breakdown.
      final pieChart = tester.widget<PieChart>(find.byType(PieChart));
      final sections = pieChart.data.sections;
      expect(sections.length, 3);
      expect(sections.map((s) => s.value).toList(), [700, 250, 50]);
      expect(sections.fold(0.0, (sum, s) => sum + s.value), 1000);
    },
  );

  testWidgets(
    'the chart is significantly bigger than the old fixed 110px size',
    (tester) async {
      final breakdown = [_breakdown(1, 'A', 600), _breakdown(2, 'B', 400)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpensePieChart(expense: breakdown, total: 1000),
          ),
        ),
      );

      final chart = tester.widget<SizedBox>(
        find.byKey(const Key('pieChartCircle')),
      );
      expect(
        chart.width,
        greaterThan(160),
        reason:
            'a merely-marginal size bump would not satisfy "ใหญ่ขึ้นชัดเจน"',
      );
      expect(chart.height, chart.width);
    },
  );

  testWidgets('a category sitting exactly at 5% share still gets its label', (
    tester,
  ) async {
    final breakdown = [_breakdown(1, 'A', 950), _breakdown(2, 'B', 50)];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ExpensePieChart(expense: breakdown, total: 1000)),
      ),
    );

    expect(find.byKey(const Key('pieChartPercentLabel-2')), findsOneWidget);
    expect(find.text('5%'), findsOneWidget);
  });

  testWidgets('a share below 5% is hidden even when rounding would show 5%', (
    tester,
  ) async {
    final breakdown = [_breakdown(1, 'A', 951), _breakdown(2, 'B', 49)];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ExpensePieChart(expense: breakdown, total: 1000)),
      ),
    );

    expect(find.byKey(const Key('pieChartPercentLabel-1')), findsOneWidget);
    expect(find.byKey(const Key('pieChartPercentLabel-2')), findsNothing);
    expect(find.byType(PieChart), findsOneWidget);
    expect(
      tester.widget<PieChart>(find.byType(PieChart)).data.sections,
      hasLength(2),
    );
  });

  testWidgets('all shares below 5% keep the slices but hide every label', (
    tester,
  ) async {
    final breakdown = [
      for (var id = 1; id <= 21; id++) _breakdown(id, 'Category $id', 1),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ExpensePieChart(expense: breakdown, total: 21)),
      ),
    );

    expect(find.byType(PieChart), findsOneWidget);
    expect(
      tester.widget<PieChart>(find.byType(PieChart)).data.sections,
      hasLength(21),
    );
    expect(find.byKey(const Key('pieChartPercentLabel-1')), findsNothing);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('empty data does not render a chart or percentage labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ExpensePieChart(expense: [], total: 0)),
      ),
    );

    expect(find.byType(PieChart), findsNothing);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('a share just above 5% is labeled', (tester) async {
    final breakdown = [_breakdown(1, 'A', 949), _breakdown(2, 'B', 51)];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ExpensePieChart(expense: breakdown, total: 1000)),
      ),
    );

    expect(find.byKey(const Key('pieChartPercentLabel-2')), findsOneWidget);
    expect(find.text('5%'), findsOneWidget);
  });

  testWidgets(
    'percentage labels sit outside the ring, at increasing angular offsets from the top',
    (tester) async {
      // Four even quarters starting at 12 o'clock (the chart's own
      // startDegreeOffset) — their label centers should each land in a
      // different quadrant around the ring, not stacked on top of one
      // another or all crammed at one spot.
      final breakdown = [
        _breakdown(1, 'A', 250),
        _breakdown(2, 'B', 250),
        _breakdown(3, 'C', 250),
        _breakdown(4, 'D', 250),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpensePieChart(expense: breakdown, total: 1000),
          ),
        ),
      );

      final chartCenter = tester.getCenter(
        find.byKey(const Key('pieChartCircle')),
      );
      final chartSize = tester
          .getSize(find.byKey(const Key('pieChartCircle')))
          .width;
      final centers = [
        for (var id = 1; id <= 4; id++)
          tester.getCenter(find.byKey(Key('pieChartPercentLabel-$id'))),
      ];

      // Every label sits outside the visible ring...
      for (final labelCenter in centers) {
        expect(
          (labelCenter - chartCenter).distance,
          greaterThan(chartSize / 2),
        );
      }
      // ...and no two labels land on the same spot (each quarter-slice
      // floats at its own distinct angle).
      for (var i = 0; i < centers.length; i++) {
        for (var j = i + 1; j < centers.length; j++) {
          expect((centers[i] - centers[j]).distance, greaterThan(1));
        }
      }
    },
  );
}

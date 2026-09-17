// Ticket 03: verifies the two acceptance criteria specific to the pie
// chart's own legend-decluttering behavior — a legend row is omitted once
// its share drops under 10% of the total, while the chart's slices
// themselves keep representing true proportions (summing to the total)
// regardless of which legend rows are hidden. No providers/repositories
// involved — ExpensePieChart is a plain StatelessWidget over the data it's
// handed, so this is a direct pumpWidget test, no fakes needed.
import 'package:cashlog/features/dashboard/domain/dashboard_summary.dart';
import 'package:cashlog/features/dashboard/presentation/widgets/expense_pie_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CategoryBreakdown _breakdown(int id, String name, double amount) =>
    CategoryBreakdown(categoryId: id, categoryName: name, iconKey: '', colorHex: '#EF4444', totalAmount: amount);

void main() {
  testWidgets('omits legend rows under 10% share while the pie itself keeps every slice', (tester) async {
    // Shares: A=70%, B=25%, C=5% of a 1000 total — only C falls under 10%.
    final breakdown = [_breakdown(1, 'A', 700), _breakdown(2, 'B', 250), _breakdown(3, 'C', 50)];

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ExpensePieChart(expense: breakdown, total: 1000))),
    );

    expect(find.byKey(const Key('pieChartLegendRow-1')), findsOneWidget);
    expect(find.byKey(const Key('pieChartLegendRow-2')), findsOneWidget);
    expect(find.byKey(const Key('pieChartLegendRow-3')), findsNothing);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsNothing);
    expect(find.text('70%'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(find.text('5%'), findsNothing);

    // The slices are built from the full, unfiltered breakdown — hiding C's
    // legend row must never drop or shrink its slice.
    final pieChart = tester.widget<PieChart>(find.byType(PieChart));
    final sections = pieChart.data.sections;
    expect(sections.length, 3);
    expect(sections.map((s) => s.value).toList(), [700, 250, 50]);
    expect(sections.fold(0.0, (sum, s) => sum + s.value), 1000);
  });

  testWidgets('shows every legend row when every category clears the 10% threshold', (tester) async {
    final breakdown = [_breakdown(1, 'A', 600), _breakdown(2, 'B', 400)];

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ExpensePieChart(expense: breakdown, total: 1000))),
    );

    expect(find.byKey(const Key('pieChartLegendRow-1')), findsOneWidget);
    expect(find.byKey(const Key('pieChartLegendRow-2')), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
  });

  testWidgets('a category sitting exactly at 10% share keeps its legend row', (tester) async {
    final breakdown = [_breakdown(1, 'A', 900), _breakdown(2, 'B', 100)];

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ExpensePieChart(expense: breakdown, total: 1000))),
    );

    expect(find.byKey(const Key('pieChartLegendRow-2')), findsOneWidget);
  });
}

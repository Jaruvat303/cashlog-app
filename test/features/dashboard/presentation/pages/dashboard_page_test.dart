// Before any pumpWidget/pumpAndSettle, dashboardRepositoryProvider is
// overridden with a hand-written fake (same pattern as
// _FakeAccountsRepository in test/widget_test.dart) — this is what keeps a
// real dio call from ever reaching Flutter's test HTTP stub.
import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/dashboard/data/dashboard_repository.dart';
import 'package:cashlog/features/dashboard/domain/dashboard_summary.dart';
import 'package:cashlog/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:dartz/dartz.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDashboardRepository implements DashboardRepository {
  final Map<(int, int), Either<Failure, DashboardSummary>> results = {};
  final List<(int, int)> fetchCalls = [];

  @override
  Future<Either<Failure, DashboardSummary>> fetchSummary({required int year, required int month}) async {
    fetchCalls.add((year, month));
    return results[(year, month)] ?? const Left(UnknownFailure(message: 'no result configured for this month'));
  }
}

CategoryBreakdown _breakdown(int id, String name, double amount, {String iconKey = 'restaurant-fill', String colorHex = '#EF4444'}) =>
    CategoryBreakdown(categoryId: id, categoryName: name, iconKey: iconKey, colorHex: colorHex, totalAmount: amount);

/// pumpAndSettle can't tell "still legitimately loading" from "stuck
/// forever" — a bounded pump loop fails fast instead (same reasoning as
/// test/widget_test.dart's `_pumpBounded`).
Future<void> _pumpBounded(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late _FakeDashboardRepository fakeRepository;
  late DateTime thisMonth;

  setUp(() {
    fakeRepository = _FakeDashboardRepository();
    final now = DateTime.now();
    thisMonth = DateTime.utc(now.year, now.month);
  });

  Widget buildApp() => ProviderScope(
    overrides: [dashboardRepositoryProvider.overrideWithValue(fakeRepository)],
    child: const MaterialApp(home: DashboardPage()),
  );

  testWidgets('renders totals from the summary and never shows total_transfer', (tester) async {
    fakeRepository.results[(thisMonth.year, thisMonth.month)] = Right(
      DashboardSummary(
        totalIncome: 5000,
        totalExpense: 2000,
        totalTransfer: 999999,
        year: thisMonth.year,
        month: thisMonth.month,
        income: const [],
        expense: [_breakdown(1, 'Food', 2000)],
      ),
    );

    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);

    expect(find.text('5000.00'), findsOneWidget);
    expect(find.text('2000.00'), findsNWidgets(2)); // total expense card + the one expense row
    expect(find.text('3000.00'), findsOneWidget); // net
    expect(find.text('999999.00'), findsNothing);
    expect(find.textContaining('999999'), findsNothing);
  });

  testWidgets('expense rows render sorted descending by amount, with a pie chart', (tester) async {
    fakeRepository.results[(thisMonth.year, thisMonth.month)] = Right(
      DashboardSummary(
        totalIncome: 0,
        totalExpense: 300,
        totalTransfer: 0,
        year: thisMonth.year,
        month: thisMonth.month,
        income: const [],
        expense: [_breakdown(1, 'Small', 50), _breakdown(2, 'Big', 200), _breakdown(3, 'Medium', 50)],
      ),
    );

    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);

    expect(find.byType(PieChart), findsOneWidget);
    final names = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
    expect(names.indexOf('Big'), lessThan(names.indexOf('Small')));
  });

  testWidgets('shows an empty-state message instead of a chart when expense is empty', (tester) async {
    fakeRepository.results[(thisMonth.year, thisMonth.month)] = Right(
      DashboardSummary(
        totalIncome: 1000,
        totalExpense: 0,
        totalTransfer: 0,
        year: thisMonth.year,
        month: thisMonth.month,
        income: const [],
        expense: const [],
      ),
    );

    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);

    expect(find.text('No expenses this month'), findsOneWidget);
    expect(find.byType(PieChart), findsNothing);
  });

  testWidgets('switching month via the shared selector refetches and swaps displayed totals', (tester) async {
    // Expense deliberately nonzero and distinct from income so "net" never
    // collides in text with "income"/"expense" (net = income - expense).
    final nextMonth = DateTime.utc(thisMonth.year, thisMonth.month + 1);
    fakeRepository.results[(thisMonth.year, thisMonth.month)] = Right(
      DashboardSummary(totalIncome: 100, totalExpense: 30, totalTransfer: 0, year: thisMonth.year, month: thisMonth.month, income: const [], expense: const []),
    );
    fakeRepository.results[(nextMonth.year, nextMonth.month)] = Right(
      DashboardSummary(totalIncome: 700, totalExpense: 200, totalTransfer: 0, year: nextMonth.year, month: nextMonth.month, income: const [], expense: const []),
    );

    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);
    expect(find.text('100.00'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await _pumpBounded(tester);

    expect(find.text('100.00'), findsNothing);
    expect(find.text('700.00'), findsOneWidget);
    expect(fakeRepository.fetchCalls, contains((nextMonth.year, nextMonth.month)));
  });
}

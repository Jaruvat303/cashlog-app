import 'dart:async';

import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/dashboard/data/dashboard_repository.dart';
import 'package:cashlog/features/dashboard/domain/dashboard_summary.dart';
import 'package:cashlog/features/dashboard/domain/trend_summary.dart';
import 'package:cashlog/features/dashboard/presentation/pages/trend_page.dart';
import 'package:dartz/dartz.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDashboardRepository implements DashboardRepository {
  final Map<TrendQuery, Either<Failure, TrendSummary>> trendResults = {};
  final Map<int, Either<Failure, DashboardSummary>> summaryResults = {};
  final Map<int, Completer<Either<Failure, DashboardSummary>>>
  pendingSummaries = {};
  final List<TrendQuery> trendCalls = [];
  final List<int> yearlySummaryCalls = [];

  @override
  Future<Either<Failure, DashboardSummary>> fetchSummary({
    required int year,
    required int month,
  }) => throw UnimplementedError('monthly summary is not used here');

  @override
  Future<Either<Failure, DashboardSummary>> fetchYearlySummary({
    required int year,
  }) async {
    yearlySummaryCalls.add(year);
    if (pendingSummaries.containsKey(year)) {
      return pendingSummaries[year]!.future;
    }
    return summaryResults[year] ??
        const Left(UnknownFailure(message: 'yearly summary not configured'));
  }

  @override
  Future<Either<Failure, TrendSummary>> fetchTrend(TrendQuery query) async {
    trendCalls.add(query);
    return trendResults[query] ??
        const Left(UnknownFailure(message: 'trend not configured'));
  }
}

final _currentYear = DateTime.now().toUtc().add(const Duration(hours: 7)).year;
final _firstYear = _currentYear - 2;
final _currentMonth = DateTime.now()
    .toUtc()
    .add(const Duration(hours: 7))
    .month;
final _firstActiveMonth = _currentMonth < 5 ? _currentMonth : 5;

DashboardSummary _summary({
  int year = 2026,
  double income = 38430,
  double expense = 17002.52,
}) => DashboardSummary(
  totalIncome: income,
  totalExpense: expense,
  totalTransfer: 999999,
  year: year,
  month: 1,
  income: income == 0
      ? const []
      : [
          CategoryBreakdown(
            categoryId: 7,
            categoryName: 'เงินเดือน',
            iconKey: 'wallet-3-fill',
            colorHex: '#22B573',
            totalAmount: income,
          ),
        ],
  expense: expense == 0
      ? const []
      : expense == 17002.52
      ? const [
          CategoryBreakdown(
            categoryId: 1,
            categoryName: 'อาหาร',
            iconKey: 'restaurant-fill',
            colorHex: '#EF4444',
            totalAmount: 9000,
          ),
          CategoryBreakdown(
            categoryId: 2,
            categoryName: 'เดินทาง',
            iconKey: 'car-fill',
            colorHex: '#3B82F6',
            totalAmount: 4002.52,
          ),
          CategoryBreakdown(
            categoryId: 0,
            categoryName: 'Uncategorized',
            iconKey: 'folder',
            colorHex: '#CCCCCC',
            totalAmount: 4000,
          ),
        ]
      : [
          CategoryBreakdown(
            categoryId: 1,
            categoryName: 'อาหาร',
            iconKey: 'restaurant-fill',
            colorHex: '#EF4444',
            totalAmount: expense / 2,
          ),
          CategoryBreakdown(
            categoryId: 0,
            categoryName: 'Uncategorized',
            iconKey: 'folder',
            colorHex: '#CCCCCC',
            totalAmount: expense / 2,
          ),
        ],
);

TrendSummary _monthTrend(
  int year, {
  double income = 38430,
  double expense = 17002.52,
  int? startMonth,
}) {
  final currentMonth = year == _currentYear
      ? DateTime.now().toUtc().add(const Duration(hours: 7)).month
      : 12;
  final firstActiveMonth = startMonth ?? _firstActiveMonth;
  final activeMonthCount = currentMonth - firstActiveMonth + 1;
  return TrendSummary(
    granularity: TrendGranularity.month,
    year: year,
    buckets: List.generate(12, (index) {
      final month = index + 1;
      final active = month >= firstActiveMonth && month <= currentMonth;
      return TrendBucket(
        year: year,
        month: month,
        totalIncome: active ? income / activeMonthCount : 0,
        totalExpense: active ? expense / activeMonthCount : 0,
        net: active ? (income - expense) / activeMonthCount : 0,
      );
    }),
  );
}

TrendSummary _yearTrend({bool empty = false, int? firstYear}) {
  final earliestYear = firstYear ?? _firstYear;
  return TrendSummary(
    granularity: TrendGranularity.year,
    year: null,
    buckets: empty
        ? const []
        : [
            for (var year = earliestYear; year <= _currentYear; year++)
              TrendBucket(
                year: year,
                month: null,
                totalIncome: 100,
                totalExpense: 50,
                net: 50,
              ),
          ],
  );
}

Widget _buildApp(_FakeDashboardRepository fake) => ProviderScope(
  overrides: [dashboardRepositoryProvider.overrideWithValue(fake)],
  child: const MaterialApp(home: TrendPage()),
);

void _configureYear(_FakeDashboardRepository fake, int year) {
  fake.trendResults[TrendQuery.month(year)] = Right(_monthTrend(year));
  fake.summaryResults[year] = Right(_summary(year: year));
}

void main() {
  late _FakeDashboardRepository fake;

  setUp(() {
    fake = _FakeDashboardRepository()
      ..trendResults[const TrendQuery.year()] = Right(_yearTrend());
    for (var year = _firstYear; year <= _currentYear; year++) {
      _configureYear(fake, year);
    }
  });

  testWidgets('shows the yearly trend, KPI cards and initial category tab', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(fake));
    await tester.pumpAndSettle();

    expect(find.text('สรุปรายปี'), findsOneWidget);
    expect(find.text('รายเดือน'), findsNothing);
    expect(find.text('รายปี'), findsNothing);
    expect(find.text('${_currentYear + 543}'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);
    expect(find.text('รายรับรวม'), findsOneWidget);
    expect(find.text('รายจ่ายรวม'), findsOneWidget);
    expect(find.text('เงินเหลือสุทธิ'), findsOneWidget);
    expect(find.text('อัตราการออม'), findsOneWidget);
    expect(find.text('฿21,427.48'), findsOneWidget);
    expect(find.text('55.8%'), findsOneWidget);
    expect(fake.trendCalls.where((query) => query == const TrendQuery.year()), [
      const TrendQuery.year(),
    ]);
    expect(fake.yearlySummaryCalls, [_currentYear]);
    expect(fake.trendCalls, contains(TrendQuery.month(_currentYear)));
    expect(find.byKey(const Key('yearlyExpenseTab')), findsOneWidget);
    expect(find.text('อาหาร'), findsOneWidget);
  });

  testWidgets('chart has two monthly lines and stops before future months', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(fake));
    await tester.pumpAndSettle();

    final chart = tester.widget<LineChart>(
      find.byKey(const Key('trendLineChart')),
    );
    expect(chart.data.lineBarsData, hasLength(2));
    final currentMonth = DateTime.now()
        .toUtc()
        .add(const Duration(hours: 7))
        .month;
    for (final line in chart.data.lineBarsData) {
      expect(line.spots, hasLength(currentMonth));
      expect(line.spots.last.x, currentMonth - 1);
      expect(line.dotData.show, isTrue);
    }
    final line = chart.data.lineBarsData.first;
    final tooltipItems = chart.data.lineTouchData.touchTooltipData
        .getTooltipItems([LineBarSpot(line, 0, line.spots[4])]);
    expect(tooltipItems.single!.text, contains('รายรับ:'));
    expect(tooltipItems.single!.text, contains('รายจ่าย:'));
    expect(tooltipItems.single!.text, contains('สุทธิ:'));
  });

  testWidgets('averages exclude months before the first active month', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(fake));
    await tester.pumpAndSettle();

    final months = DateTime.now().toUtc().add(const Duration(hours: 7)).month;
    final count = months - _firstActiveMonth + 1;
    expect(
      find.text('เฉลี่ย ${formatYearlyAmount(38430 / count)} / เดือน'),
      findsOneWidget,
    );
  });

  testWidgets('sorts all categories and pins uncategorized last with shares', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(fake));
    await tester.pumpAndSettle();

    final food = tester.getTopLeft(
      find.byKey(const Key('yearlyCategoryName1')),
    );
    final transport = tester.getTopLeft(
      find.byKey(const Key('yearlyCategoryName2')),
    );
    final uncategorized = tester.getTopLeft(
      find.byKey(const Key('yearlyCategoryName0')),
    );
    expect(food.dy, lessThan(transport.dy));
    expect(transport.dy, lessThan(uncategorized.dy));
    expect(find.text('ไม่ระบุหมวด'), findsOneWidget);
    expect(find.text('52.9%'), findsOneWidget);
    expect(find.text('23.5%'), findsNWidgets(2));
    expect(find.text('฿17,002.52'), findsNWidgets(2));
    expect(find.text('฿9,000'), findsOneWidget);
    expect(find.text('฿4,002.52'), findsOneWidget);
    expect(find.text('฿4,000'), findsOneWidget);
  });

  testWidgets('income tab remains selected while changing years', (
    tester,
  ) async {
    final previousYear = _currentYear - 1;
    await tester.pumpWidget(_buildApp(fake));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('yearlyIncomeTab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('yearlyIncomeTab')));
    await tester.pumpAndSettle();
    expect(find.text('เงินเดือน'), findsOneWidget);
    expect(find.text('อาหาร'), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('trendYearBack')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('trendYearBack')));
    await tester.pumpAndSettle();

    expect(find.text('เงินเดือน'), findsOneWidget);
    expect(find.text('อาหาร'), findsNothing);
    expect(fake.yearlySummaryCalls, contains(previousYear));
  });

  testWidgets(
    'shows KPI and chart skeletons while a newly selected year loads',
    (tester) async {
      final previousYear = _currentYear - 1;
      final pending = Completer<Either<Failure, DashboardSummary>>();
      fake.pendingSummaries[previousYear] = pending;

      await tester.pumpWidget(_buildApp(fake));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('trendYearBack')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('trendYearBack')));
      await tester.pump();

      expect(find.byKey(const Key('yearlyKpiSkeleton')), findsOneWidget);
      expect(find.byKey(const Key('yearlySummaryKpiGrid')), findsNothing);

      fake.pendingSummaries.remove(previousYear);
      pending.complete(Right(_summary(year: previousYear)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('yearlySummaryKpiGrid')), findsOneWidget);
    },
  );

  testWidgets('shows a dash for zero income and a signed negative net', (
    tester,
  ) async {
    fake.trendResults[TrendQuery.month(_currentYear)] = Right(
      _monthTrend(_currentYear, income: 0, expense: 100),
    );
    fake.summaryResults[_currentYear] = Right(
      _summary(year: _currentYear, income: 0, expense: 100),
    );

    await tester.pumpWidget(_buildApp(fake));
    await tester.pumpAndSettle();

    expect(find.text('—'), findsOneWidget);
    expect(find.text('-฿100'), findsOneWidget);
    expect(find.text('฿999,999'), findsNothing);
  });

  testWidgets('negative savings rate and net keep an explicit minus sign', (
    tester,
  ) async {
    fake.trendResults[TrendQuery.month(_currentYear)] = Right(
      _monthTrend(_currentYear, income: 100, expense: 200),
    );
    fake.summaryResults[_currentYear] = Right(
      _summary(year: _currentYear, income: 100, expense: 200),
    );

    await tester.pumpWidget(_buildApp(fake));
    await tester.pumpAndSettle();

    expect(find.text('-฿100'), findsOneWidget);
    expect(find.text('-100.0%'), findsOneWidget);
  });

  testWidgets('an empty income category tab explains that it has no entries', (
    tester,
  ) async {
    fake.trendResults[TrendQuery.month(_currentYear)] = Right(
      _monthTrend(_currentYear, income: 0),
    );
    fake.summaryResults[_currentYear] = Right(
      _summary(year: _currentYear, income: 0),
    );

    await tester.pumpWidget(_buildApp(fake));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('yearlyIncomeTab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('yearlyIncomeTab')));
    await tester.pumpAndSettle();

    expect(find.text('ไม่มีรายรับในปีนี้'), findsOneWidget);
  });

  testWidgets('empty account history hides year arrows and skips summary', (
    tester,
  ) async {
    fake.trendResults[const TrendQuery.year()] = Right(_yearTrend(empty: true));

    await tester.pumpWidget(_buildApp(fake));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('yearlySummaryEmpty')), findsOneWidget);
    expect(find.text('ยังไม่มีรายการ'), findsOneWidget);
    expect(find.text('${_currentYear + 543}'), findsOneWidget);
    expect(find.byKey(const Key('trendYearBack')), findsNothing);
    expect(find.byKey(const Key('trendYearForward')), findsNothing);
    expect(fake.yearlySummaryCalls, isEmpty);
    expect(
      fake.trendCalls.where((q) => q.granularity == TrendGranularity.month),
      isEmpty,
    );
  });

  testWidgets('year switcher is disabled at both bounds', (tester) async {
    await tester.pumpWidget(_buildApp(fake));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('trendYearBack')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('trendYearBack')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('trendYearBack')));
    await tester.pumpAndSettle();

    expect(find.text('${_firstYear + 543}'), findsOneWidget);
    final callsAtEarliest = fake.yearlySummaryCalls.length;
    await tester.tap(find.byKey(const Key('trendYearBack')));
    await tester.pumpAndSettle();
    expect(fake.yearlySummaryCalls.length, callsAtEarliest);

    await tester.tap(find.byKey(const Key('trendYearForward')));
    await tester.pumpAndSettle();
    expect(find.text('${2025 + 543}'), findsOneWidget);
  });

  testWidgets('loading and failure do not show partial yearly data', (
    tester,
  ) async {
    final pending = Completer<Either<Failure, DashboardSummary>>();
    fake.pendingSummaries[_currentYear] = pending;
    await tester.pumpWidget(_buildApp(fake));
    await tester.pump();

    expect(find.byKey(const Key('yearlyKpiSkeleton')), findsOneWidget);
    fake.pendingSummaries.remove(_currentYear);
    fake.summaryResults[_currentYear] = const Left(
      UnknownFailure(message: 'summary unavailable'),
    );
    pending.complete(
      const Left(UnknownFailure(message: 'summary unavailable')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('โหลดสรุปรายปีไม่สำเร็จ'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
    expect(find.text('รายรับรวม'), findsNothing);

    fake.summaryResults[_currentYear] = Right(_summary(year: _currentYear));
    await tester.tap(find.byKey(const Key('yearlySummaryRetryButton')));
    await tester.pumpAndSettle();

    expect(find.text('฿21,427.48'), findsOneWidget);
  });

  testWidgets('a trend failure also hides all yearly summary content', (
    tester,
  ) async {
    fake.trendResults[TrendQuery.month(_currentYear)] = const Left(
      UnknownFailure(message: 'trend unavailable'),
    );

    await tester.pumpWidget(_buildApp(fake));
    await tester.pumpAndSettle();

    expect(find.textContaining('โหลดสรุปรายปีไม่สำเร็จ'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
    expect(find.text('รายรับรวม'), findsNothing);
    expect(fake.yearlySummaryCalls, contains(_currentYear));
  });
}

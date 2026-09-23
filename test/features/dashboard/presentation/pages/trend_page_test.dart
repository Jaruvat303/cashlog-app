// Before any pumpWidget/pumpAndSettle, dashboardRepositoryProvider is
// overridden with a hand-written fake (same pattern as
// dashboard_page_test.dart / cache_invalidator_test.dart) — this never lets
// a real dio call hit Flutter's test HTTP stub (CLAUDE.md).
import 'dart:async';

import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/dashboard/data/dashboard_repository.dart';
import 'package:cashlog/features/dashboard/domain/dashboard_summary.dart';
import 'package:cashlog/features/dashboard/domain/trend_summary.dart';
import 'package:cashlog/features/dashboard/presentation/pages/trend_page.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDashboardRepository implements DashboardRepository {
  final Map<TrendQuery, Either<Failure, TrendSummary>> nextResultByQuery = {};
  final List<TrendQuery> fetchTrendCalls = [];

  /// Queries in here never resolve — used to hold `trendProvider(query)` in
  /// `AsyncLoading` indefinitely, to exercise the year switcher's permissive
  /// fallback while the background year-mode bound read hasn't settled yet.
  final Set<TrendQuery> hangingQueries = {};

  @override
  Future<Either<Failure, TrendSummary>> fetchTrend(TrendQuery query) {
    fetchTrendCalls.add(query);
    if (hangingQueries.contains(query)) {
      return Completer<Either<Failure, TrendSummary>>().future;
    }
    return Future.value(
      nextResultByQuery[query] ??
          const Left(UnknownFailure(message: 'no result configured')),
    );
  }

  @override
  Future<Either<Failure, DashboardSummary>> fetchSummary({
    required int year,
    required int month,
  }) => throw UnimplementedError('not exercised by this test');
}

TrendSummary _monthSummary(
  int year, {
  double income = 45000,
  double expense = 32000,
}) => TrendSummary(
  granularity: TrendGranularity.month,
  year: year,
  buckets: List.generate(
    12,
    (i) => TrendBucket(
      year: year,
      month: i + 1,
      totalIncome: income,
      totalExpense: expense,
      net: income - expense,
    ),
  ),
);

TrendSummary _yearSummary({int earliestYear = 2024, int latestYear = 2026}) =>
    TrendSummary(
      granularity: TrendGranularity.year,
      year: null,
      buckets: [
        for (var y = earliestYear; y <= latestYear; y++)
          TrendBucket(
            year: y,
            month: null,
            totalIncome: 500000,
            totalExpense: 300000,
            net: 200000,
          ),
      ],
    );

Widget _buildApp(_FakeDashboardRepository fake) => ProviderScope(
  overrides: [dashboardRepositoryProvider.overrideWithValue(fake)],
  child: const MaterialApp(home: TrendPage()),
);

void main() {
  late _FakeDashboardRepository fake;
  late int currentYear;

  setUp(() {
    fake = _FakeDashboardRepository();
    currentYear = DateTime.now().year;
    fake.nextResultByQuery[TrendQuery.month(currentYear)] = Right(
      _monthSummary(currentYear),
    );
    fake.nextResultByQuery[const TrendQuery.year()] = Right(
      _yearSummary(latestYear: currentYear),
    );
  });

  testWidgets('opens in monthly mode for the current year', (tester) async {
    await tester.pumpWidget(_buildApp(fake));
    await tester.pumpAndSettle();

    expect(fake.fetchTrendCalls, contains(TrendQuery.month(currentYear)));
    expect(find.byKey(const Key('trendYearBack')), findsOneWidget);
    expect(find.text('${currentYear + 543}'), findsOneWidget);
  });

  testWidgets(
    'switching to รายปี hides the year switcher and requests year-mode data',
    (tester) async {
      await tester.pumpWidget(_buildApp(fake));
      await tester.pumpAndSettle();

      await tester.tap(find.text('รายปี'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('trendYearBack')), findsNothing);
      expect(find.byKey(const Key('trendYearForward')), findsNothing);
      expect(fake.fetchTrendCalls, contains(const TrendQuery.year()));
    },
  );

  testWidgets('the year switcher does not advance past the current year', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(fake));
    await tester.pumpAndSettle();
    final callsBefore = List.of(fake.fetchTrendCalls);

    await tester.tap(find.byKey(const Key('trendYearForward')));
    await tester.pumpAndSettle();

    expect(fake.fetchTrendCalls, callsBefore);
    expect(find.text('${currentYear + 543}'), findsOneWidget);
  });

  testWidgets('the back arrow steps to the previous year and requests it', (
    tester,
  ) async {
    fake.nextResultByQuery[TrendQuery.month(currentYear - 1)] = Right(
      _monthSummary(currentYear - 1),
    );
    await tester.pumpWidget(_buildApp(fake));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('trendYearBack')));
    await tester.pumpAndSettle();

    expect(fake.fetchTrendCalls, contains(TrendQuery.month(currentYear - 1)));
    expect(find.text('${currentYear - 1 + 543}'), findsOneWidget);
  });

  testWidgets(
    'the back arrow stops at the earliest year trendProvider(TrendQuery.year()) reports data for',
    (tester) async {
      final earliestYear = currentYear - 2;
      fake.nextResultByQuery[const TrendQuery.year()] = Right(
        _yearSummary(earliestYear: earliestYear, latestYear: currentYear),
      );
      for (var y = earliestYear; y < currentYear; y++) {
        fake.nextResultByQuery[TrendQuery.month(y)] = Right(_monthSummary(y));
      }
      await tester.pumpWidget(_buildApp(fake));
      await tester.pumpAndSettle();

      // Step back exactly to the earliest year — each tap must still work.
      for (var i = 0; i < currentYear - earliestYear; i++) {
        await tester.tap(find.byKey(const Key('trendYearBack')));
        await tester.pumpAndSettle();
      }
      expect(find.text('${earliestYear + 543}'), findsOneWidget);
      final callsAtBound = List.of(fake.fetchTrendCalls);

      // One more tap past the earliest year must be a no-op — the arrow is
      // disabled (`onTap: null`) once `_year == earliestYear`.
      await tester.tap(find.byKey(const Key('trendYearBack')));
      await tester.pumpAndSettle();

      expect(find.text('${earliestYear + 543}'), findsOneWidget);
      expect(fake.fetchTrendCalls, callsAtBound);
    },
  );

  testWidgets(
    'the back arrow is never blocked while the year-mode bound is still loading — permissive fallback',
    (tester) async {
      // trendProvider(const TrendQuery.year()) never resolves in this test —
      // `_earliestYear` sees only AsyncLoading (`.value` is null), so the
      // back arrow must default to enabled rather than falsely disabling
      // navigation on an unrelated read that simply hasn't settled yet.
      fake.hangingQueries.add(const TrendQuery.year());
      fake.nextResultByQuery[TrendQuery.month(currentYear - 1)] = Right(
        _monthSummary(currentYear - 1),
      );
      await tester.pumpWidget(_buildApp(fake));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('trendYearBack')), findsOneWidget);
      await tester.tap(find.byKey(const Key('trendYearBack')));
      await tester.pumpAndSettle();

      expect(fake.fetchTrendCalls, contains(TrendQuery.month(currentYear - 1)));
      expect(find.text('${currentYear - 1 + 543}'), findsOneWidget);
    },
  );

  testWidgets(
    'an error shows a retry action, which re-fetches the same query',
    (tester) async {
      fake.nextResultByQuery.remove(TrendQuery.month(currentYear));
      await tester.pumpWidget(_buildApp(fake));
      await tester.pumpAndSettle();

      expect(find.textContaining('ไม่สำเร็จ'), findsOneWidget);
      final callsBefore = fake.fetchTrendCalls.length;

      fake.nextResultByQuery[TrendQuery.month(currentYear)] = Right(
        _monthSummary(currentYear),
      );
      await tester.tap(find.byKey(const Key('trendRetryButton')));
      await tester.pumpAndSettle();

      expect(fake.fetchTrendCalls.length, greaterThan(callsBefore));
      expect(find.textContaining('ไม่สำเร็จ'), findsNothing);
    },
  );

  testWidgets('pull-to-refresh re-fetches the currently shown query', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(fake));
    await tester.pumpAndSettle();
    final callsBefore = fake.fetchTrendCalls
        .where((q) => q == TrendQuery.month(currentYear))
        .length;

    await tester.fling(
      find.byType(RefreshIndicator),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();

    final callsAfter = fake.fetchTrendCalls
        .where((q) => q == TrendQuery.month(currentYear))
        .length;
    expect(callsAfter, greaterThan(callsBefore));
  });
}

// Pure ProviderContainer test — no widget pump, no dio. Same fake-repository
// reasoning as dashboard_providers_test.dart.
import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/dashboard/data/dashboard_repository.dart';
import 'package:cashlog/features/dashboard/domain/dashboard_summary.dart';
import 'package:cashlog/features/dashboard/domain/trend_summary.dart';
import 'package:cashlog/features/dashboard/presentation/providers/trend_providers.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDashboardRepository implements DashboardRepository {
  final Map<TrendQuery, Either<Failure, TrendSummary>> nextResultByQuery = {};
  final List<TrendQuery> fetchTrendCalls = [];

  @override
  Future<Either<Failure, TrendSummary>> fetchTrend(TrendQuery query) async {
    fetchTrendCalls.add(query);
    return nextResultByQuery[query] ??
        const Left(UnknownFailure(message: 'no result configured'));
  }

  @override
  Future<Either<Failure, DashboardSummary>> fetchSummary({
    required int year,
    required int month,
  }) => throw UnimplementedError('not exercised by this test');
}

TrendSummary _summary({
  TrendGranularity granularity = TrendGranularity.month,
  int? year = 2026,
}) => TrendSummary(
  granularity: granularity,
  year: year,
  buckets: [
    TrendBucket(
      year: 2026,
      month: granularity == TrendGranularity.year ? null : 1,
      totalIncome: 45000,
      totalExpense: 32000,
      net: 13000,
    ),
  ],
);

void main() {
  test('trendProvider exposes AsyncData on a successful fetch', () async {
    const query = TrendQuery.month(2026);
    final fake = _FakeDashboardRepository()
      ..nextResultByQuery[query] = Right(_summary());
    final container = ProviderContainer(
      overrides: [dashboardRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final summary = await container.read(trendProvider(query).future);

    expect(summary.granularity, TrendGranularity.month);
    expect(summary.buckets.single.totalIncome, 45000);
  });

  test(
    'trendProvider surfaces the original Failure as AsyncError on a Left',
    () async {
      const query = TrendQuery.month(2026);
      const failure = TimeoutFailure(message: 'timed out');
      final fake = _FakeDashboardRepository()
        ..nextResultByQuery[query] = const Left(failure);
      final container = ProviderContainer(
        overrides: [dashboardRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final provider = trendProvider(query);
      await expectLater(
        container.read(provider.future),
        throwsA(same(failure)),
      );

      expect(container.read(provider), isA<AsyncError<TrendSummary>>());
      expect((container.read(provider) as AsyncError).error, same(failure));
    },
  );

  test('different TrendQuery arguments produce independent results', () async {
    const monthQuery = TrendQuery.month(2026);
    const yearQuery = TrendQuery.year();
    final fake = _FakeDashboardRepository()
      ..nextResultByQuery[monthQuery] = Right(_summary())
      ..nextResultByQuery[yearQuery] = Right(
        _summary(granularity: TrendGranularity.year, year: null),
      );
    final container = ProviderContainer(
      overrides: [dashboardRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final monthResult = await container.read(trendProvider(monthQuery).future);
    final yearResult = await container.read(trendProvider(yearQuery).future);

    expect(monthResult.granularity, TrendGranularity.month);
    expect(yearResult.granularity, TrendGranularity.year);
    expect(fake.fetchTrendCalls, [monthQuery, yearQuery]);
  });

  test('trendProvider is keepAlive — rereading the same query with nothing watching does not refetch', () async {
    const query = TrendQuery.month(2026);
    final fake = _FakeDashboardRepository()
      ..nextResultByQuery[query] = Right(_summary());
    final container = ProviderContainer(
      overrides: [dashboardRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    await container.read(trendProvider(query).future);
    await container.read(trendProvider(query).future);

    expect(fake.fetchTrendCalls, [query]);
  });
}

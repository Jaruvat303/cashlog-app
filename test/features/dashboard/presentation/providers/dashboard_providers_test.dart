// Pure ProviderContainer test — no widget pump, no dio. A hand-written fake
// DashboardRepository stands in for the network (same reasoning as
// transactions_feed_providers_test.dart).
import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/dashboard/data/dashboard_repository.dart';
import 'package:cashlog/features/dashboard/domain/dashboard_summary.dart';
import 'package:cashlog/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDashboardRepository implements DashboardRepository {
  Either<Failure, DashboardSummary>? nextResult;

  @override
  Future<Either<Failure, DashboardSummary>> fetchSummary({required int year, required int month}) async =>
      nextResult ?? const Left(UnknownFailure(message: 'no result configured'));
}

DashboardSummary _summary({double income = 100, double expense = 40}) => DashboardSummary(
  totalIncome: income,
  totalExpense: expense,
  totalTransfer: 0,
  year: 2026,
  month: 9,
  income: const [],
  expense: const [],
);

void main() {
  test('dashboardSummaryProvider exposes AsyncData on a successful fetch', () async {
    final fake = _FakeDashboardRepository()..nextResult = Right(_summary());
    final container = ProviderContainer(overrides: [dashboardRepositoryProvider.overrideWithValue(fake)]);
    addTearDown(container.dispose);

    final summary = await container.read(dashboardSummaryProvider(2026, 9).future);

    expect(summary.totalIncome, 100);
    expect(summary.net, 60);
  });

  test('dashboardSummaryProvider surfaces the original Failure as AsyncError on a Left', () async {
    const failure = TimeoutFailure(message: 'timed out');
    final fake = _FakeDashboardRepository()..nextResult = const Left(failure);
    final container = ProviderContainer(overrides: [dashboardRepositoryProvider.overrideWithValue(fake)]);
    addTearDown(container.dispose);

    final provider = dashboardSummaryProvider(2026, 9);
    await expectLater(container.read(provider.future), throwsA(same(failure)));

    // AsyncValue's error-branch state should carry that exact Failure too —
    // read it in the same microtask window the rejected `.future` settled
    // in, before this autoDispose family (no listeners) tears itself down.
    expect(container.read(provider), isA<AsyncError<DashboardSummary>>());
    expect((container.read(provider) as AsyncError).error, same(failure));
  });
}

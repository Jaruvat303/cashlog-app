// Pure ProviderContainer test — no widget pump, no dio/drift. Hand-written
// fakes stand in for TransactionsRepository/DashboardRepository so this can
// assert exactly when each underlying repository method gets called, which
// is what proves DoD #4 (invalidating a month nobody's watching must not
// trigger a network call).
import 'package:cashlog/core/cache/cache_invalidator.dart';
import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/dashboard/data/dashboard_repository.dart';
import 'package:cashlog/features/dashboard/domain/dashboard_summary.dart';
import 'package:cashlog/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:cashlog/features/transactions/data/transactions_repository.dart';
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:cashlog/features/transactions/domain/transaction_page.dart';
import 'package:cashlog/features/transactions/presentation/providers/transactions_feed_providers.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTransactionsRepository implements TransactionsRepository {
  final List<(int, int)> watchMonthCalls = [];

  @override
  Stream<List<Transaction>> watchMonth({required int year, required int month}) {
    watchMonthCalls.add((year, month));
    return Stream.value(const []);
  }

  @override
  Future<Either<Failure, TransactionPage>> fetchPage({required int year, required int month, required int page, int limit = 20}) =>
      throw UnimplementedError('not exercised by this test');

  @override
  Future<Either<Failure, Transaction>> create({
    required TransactionType type,
    required double amount,
    required DateTime date,
    String? note,
    int? accountId,
    int? fromAccountId,
    int? toAccountId,
    int? categoryId,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Future<Either<Failure, Transaction>> update(
    int id, {
    required TransactionType type,
    required double amount,
    required DateTime date,
    String? note,
    int? accountId,
    int? fromAccountId,
    int? toAccountId,
    int? categoryId,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Future<Either<Failure, void>> delete(int id) => throw UnimplementedError('not exercised by this test');
}

class _FakeDashboardRepository implements DashboardRepository {
  final List<(int, int)> fetchSummaryCalls = [];

  @override
  Future<Either<Failure, DashboardSummary>> fetchSummary({required int year, required int month}) async {
    fetchSummaryCalls.add((year, month));
    return Right(
      DashboardSummary(totalIncome: 0, totalExpense: 0, totalTransfer: 0, year: year, month: month, income: const [], expense: const []),
    );
  }
}

void main() {
  late _FakeTransactionsRepository fakeTransactions;
  late _FakeDashboardRepository fakeDashboard;
  late ProviderContainer container;

  setUp(() {
    fakeTransactions = _FakeTransactionsRepository();
    fakeDashboard = _FakeDashboardRepository();
    container = ProviderContainer(
      overrides: [
        transactionsRepositoryProvider.overrideWithValue(fakeTransactions),
        dashboardRepositoryProvider.overrideWithValue(fakeDashboard),
      ],
    );
    addTearDown(container.dispose);
  });

  test('invalidateMonth rebuilds a currently-watched month\'s feed and dashboard immediately', () async {
    container.listen(monthTransactionsProvider(2026, 9), (prev, next) {});
    container.listen(dashboardSummaryProvider(2026, 9), (prev, next) {});
    await container.read(dashboardSummaryProvider(2026, 9).future);

    expect(fakeTransactions.watchMonthCalls, [(2026, 9)]);
    expect(fakeDashboard.fetchSummaryCalls, [(2026, 9)]);

    container.read(cacheInvalidatorProvider).invalidateMonth(2026, 9);
    // A watched family provider rebuilds on invalidate, but not
    // synchronously inside this call — give its scheduled rebuild a
    // microtask turn before asserting, same as CLAUDE.md's Riverpod
    // "watched rebuilds immediately, unwatched refetches lazily" rule.
    await Future<void>.delayed(Duration.zero);
    await container.read(dashboardSummaryProvider(2026, 9).future);

    expect(fakeTransactions.watchMonthCalls, [(2026, 9), (2026, 9)]);
    expect(fakeDashboard.fetchSummaryCalls, [(2026, 9), (2026, 9)]);
  });

  test('invalidating a month nobody is watching triggers no network call for that month', () async {
    container.read(cacheInvalidatorProvider).invalidateMonth(2026, 11);
    // Let any (incorrect) eager rebuild's microtasks run before asserting.
    await Future<void>.delayed(Duration.zero);

    expect(fakeTransactions.watchMonthCalls, isEmpty);
    expect(fakeDashboard.fetchSummaryCalls, isEmpty);
  });

  test('invalidateMonths invalidates every given month and leaves other watched months alone', () async {
    container.listen(dashboardSummaryProvider(2026, 6), (prev, next) {});
    container.listen(dashboardSummaryProvider(2026, 7), (prev, next) {});
    container.listen(dashboardSummaryProvider(2026, 8), (prev, next) {});
    await Future.wait([
      container.read(dashboardSummaryProvider(2026, 6).future),
      container.read(dashboardSummaryProvider(2026, 7).future),
      container.read(dashboardSummaryProvider(2026, 8).future),
    ]);
    expect(fakeDashboard.fetchSummaryCalls, [(2026, 6), (2026, 7), (2026, 8)]);

    container.read(cacheInvalidatorProvider).invalidateMonths({(2026, 6), (2026, 7)});
    await Future<void>.delayed(Duration.zero);
    await Future.wait([
      container.read(dashboardSummaryProvider(2026, 6).future),
      container.read(dashboardSummaryProvider(2026, 7).future),
    ]);

    expect(fakeDashboard.fetchSummaryCalls.where((m) => m == (2026, 6)).length, 2);
    expect(fakeDashboard.fetchSummaryCalls.where((m) => m == (2026, 7)).length, 2);
    // Month 8 was watched but never named in invalidateMonths — untouched.
    expect(fakeDashboard.fetchSummaryCalls.where((m) => m == (2026, 8)).length, 1);
  });
}

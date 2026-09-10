// Pure ProviderContainer test — no widget pump, no dio, no drift. A
// hand-written fake TransactionsRepository stands in for the network so
// page-advance/hasMore/re-entrancy behavior can be driven deterministically.
import 'dart:async';

import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/transactions/data/transactions_repository.dart';
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:cashlog/features/transactions/domain/transaction_page.dart';
import 'package:cashlog/features/transactions/presentation/providers/transactions_feed_providers.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTransactionsRepository implements TransactionsRepository {
  final Map<int, TransactionPage> pages = {};
  final List<int> requestedPages = [];

  /// When set, [fetchPage] awaits this before resolving — lets a test hold
  /// a call in flight to exercise the re-entrancy guard.
  Completer<void>? gate;

  @override
  Future<Either<Failure, TransactionPage>> fetchPage({required int year, required int month, required int page, int limit = 20}) async {
    requestedPages.add(page);
    if (gate != null) await gate!.future;
    final result = pages[page];
    if (result == null) return const Left(UnknownFailure(message: 'no page configured'));
    return Right(result);
  }

  @override
  Stream<List<Transaction>> watchMonth({required int year, required int month}) => throw UnimplementedError('not exercised by this test');

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

void main() {
  late _FakeTransactionsRepository fakeRepository;
  late ProviderContainer container;

  setUp(() {
    fakeRepository = _FakeTransactionsRepository();
    container = ProviderContainer(overrides: [transactionsRepositoryProvider.overrideWithValue(fakeRepository)]);
  });

  tearDown(() => container.dispose());

  test('loadFirstPage populates meta from the fetched page', () async {
    fakeRepository.pages[1] = const TransactionPage(transactions: [], currentPage: 1, totalPages: 3);

    final notifier = container.read(transactionsFeedSyncProvider(2026, 9).notifier);
    final result = await notifier.loadFirstPage();

    expect(result.isRight(), isTrue);
    final meta = container.read(transactionsFeedSyncProvider(2026, 9));
    expect(meta?.currentPage, 1);
    expect(meta?.totalPages, 3);
    expect(meta?.hasMore, isTrue);
    expect(meta?.isLoadingMore, isFalse);
  });

  test('loadNextPage advances currentPage and flips hasMore false on the last page', () async {
    fakeRepository.pages[1] = const TransactionPage(transactions: [], currentPage: 1, totalPages: 2);
    fakeRepository.pages[2] = const TransactionPage(transactions: [], currentPage: 2, totalPages: 2);
    final notifier = container.read(transactionsFeedSyncProvider(2026, 9).notifier);
    await notifier.loadFirstPage();

    final result = await notifier.loadNextPage();

    expect(result.isRight(), isTrue);
    final meta = container.read(transactionsFeedSyncProvider(2026, 9));
    expect(meta?.currentPage, 2);
    expect(meta?.hasMore, isFalse);
    expect(fakeRepository.requestedPages, [1, 2]);
  });

  test('loadNextPage is a no-op once hasMore is false — no extra fetchPage call', () async {
    fakeRepository.pages[1] = const TransactionPage(transactions: [], currentPage: 1, totalPages: 1);
    final notifier = container.read(transactionsFeedSyncProvider(2026, 9).notifier);
    await notifier.loadFirstPage();

    final result = await notifier.loadNextPage();

    expect(result.isRight(), isTrue);
    expect(fakeRepository.requestedPages, [1]); // page 2 never requested
  });

  test('a concurrent loadNextPage call while one is already in flight is guarded — only one fetchPage for the next page', () async {
    fakeRepository.pages[1] = const TransactionPage(transactions: [], currentPage: 1, totalPages: 3);
    fakeRepository.pages[2] = const TransactionPage(transactions: [], currentPage: 2, totalPages: 3);
    final notifier = container.read(transactionsFeedSyncProvider(2026, 9).notifier);
    await notifier.loadFirstPage();

    fakeRepository.gate = Completer<void>();
    final firstCall = notifier.loadNextPage();
    // isLoadingMore is now true — a second call made before the first
    // resolves must bail out without hitting the repository again.
    final secondCall = notifier.loadNextPage();
    fakeRepository.gate!.complete();
    await Future.wait([firstCall, secondCall]);

    expect(fakeRepository.requestedPages, [1, 2]); // page 2 requested exactly once
    final meta = container.read(transactionsFeedSyncProvider(2026, 9));
    expect(meta?.currentPage, 2);
  });

  test('a failed loadNextPage resets isLoadingMore but keeps the last known page', () async {
    fakeRepository.pages[1] = const TransactionPage(transactions: [], currentPage: 1, totalPages: 3);
    // page 2 deliberately left unconfigured -> fetchPage returns Left
    final notifier = container.read(transactionsFeedSyncProvider(2026, 9).notifier);
    await notifier.loadFirstPage();

    final result = await notifier.loadNextPage();

    expect(result.isLeft(), isTrue);
    final meta = container.read(transactionsFeedSyncProvider(2026, 9));
    expect(meta?.currentPage, 1);
    expect(meta?.isLoadingMore, isFalse);
  });
}

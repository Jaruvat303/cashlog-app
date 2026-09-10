// Before any pumpWidget/pumpAndSettle, every repository the feed touches is
// overridden with a hand-written fake (same pattern as
// _FakeAccountsRepository in test/widget_test.dart / transaction_form_page_test.dart)
// — this is what keeps a real dio call from ever reaching Flutter's test
// HTTP stub, the exact thing that caused a hang in T4.
import 'dart:async';

import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/accounts/data/accounts_repository.dart';
import 'package:cashlog/features/accounts/domain/account.dart';
import 'package:cashlog/features/categories/data/categories_repository.dart';
import 'package:cashlog/features/categories/domain/category.dart';
import 'package:cashlog/features/transactions/data/transactions_repository.dart';
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:cashlog/features/transactions/domain/transaction_page.dart';
import 'package:cashlog/features/transactions/presentation/pages/transactions_page.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAccountsRepository implements AccountsRepository {
  @override
  Stream<List<Account>> watchActiveAccounts() => Stream.value(const []);

  @override
  Stream<Account?> watchCached(int id) => Stream.value(null);

  @override
  Future<Either<Failure, void>> refreshFromApi() async => const Right(null);

  @override
  Future<Either<Failure, Account>> create({
    required String name,
    required AccountType accountType,
    required double openingBalance,
    required List<String> matchingKeywords,
    required String bankIcon,
  }) => throw UnimplementedError('not exercised by this feed test');

  @override
  Future<Either<Failure, Account>> update(
    int id, {
    required String name,
    required AccountType accountType,
    required List<String> matchingKeywords,
    required String bankIcon,
  }) => throw UnimplementedError('not exercised by this feed test');

  @override
  Future<Either<Failure, void>> close(int id) => throw UnimplementedError('not exercised by this feed test');
}

class _FakeCategoriesRepository implements CategoriesRepository {
  @override
  Stream<List<Category>> watchAll() => Stream.value(const []);

  @override
  Future<Either<Failure, void>> refreshFromApi() async => const Right(null);

  @override
  Future<Either<Failure, Category>> create({
    required String name,
    required CategoryType type,
    required String iconKey,
    required String colorHex,
  }) => throw UnimplementedError('not exercised by this feed test');

  @override
  Future<Either<Failure, Category>> update(
    int id, {
    required String name,
    required CategoryType type,
    required String iconKey,
    required String colorHex,
  }) => throw UnimplementedError('not exercised by this feed test');

  @override
  Future<int> countLinkedTransactions(int categoryId) => throw UnimplementedError('not exercised by this feed test');

  @override
  Future<Either<Failure, void>> delete(int id) => throw UnimplementedError('not exercised by this feed test');
}

/// One independently-addressable (year, month) feed, so the fake behaves
/// like the real upsert-into-cache/read-from-cache split: [fetchPage]
/// appends into [current], [watchMonth] streams whatever's in [current] —
/// including an immediate replay of the latest snapshot to every new
/// listener (`Stream.multi`), since a real drift `.watch()` does the same.
class _MonthChannel {
  List<Transaction> current = [];
  final _controller = StreamController<List<Transaction>>.broadcast();

  Stream<List<Transaction>> get stream => Stream.multi((controller) {
    controller.add(current);
    final sub = _controller.stream.listen(controller.add);
    controller.onCancel = sub.cancel;
  });

  void append(List<Transaction> page) {
    current = [...current, ...page];
    _controller.add(current);
  }
}

class _FakeTransactionsRepository implements TransactionsRepository {
  final Map<(int, int), _MonthChannel> _channels = {};

  /// Canned pages keyed by (year, month, page). A (year, month, page) with
  /// no entry makes [fetchPage] return a `Left` — same as the real backend
  /// erroring on a page a test never intended to be requested.
  final Map<(int, int, int), TransactionPage> pages = {};
  final List<(int, int, int)> fetchCalls = [];

  _MonthChannel _channelFor(int year, int month) => _channels.putIfAbsent((year, month), () => _MonthChannel());

  @override
  Stream<List<Transaction>> watchMonth({required int year, required int month}) => _channelFor(year, month).stream;

  @override
  Future<Either<Failure, TransactionPage>> fetchPage({required int year, required int month, required int page, int limit = 20}) async {
    fetchCalls.add((year, month, page));
    final result = pages[(year, month, page)];
    if (result == null) return const Left(UnknownFailure(message: 'no page configured for this request'));
    _channelFor(year, month).append(result.transactions);
    return Right(result);
  }

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
  }) => throw UnimplementedError('not exercised by this feed test');

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
  }) => throw UnimplementedError('not exercised by this feed test');

  @override
  Future<Either<Failure, void>> delete(int id) => throw UnimplementedError('not exercised by this feed test');
}

Transaction _expense(int id, String note, DateTime date) =>
    Transaction(id: id, amount: 100, type: TransactionType.expense, note: note, source: 'manual', transactionDate: date);

/// pumpAndSettle can't tell "still legitimately loading" from "stuck
/// forever" — a bounded pump loop fails fast instead (same reasoning as
/// test/widget_test.dart's `_pumpBounded`).
Future<void> _pumpBounded(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late _FakeTransactionsRepository fakeTransactions;
  late DateTime thisMonth;

  setUp(() {
    fakeTransactions = _FakeTransactionsRepository();
    final now = DateTime.now();
    thisMonth = DateTime.utc(now.year, now.month);
  });

  Widget buildApp() => ProviderScope(
    overrides: [
      accountsRepositoryProvider.overrideWithValue(_FakeAccountsRepository()),
      categoriesRepositoryProvider.overrideWithValue(_FakeCategoriesRepository()),
      transactionsRepositoryProvider.overrideWithValue(fakeTransactions),
    ],
    child: const MaterialApp(home: TransactionsPage()),
  );

  testWidgets('renders page 1 on open and loads page 2 when scrolled to the bottom', (tester) async {
    // 20 rows is enough to fill the viewport and leave room to scroll.
    final pageOneRows = List.generate(20, (i) => _expense(i + 1, 'Page one row $i', thisMonth));
    final pageTwoRows = [_expense(100, 'Page two exclusive row', thisMonth)];
    fakeTransactions.pages[(thisMonth.year, thisMonth.month, 1)] = TransactionPage(transactions: pageOneRows, currentPage: 1, totalPages: 2);
    fakeTransactions.pages[(thisMonth.year, thisMonth.month, 2)] = TransactionPage(transactions: pageTwoRows, currentPage: 2, totalPages: 2);

    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);

    expect(find.text('Page one row 0'), findsOneWidget);
    expect(find.text('Page two exclusive row'), findsNothing);
    expect(fakeTransactions.fetchCalls, [(thisMonth.year, thisMonth.month, 1)]);

    await tester.drag(find.byType(ListView), const Offset(0, -20000));
    await _pumpBounded(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -20000));
    await _pumpBounded(tester);

    expect(fakeTransactions.fetchCalls, [(thisMonth.year, thisMonth.month, 1), (thisMonth.year, thisMonth.month, 2)]);
    expect(find.text('Page two exclusive row'), findsOneWidget);
  });

  testWidgets('switching month replaces the list with the new month\'s data', (tester) async {
    final nextMonth = DateTime.utc(thisMonth.year, thisMonth.month + 1);
    fakeTransactions.pages[(thisMonth.year, thisMonth.month, 1)] = TransactionPage(
      transactions: [_expense(1, 'This month row', thisMonth)],
      currentPage: 1,
      totalPages: 1,
    );
    fakeTransactions.pages[(nextMonth.year, nextMonth.month, 1)] = TransactionPage(
      transactions: [_expense(2, 'Next month row', nextMonth)],
      currentPage: 1,
      totalPages: 1,
    );

    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);
    expect(find.text('This month row'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await _pumpBounded(tester);

    expect(find.text('This month row'), findsNothing);
    expect(find.text('Next month row'), findsOneWidget);
  });
}

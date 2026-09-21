// Before any pumpWidget/pumpAndSettle, every repository the feed touches is
// overridden with a hand-written fake (same pattern as
// _FakeAccountsRepository in test/widget_test.dart / transaction_form_page_test.dart)
// — this is what keeps a real dio call from ever reaching Flutter's test
// HTTP stub, the exact thing that caused a hang in T4.
import 'dart:async';

import 'package:cashlog/core/month/selected_month_provider.dart';
import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/core/theme/app_theme.dart';
import 'package:cashlog/features/accounts/data/accounts_repository.dart';
import 'package:cashlog/features/accounts/domain/account.dart';
import 'package:cashlog/features/accounts/presentation/widgets/current_balance_text.dart';
import 'package:cashlog/features/categories/data/categories_repository.dart';
import 'package:cashlog/features/categories/domain/category.dart';
import 'package:cashlog/features/dashboard/data/dashboard_repository.dart';
import 'package:cashlog/features/dashboard/domain/dashboard_summary.dart';
import 'package:cashlog/features/transactions/data/pending_action_mapper.dart';
import 'package:cashlog/features/transactions/data/pending_actions_repository.dart';
import 'package:cashlog/features/transactions/data/transactions_repository.dart';
import 'package:cashlog/features/transactions/domain/pending_action.dart';
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:cashlog/features/transactions/domain/transaction_page.dart';
import 'package:cashlog/features/transactions/presentation/pages/transactions_page.dart';
import 'package:cashlog/shared/format/money.dart';
import 'package:dartz/dartz.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

class _FakeAccountsRepository implements AccountsRepository {
  _FakeAccountsRepository({this.accounts = const [], this.balances = const {}});

  final List<Account> accounts;
  final Map<int, double> balances;

  @override
  Stream<List<Account>> watchActiveAccounts() => Stream.value(accounts);

  @override
  Stream<Account?> watchCached(int id) {
    for (final account in accounts) {
      if (account.id == id) return Stream.value(account);
    }
    return Stream.value(null);
  }

  @override
  Stream<double> watchCurrentBalance(int accountId) => Stream.value(balances[accountId] ?? 0);

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
/// listener (an `async*` seed + broadcast passthrough), since a real drift
/// `.watch()` does the same.
class _MonthChannel {
  List<Transaction> current = [];
  final _controller = StreamController<List<Transaction>>.broadcast();

  Stream<List<Transaction>> get stream async* {
    yield current;
    yield* _controller.stream;
  }

  /// Ticket 07: mirrors [TransactionsRepository.watchMonth]'s `categoryId`
  /// narrowing as a `.map()` over the same underlying stream — a real drift
  /// `.watch()` re-filters on every emission the same way, so this fake
  /// stays faithful without needing a second channel per category.
  Stream<List<Transaction>> streamFor({int? categoryId}) =>
      stream.map((list) => categoryId == null ? list : list.where((t) => t.categoryId == categoryId).toList());

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
  Stream<List<Transaction>> watchMonth({required int year, required int month, int? categoryId}) =>
      _channelFor(year, month).streamFor(categoryId: categoryId);

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

/// In-memory stand-in, not a real drift-backed repository — a real one
/// inside a testWidgets test hits a known drift/flutter_test interaction
/// (cancelling a live `.watch()` stream during widget-tree disposal
/// schedules a zero-duration Timer that never fires before the test
/// framework's post-test check, see
/// https://github.com/simolus3/drift/issues/3323 — confirmed during T13
/// verification). Reuses the real `recordIfTransient` policy check inline so
/// this fake's queue-or-not behavior matches production exactly; the
/// dedicated pending_actions_repository_test.dart (plain test(), unaffected
/// by the FakeAsync interaction above) covers this against a real drift db.
class _FakePendingActionsRepository implements PendingActionsRepository {
  final List<PendingAction> _items = [];
  int _nextId = 1;
  final _controller = StreamController<List<PendingAction>>.broadcast();

  @override
  Stream<List<PendingAction>> watchAll() async* {
    yield List.unmodifiable(_items);
    yield* _controller.stream;
  }

  @override
  Future<bool> recordIfTransient({
    required Failure failure,
    required PendingActionType actionType,
    required Map<String, dynamic> payload,
    int? targetTransactionId,
  }) async {
    if (failure.retryPolicy != RetryPolicy.transient) return false;
    _items.add(
      PendingAction(
        id: _nextId++,
        actionType: actionType,
        payload: payload,
        targetTransactionId: targetTransactionId,
        createdAt: DateTime.now(),
        lastErrorCode: errorTagForFailure(failure),
      ),
    );
    _controller.add(List.unmodifiable(_items));
    return true;
  }

  @override
  Future<void> recordRetryFailure(int id, String? errorCode) => throw UnimplementedError('not exercised by this feed test');

  @override
  Future<void> remove(int id) => throw UnimplementedError('not exercised by this feed test');
}

/// Ticket 07: the summary section reads `dashboardSummaryProvider`, backed
/// by a real `ApiClient`/dio call unless overridden — same reasoning as
/// every other `_Fake*Repository` in this file (CLAUDE.md: never let a real
/// dio call reach Flutter's test HTTP stub).
class _FakeDashboardRepository implements DashboardRepository {
  final Map<(int, int), Either<Failure, DashboardSummary>> results = {};

  @override
  Future<Either<Failure, DashboardSummary>> fetchSummary({required int year, required int month}) async =>
      results[(year, month)] ?? const Left(UnknownFailure(message: 'no result configured for this month'));
}

CategoryBreakdown _breakdown(int id, String name, double amount) =>
    CategoryBreakdown(categoryId: id, categoryName: name, iconKey: '', colorHex: '#EF4444', totalAmount: amount);

Transaction _expense(int id, String note, DateTime date, {int? categoryId}) =>
    Transaction(id: id, amount: 100, type: TransactionType.expense, note: note, source: 'manual', transactionDate: date, categoryId: categoryId);

Transaction _transfer(int id, double amount, DateTime date) =>
    Transaction(id: id, amount: amount, type: TransactionType.transfer, source: 'manual', transactionDate: date);

/// pumpAndSettle can't tell "still legitimately loading" from "stuck
/// forever" — a bounded pump loop fails fast instead (same reasoning as
/// test/widget_test.dart's `_pumpBounded`).
Future<void> _pumpBounded(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Post-launch UI polish ticket 03's enlarged pie chart makes the summary
/// section taller, so the day-grouped transaction rows below it are no
/// longer within the initial viewport in several of these tests — the
/// sliver list only builds visible (+cache-extent) children, same reasoning
/// as the analogous helper in transaction_form_page_test.dart.
Future<void> _scrollToFinder(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable).first);

/// Ticket 10's visual-selected-state check: the row's highlight is a
/// `BoxDecoration.color`/`border` on the `Container` directly under its
/// keyed `InkWell`, not a separate marker widget — read that decoration
/// straight off the tree rather than re-deriving the same condition the
/// widget itself uses, so this actually catches a broken/missing highlight.
bool _categoryRowIsHighlighted(WidgetTester tester, int categoryId) {
  final container = tester.widget<Container>(
    find.descendant(of: find.byKey(Key('categoryTotalRow-$categoryId')), matching: find.byType(Container)).first,
  );
  final decoration = container.decoration as BoxDecoration?;
  return decoration?.color == AppColors.primarySurface;
}

void main() {
  late _FakeTransactionsRepository fakeTransactions;
  late DateTime thisMonth;
  late _FakePendingActionsRepository pendingActions;
  late _FakeDashboardRepository fakeDashboard;

  setUp(() {
    fakeTransactions = _FakeTransactionsRepository();
    final now = DateTime.now();
    thisMonth = DateTime.utc(now.year, now.month);
    // TransactionsPage's badge reads straight off this repository's own
    // watchAll() stream, so seeding rows here exercises the same code path
    // the badge uses, not a stand-in count.
    pendingActions = _FakePendingActionsRepository();
    fakeDashboard = _FakeDashboardRepository();
  });

  Widget buildApp({AccountsRepository? accountsRepository}) => ProviderScope(
    overrides: [
      accountsRepositoryProvider.overrideWithValue(accountsRepository ?? _FakeAccountsRepository()),
      categoriesRepositoryProvider.overrideWithValue(_FakeCategoriesRepository()),
      transactionsRepositoryProvider.overrideWithValue(fakeTransactions),
      pendingActionsRepositoryProvider.overrideWithValue(pendingActions),
      dashboardRepositoryProvider.overrideWithValue(fakeDashboard),
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

    await tester.tap(find.byIcon(RemixIcon.arrowRightSLine));
    await _pumpBounded(tester);

    expect(find.text('This month row'), findsNothing);
    expect(find.text('Next month row'), findsOneWidget);
  });

  group('T13 stuck-items badge', () {
    testWidgets('hidden when the retry queue is empty', (tester) async {
      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      expect(find.byKey(const Key('pendingActionsButton')), findsOneWidget);
      final badge = tester.widget<Badge>(
        find.descendant(of: find.byKey(const Key('pendingActionsButton')), matching: find.byType(Badge)),
      );
      expect(badge.isLabelVisible, isFalse);
    });

    testWidgets('shows the queue count and opens the stuck-items page on tap', (tester) async {
      await pendingActions.recordIfTransient(
        failure: const TimeoutFailure(),
        actionType: PendingActionType.deleteTransaction,
        payload: deleteTransactionPayload(date: thisMonth),
        targetTransactionId: 99,
      );

      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      final badge = tester.widget<Badge>(
        find.descendant(of: find.byKey(const Key('pendingActionsButton')), matching: find.byType(Badge)),
      );
      expect(badge.isLabelVisible, isTrue);
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byKey(const Key('pendingActionsButton')));
      await _pumpBounded(tester);

      expect(find.text('รายการค้าง'), findsOneWidget);
    });
  });

  // T21 manual slip attach button: moved to test/widget_test.dart along with
  // the mockup redesign — it's now the AppShell's raised camera FAB
  // (reachable from every tab), not a Transactions-page-only AppBar action.

  group('summary tabs (ticket 07) and category drill-through (ticket 10)', () {
    setUp(() {
      fakeDashboard.results[(thisMonth.year, thisMonth.month)] = Right(
        DashboardSummary(
          totalIncome: 5000,
          totalExpense: 2500,
          totalTransfer: 0,
          year: thisMonth.year,
          month: thisMonth.month,
          income: [_breakdown(20, 'เงินเดือน', 5000)],
          expense: [_breakdown(10, 'อาหาร', 2000), _breakdown(11, 'เดินทาง', 500)],
        ),
      );
    });

    testWidgets('defaults to the Expense tab, listing categories with their totals as text', (tester) async {
      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      // Scoped to the list row's own key, matching the pattern the rest of
      // this file uses for category name assertions.
      expect(find.descendant(of: find.byKey(const Key('categoryTotalRow-10')), matching: find.text('อาหาร')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('categoryTotalRow-11')), matching: find.text('เดินทาง')), findsOneWidget);
      expect(find.text(formatAmount(2000)), findsOneWidget);
      expect(find.text(formatAmount(500)), findsOneWidget);
      expect(find.text('เงินเดือน'), findsNothing); // income row, not shown while Expense tab is active
      expect(find.byType(PieChart), findsOneWidget); // ticket 03: pie chart restored above the list
    });

    testWidgets('switching to the Income tab shows income categories and totals instead', (tester) async {
      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      await tester.tap(find.byKey(const Key('summaryTab-income')));
      await _pumpBounded(tester);

      expect(find.descendant(of: find.byKey(const Key('categoryTotalRow-20')), matching: find.text('เงินเดือน')), findsOneWidget);
      expect(find.text(formatAmount(5000)), findsOneWidget);
      expect(find.text('อาหาร'), findsNothing);
    });

    group('ticket 10: category drill-through', () {
      testWidgets('tapping a category row filters the day-grouped list below to only that category', (tester) async {
        fakeTransactions.pages[(thisMonth.year, thisMonth.month, 1)] = TransactionPage(
          transactions: [
            _expense(1, 'Food expense row', thisMonth, categoryId: 10),
            _expense(2, 'Transport expense row', thisMonth, categoryId: 11),
            _expense(3, 'Uncategorized expense row', thisMonth),
          ],
          currentPage: 1,
          totalPages: 1,
        );

        await tester.pumpWidget(buildApp());
        await _pumpBounded(tester);
        await _scrollToFinder(tester, find.text('Food expense row'));
        expect(find.text('Food expense row'), findsOneWidget);
        expect(find.text('Transport expense row'), findsOneWidget);
        expect(find.text('Uncategorized expense row'), findsOneWidget);

        // Back to the top before tapping the summary card's category row —
        // it scrolled out of view to reveal the rows above.
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 1000));
        await _pumpBounded(tester);
        await tester.tap(find.byKey(const Key('categoryTotalRow-10')));
        await _pumpBounded(tester);
        await _scrollToFinder(tester, find.text('Food expense row'));

        expect(find.text('Food expense row'), findsOneWidget);
        expect(find.text('Transport expense row'), findsNothing);
        expect(find.text('Uncategorized expense row'), findsNothing);
      });

      testWidgets('tapping the same category row again clears the filter, restoring the full list', (tester) async {
        fakeTransactions.pages[(thisMonth.year, thisMonth.month, 1)] = TransactionPage(
          transactions: [
            _expense(1, 'Food expense row', thisMonth, categoryId: 10),
            _expense(2, 'Uncategorized expense row', thisMonth),
          ],
          currentPage: 1,
          totalPages: 1,
        );

        await tester.pumpWidget(buildApp());
        await _pumpBounded(tester);

        await tester.tap(find.byKey(const Key('categoryTotalRow-10')));
        await _pumpBounded(tester);
        await _scrollToFinder(tester, find.text('Food expense row'));
        expect(find.text('Uncategorized expense row'), findsNothing);

        await tester.drag(find.byType(Scrollable).first, const Offset(0, 1000));
        await _pumpBounded(tester);
        await tester.tap(find.byKey(const Key('categoryTotalRow-10')));
        await _pumpBounded(tester);
        await _scrollToFinder(tester, find.text('Food expense row'));

        expect(find.text('Food expense row'), findsOneWidget);
        expect(find.text('Uncategorized expense row'), findsOneWidget);
      });

      testWidgets('the selected category row is visually highlighted; tapping it off removes the highlight', (tester) async {
        await tester.pumpWidget(buildApp());
        await _pumpBounded(tester);

        expect(_categoryRowIsHighlighted(tester, 10), isFalse);
        expect(_categoryRowIsHighlighted(tester, 11), isFalse);

        await tester.tap(find.byKey(const Key('categoryTotalRow-10')));
        await _pumpBounded(tester);
        expect(_categoryRowIsHighlighted(tester, 10), isTrue);
        expect(_categoryRowIsHighlighted(tester, 11), isFalse);

        await tester.tap(find.byKey(const Key('categoryTotalRow-10')));
        await _pumpBounded(tester);
        expect(_categoryRowIsHighlighted(tester, 10), isFalse);
      });

      testWidgets('tapping a different category while one is already selected moves the highlight and the filter', (tester) async {
        fakeTransactions.pages[(thisMonth.year, thisMonth.month, 1)] = TransactionPage(
          transactions: [
            _expense(1, 'Food expense row', thisMonth, categoryId: 10),
            _expense(2, 'Transport expense row', thisMonth, categoryId: 11),
          ],
          currentPage: 1,
          totalPages: 1,
        );

        await tester.pumpWidget(buildApp());
        await _pumpBounded(tester);

        await tester.tap(find.byKey(const Key('categoryTotalRow-10')));
        await _pumpBounded(tester);
        await tester.tap(find.byKey(const Key('categoryTotalRow-11')));
        await _pumpBounded(tester);

        expect(_categoryRowIsHighlighted(tester, 10), isFalse);
        expect(_categoryRowIsHighlighted(tester, 11), isTrue);
        await _scrollToFinder(tester, find.text('Transport expense row'));
        expect(find.text('Transport expense row'), findsOneWidget);
        expect(find.text('Food expense row'), findsNothing);
      });

      testWidgets('switching months clears an active category filter', (tester) async {
        final nextMonth = DateTime.utc(thisMonth.year, thisMonth.month + 1);
        fakeDashboard.results[(nextMonth.year, nextMonth.month)] = Right(
          DashboardSummary(
            totalIncome: 0,
            totalExpense: 500,
            totalTransfer: 0,
            year: nextMonth.year,
            month: nextMonth.month,
            income: const [],
            expense: [_breakdown(10, 'อาหาร', 500)],
          ),
        );
        fakeTransactions.pages[(thisMonth.year, thisMonth.month, 1)] = TransactionPage(
          transactions: [
            _expense(1, 'Food expense row', thisMonth, categoryId: 10),
            _expense(2, 'Uncategorized expense row', thisMonth),
          ],
          currentPage: 1,
          totalPages: 1,
        );
        fakeTransactions.pages[(nextMonth.year, nextMonth.month, 1)] = TransactionPage(
          transactions: [
            _expense(3, 'Next month food row', nextMonth, categoryId: 10),
            _expense(4, 'Next month uncategorized row', nextMonth),
          ],
          currentPage: 1,
          totalPages: 1,
        );

        await tester.pumpWidget(buildApp());
        await _pumpBounded(tester);

        await tester.tap(find.byKey(const Key('categoryTotalRow-10')));
        await _pumpBounded(tester);
        await _scrollToFinder(tester, find.text('Food expense row'));
        expect(find.text('Uncategorized expense row'), findsNothing);

        await tester.tap(find.byIcon(RemixIcon.arrowRightSLine));
        await _pumpBounded(tester);

        // Ticket 10: the filter is cleared, not carried over to the new
        // month — both of next month's rows show, and the row that used to
        // be selected is no longer highlighted.
        expect(_categoryRowIsHighlighted(tester, 10), isFalse);
        await _scrollToFinder(tester, find.text('Next month food row'));
        expect(find.text('Next month food row'), findsOneWidget);
        expect(find.text('Next month uncategorized row'), findsOneWidget);
      });

      testWidgets('switching the summary tab clears an active category filter', (tester) async {
        fakeTransactions.pages[(thisMonth.year, thisMonth.month, 1)] = TransactionPage(
          transactions: [
            _expense(1, 'Food expense row', thisMonth, categoryId: 10),
            _expense(2, 'Uncategorized expense row', thisMonth),
          ],
          currentPage: 1,
          totalPages: 1,
        );

        await tester.pumpWidget(buildApp());
        await _pumpBounded(tester);

        await tester.tap(find.byKey(const Key('categoryTotalRow-10')));
        await _pumpBounded(tester);
        await _scrollToFinder(tester, find.text('Food expense row'));
        expect(find.text('Uncategorized expense row'), findsNothing);

        await tester.drag(find.byType(Scrollable).first, const Offset(0, 1000));
        await _pumpBounded(tester);
        await tester.tap(find.byKey(const Key('summaryTab-income')));
        await _pumpBounded(tester);
        await tester.tap(find.byKey(const Key('summaryTab-expense')));
        await _pumpBounded(tester);

        expect(_categoryRowIsHighlighted(tester, 10), isFalse);
        await _scrollToFinder(tester, find.text('Food expense row'));
        expect(find.text('Food expense row'), findsOneWidget);
        expect(find.text('Uncategorized expense row'), findsOneWidget);
      });
    });
  });

  group('ticket 08: Transfer summary tab', () {
    setUp(() {
      fakeDashboard.results[(thisMonth.year, thisMonth.month)] = const Right(
        DashboardSummary(totalIncome: 0, totalExpense: 0, totalTransfer: 0, year: 0, month: 0, income: [], expense: []),
      );
    });

    testWidgets('shows every transfer transaction for the month, flat and ungrouped', (tester) async {
      fakeTransactions.pages[(thisMonth.year, thisMonth.month, 1)] = TransactionPage(
        transactions: [
          _expense(1, 'Food expense row', thisMonth, categoryId: 10),
          _transfer(2, 1234, thisMonth),
          _transfer(3, 5678, thisMonth),
        ],
        currentPage: 1,
        totalPages: 1,
      );

      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      await tester.tap(find.byKey(const Key('summaryTab-transfer')));
      await _pumpBounded(tester);

      // Ticket 08 acceptance: every transfer for the scope appears in the
      // tab's own list — scoped to `transferTabList` since the unfiltered
      // day-grouped feed below the summary card also renders these same two
      // transfers today (unrelated pre-existing behavior, not this tab).
      final transferList = find.byKey(const Key('transferTabList'));
      expect(find.descendant(of: transferList, matching: find.text(formatAmount(1234))), findsOneWidget);
      expect(find.descendant(of: transferList, matching: find.text(formatAmount(5678))), findsOneWidget);
      // ...the non-transfer transaction never leaks into this tab...
      expect(find.descendant(of: transferList, matching: find.text('Food expense row')), findsNothing);
      // ...and no aggregation/grouping is applied: exactly one row per
      // transfer, with a plain divider between them, not e.g. a single
      // account-pair total.
      final list = tester.widget<Column>(transferList);
      expect(list.children.whereType<Divider>().length, 1); // 2 rows => 1 separating divider
    });

    testWidgets('shows a "no transfers" empty state distinct from the placeholder copy', (tester) async {
      fakeTransactions.pages[(thisMonth.year, thisMonth.month, 1)] = TransactionPage(transactions: [], currentPage: 1, totalPages: 1);

      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      await tester.tap(find.byKey(const Key('summaryTab-transfer')));
      await _pumpBounded(tester);

      expect(find.text('ไม่มีรายการย้ายเงินในเดือนนี้'), findsOneWidget);
    });

    testWidgets('switching between Expense and Transfer tabs never empties either one', (tester) async {
      fakeDashboard.results[(thisMonth.year, thisMonth.month)] = Right(
        DashboardSummary(
          totalIncome: 0,
          totalExpense: 2000,
          totalTransfer: 0,
          year: thisMonth.year,
          month: thisMonth.month,
          income: const [],
          expense: [_breakdown(10, 'อาหาร', 2000)],
        ),
      );
      fakeTransactions.pages[(thisMonth.year, thisMonth.month, 1)] = TransactionPage(
        transactions: [_expense(1, 'Food expense row', thisMonth, categoryId: 10), _transfer(3, 999, thisMonth)],
        currentPage: 1,
        totalPages: 1,
      );

      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      expect(find.descendant(of: find.byKey(const Key('categoryTotalRow-10')), matching: find.text('อาหาร')), findsOneWidget);

      await tester.tap(find.byKey(const Key('summaryTab-transfer')));
      await _pumpBounded(tester);
      expect(
        find.descendant(of: find.byKey(const Key('transferTabList')), matching: find.text(formatAmount(999))),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('summaryTab-expense')));
      await _pumpBounded(tester);
      expect(find.descendant(of: find.byKey(const Key('categoryTotalRow-10')), matching: find.text('อาหาร')), findsOneWidget);
    });
  });

  group('ticket 04: summary page consolidation', () {
    setUp(() {
      fakeDashboard.results[(thisMonth.year, thisMonth.month)] = const Right(
        DashboardSummary(totalIncome: 0, totalExpense: 0, totalTransfer: 0, year: 0, month: 0, income: [], expense: []),
      );
    });

    const account = Account(
      id: 1,
      name: 'Main Wallet',
      accountType: AccountType.bank,
      openingBalance: 0,
      matchingKeywords: [],
      bankIcon: 'scb',
      isActive: true,
    );

    testWidgets('the page-level "+" button is gone; the pending-actions button remains', (tester) async {
      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      expect(find.byKey(const Key('newTransactionButton')), findsNothing);
      expect(find.byKey(const Key('pendingActionsButton')), findsOneWidget);
    });

    testWidgets(
      'post-launch-polish-08: the Topbar has no Filter icon and no filter chip row beneath it — only the month switcher and the one action button ticket 02 placed',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await _pumpBounded(tester);

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.actions, hasLength(1), reason: 'ticket 02\'s own action button, nothing else beside it');
        expect(find.byIcon(RemixIcon.filterLine), findsNothing);
        expect(find.byIcon(RemixIcon.filter3Line), findsNothing);
        expect(find.byIcon(RemixIcon.equalizerLine), findsNothing);
        // Ticket 08: not just the icon — ticket 07 only removed the AppBar
        // icon and left the whole type-chip row (ทั้งหมด/รายรับ/รายจ่าย/
        // ไม่ระบุหมวด N) sitting in `AppBar.bottom`. That row, and the
        // category-drill-through feature it doubled as a clear-button for,
        // are both gone now — asserting `bottom` is null is the direct way
        // to prove no secondary row survives under any state.
        expect(appBar.bottom, isNull);
        expect(find.text('ทั้งหมด'), findsNothing);
        expect(find.textContaining('ไม่ระบุหมวด'), findsNothing);
      },
    );

    testWidgets('the account-info strip renders on this page, showing each account and its balance', (tester) async {
      await tester.pumpWidget(
        buildApp(accountsRepository: _FakeAccountsRepository(accounts: const [account], balances: const {1: 2500})),
      );
      await _pumpBounded(tester);

      expect(find.byKey(const Key('accountInfoStrip')), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(const Key('accountInfoStrip')), matching: find.text('Main Wallet')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byKey(const Key('accountInfoStrip')), matching: find.text(formatAmount(2500))),
        findsOneWidget,
      );
    });

    group('post-launch-polish-03: Account Card subtitle', () {
      testWidgets('shows the account\'s matching_keywords as a white subtitle, not the generic balance disclaimer', (tester) async {
        const withKeywords = Account(
          id: 2,
          name: 'SCB Savings',
          accountType: AccountType.bank,
          openingBalance: 0,
          matchingKeywords: ['SCB EASY', 'ไทยพาณิชย์'],
          bankIcon: 'scb',
          isActive: true,
        );

        await tester.pumpWidget(
          buildApp(accountsRepository: _FakeAccountsRepository(accounts: const [withKeywords], balances: const {2: 1000})),
        );
        await _pumpBounded(tester);

        expect(find.text('SCB EASY, ไทยพาณิชย์'), findsOneWidget);
        expect(find.text(currentBalanceDisclaimer), findsNothing);

        final subtitle = tester.widget<Text>(find.text('SCB EASY, ไทยพาณิชย์'));
        expect(subtitle.style?.color, Colors.white);
      });

      testWidgets('an account with no matching_keywords shows a plain placeholder, still not the disclaimer', (tester) async {
        await tester.pumpWidget(
          buildApp(accountsRepository: _FakeAccountsRepository(accounts: const [account], balances: const {1: 2500})),
        );
        await _pumpBounded(tester);

        expect(find.text('—'), findsOneWidget);
        expect(find.text(currentBalanceDisclaimer), findsNothing);
      });
    });

    testWidgets('the month switcher lives in the AppBar title, not a secondary row below it', (tester) async {
      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.title, isNotNull, reason: 'the month switcher should be the AppBar title, matching Home');
      expect(
        find.descendant(of: find.byWidget(appBar.title!), matching: find.text(monthYearShortLabel(thisMonth))),
        findsOneWidget,
      );
      // Only ever rendered once on screen — proof it moved rather than
      // being duplicated between the title and a leftover secondary row.
      expect(find.text(monthYearShortLabel(thisMonth)), findsOneWidget);
    });

    testWidgets('switching months updates the account info, the summary tabs, and the list below together', (tester) async {
      final nextMonth = DateTime.utc(thisMonth.year, thisMonth.month + 1);
      fakeDashboard.results[(thisMonth.year, thisMonth.month)] = Right(
        DashboardSummary(
          totalIncome: 0,
          totalExpense: 2000,
          totalTransfer: 0,
          year: thisMonth.year,
          month: thisMonth.month,
          income: const [],
          expense: [_breakdown(10, 'อาหาร', 2000)],
        ),
      );
      fakeDashboard.results[(nextMonth.year, nextMonth.month)] = Right(
        DashboardSummary(
          totalIncome: 0,
          totalExpense: 900,
          totalTransfer: 0,
          year: nextMonth.year,
          month: nextMonth.month,
          income: const [],
          expense: [_breakdown(11, 'เดินทาง', 900)],
        ),
      );
      fakeTransactions.pages[(thisMonth.year, thisMonth.month, 1)] = TransactionPage(
        transactions: [_expense(1, 'This month row', thisMonth, categoryId: 10)],
        currentPage: 1,
        totalPages: 1,
      );
      fakeTransactions.pages[(nextMonth.year, nextMonth.month, 1)] = TransactionPage(
        transactions: [_expense(2, 'Next month row', nextMonth, categoryId: 11)],
        currentPage: 1,
        totalPages: 1,
      );

      await tester.pumpWidget(
        buildApp(accountsRepository: _FakeAccountsRepository(accounts: const [account], balances: const {1: 2500})),
      );
      await _pumpBounded(tester);

      // Scoped to the list row's own key, matching the pattern the rest of
      // this file uses for category name assertions. Checked before
      // scrolling — the account-info strip and summary card sit above the
      // day-grouped list, so this and the strip below are both still on
      // screen at the initial (top) scroll position.
      expect(find.descendant(of: find.byKey(const Key('categoryTotalRow-10')), matching: find.text('อาหาร')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('accountInfoStrip')), matching: find.text('Main Wallet')), findsOneWidget);
      await _scrollToFinder(tester, find.text('This month row'));
      expect(find.text('This month row'), findsOneWidget);

      // `_switchMonth` jumps the list back to the top on every switch, so
      // the strip/summary card are on screen again without any scrolling
      // back up.
      await tester.tap(find.byIcon(RemixIcon.arrowRightSLine));
      await _pumpBounded(tester);

      // Summary tab (still Expense, the default) now reflects next month's
      // breakdown...
      expect(find.descendant(of: find.byKey(const Key('categoryTotalRow-11')), matching: find.text('เดินทาง')), findsOneWidget);
      expect(find.text('อาหาร'), findsNothing);
      expect(find.descendant(of: find.byKey(const Key('accountInfoStrip')), matching: find.text('Main Wallet')), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(const Key('accountInfoStrip')), matching: find.text(formatAmount(2500))),
        findsOneWidget,
      );
      // ...the list below is next month's data too.
      await _scrollToFinder(tester, find.text('Next month row'));
      expect(find.text('Next month row'), findsOneWidget);
      expect(find.text('This month row'), findsNothing);
    });
  });
}

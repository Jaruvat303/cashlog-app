// Before any pumpWidget/pumpAndSettle, every repository this page touches is
// overridden with a hand-written fake (same pattern as _FakeAccountsRepository
// in test/widget_test.dart) — this is what keeps a real dio call or a real
// photo_manager platform-channel call from ever happening in this test
// environment.
import 'dart:async';
import 'dart:typed_data';

import 'package:cashlog/core/month/selected_month_provider.dart';
import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/accounts/data/accounts_repository.dart';
import 'package:cashlog/features/accounts/domain/account.dart';
import 'package:cashlog/features/categories/data/categories_repository.dart';
import 'package:cashlog/features/categories/domain/category.dart';
import 'package:cashlog/features/dashboard/data/dashboard_repository.dart';
import 'package:cashlog/features/dashboard/domain/dashboard_summary.dart';
import 'package:cashlog/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:cashlog/features/slip_scan/data/slip_gallery_repository.dart';
import 'package:cashlog/features/slip_scan/data/slip_upload_repository.dart';
import 'package:cashlog/features/slip_scan/domain/gallery_access_level.dart';
import 'package:cashlog/features/slip_scan/domain/slip_candidate.dart';
import 'package:cashlog/features/slip_scan/domain/slip_upload_outcome.dart';
import 'package:cashlog/features/slip_scan/presentation/providers/slip_scan_pipeline_provider.dart';
import 'package:cashlog/features/transactions/data/pending_actions_repository.dart';
import 'package:cashlog/features/transactions/data/transactions_repository.dart';
import 'package:cashlog/features/transactions/domain/pending_action.dart';
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:cashlog/features/transactions/domain/transaction_page.dart';
import 'package:cashlog/features/transactions/presentation/pages/pending_actions_page.dart';
import 'package:cashlog/shared/format/datetime.dart';
import 'package:cashlog/shared/format/money.dart';
import 'package:dartz/dartz.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

class _FakeAccountsRepository implements AccountsRepository {
  _FakeAccountsRepository({this.accounts = const []});

  final List<Account> accounts;

  @override
  Stream<List<Account>> watchActiveAccounts() => Stream.value(accounts);
  @override
  Stream<Account?> watchCached(int id) => Stream.value(null);
  @override
  Stream<double> watchCurrentBalance(int accountId) => Stream.value(0);
  @override
  Future<Either<Failure, void>> refreshFromApi() async => const Right(null);
  @override
  Future<Either<Failure, Account>> create({
    required String name,
    required AccountType accountType,
    required double openingBalance,
    required List<String> matchingKeywords,
    required String bankIcon,
  }) => throw UnimplementedError('not exercised by this page test');
  @override
  Future<Either<Failure, Account>> update(
    int id, {
    required String name,
    required AccountType accountType,
    required List<String> matchingKeywords,
    required String bankIcon,
  }) => throw UnimplementedError('not exercised by this page test');
  @override
  Future<Either<Failure, void>> close(int id) => throw UnimplementedError('not exercised by this page test');
}

class _FakeCategoriesRepository implements CategoriesRepository {
  _FakeCategoriesRepository({this.categories = const []});

  final List<Category> categories;

  @override
  Stream<List<Category>> watchAll() => Stream.value(categories);
  @override
  Future<Either<Failure, void>> refreshFromApi() async => const Right(null);
  @override
  Future<Either<Failure, Category>> create({
    required String name,
    required CategoryType type,
    required String iconKey,
    required String colorHex,
  }) => throw UnimplementedError('not exercised by this page test');
  @override
  Future<Either<Failure, Category>> update(
    int id, {
    required String name,
    required CategoryType type,
    required String iconKey,
    required String colorHex,
  }) => throw UnimplementedError('not exercised by this page test');
  @override
  Future<int> countLinkedTransactions(int categoryId) => throw UnimplementedError('not exercised by this page test');
  @override
  Future<Either<Failure, void>> delete(int id) => throw UnimplementedError('not exercised by this page test');
}

/// One independently-addressable (year, month) feed, matching the real
/// upsert-into-cache/read-from-cache split: [fetchPage] appends into
/// [current], [watchMonth] streams whatever's in [current] — including an
/// immediate replay of the latest snapshot to every new listener (an
/// `async*` seed + broadcast passthrough, since a real drift `.watch()` does
/// the same). [replace] additionally lets a test push a brand-new snapshot
/// for the month — standing in for a drift row being upserted in place after
/// a `PATCH` (e.g. a category getting assigned), which is exactly the
/// scenario ticket 06's regression test needs to drive.
class _MonthChannel {
  List<Transaction> current = [];
  final _controller = StreamController<List<Transaction>>.broadcast();

  Stream<List<Transaction>> get stream async* {
    yield current;
    yield* _controller.stream;
  }

  void append(List<Transaction> page) {
    current = [...current, ...page];
    _controller.add(current);
  }

  void replace(List<Transaction> transactions) {
    current = transactions;
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

  _MonthChannel channelFor(int year, int month) => _channels.putIfAbsent((year, month), () => _MonthChannel());

  @override
  Stream<List<Transaction>> watchMonth({required int year, required int month, int? categoryId}) =>
      channelFor(year, month).stream.map((list) => categoryId == null ? list : list.where((t) => t.categoryId == categoryId).toList());

  @override
  Future<Either<Failure, TransactionPage>> fetchPage({required int year, required int month, required int page, int limit = 20}) async {
    fetchCalls.add((year, month, page));
    final result = pages[(year, month, page)];
    if (result == null) return const Left(UnknownFailure(message: 'no page configured for this request'));
    channelFor(year, month).append(result.transactions);
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
  }) => throw UnimplementedError('not exercised by this page test');

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
  }) => throw UnimplementedError('not exercised by this page test');

  @override
  Future<Either<Failure, void>> delete(int id) => throw UnimplementedError('not exercised by this page test');
}

/// Ticket 07: `ExpenseTotalWidget` reads `dashboardSummaryProvider`, backed
/// by a real `ApiClient`/dio call unless overridden — same reasoning as
/// every other fake repository in this file (CLAUDE.md: never let a real
/// dio call hit Flutter's test HTTP stub).
class _FakeDashboardRepository implements DashboardRepository {
  final Map<(int, int), Either<Failure, DashboardSummary>> results = {};

  @override
  Future<Either<Failure, DashboardSummary>> fetchSummary({required int year, required int month}) async =>
      results[(year, month)] ?? const Left(UnknownFailure(message: 'no result configured for this month'));
}

class _FakeSlipGalleryRepository implements SlipGalleryRepository {
  GalleryAccessLevel requestAccessResult = GalleryAccessLevel.full;
  int requestAccessCalls = 0;
  int presentLimitedSelectionCalls = 0;

  @override
  Future<GalleryAccessLevel> currentAccess() async => requestAccessResult;
  @override
  Future<GalleryAccessLevel> requestAccess() async {
    requestAccessCalls++;
    return requestAccessResult;
  }
  @override
  Future<void> presentLimitedSelection() async => presentLimitedSelectionCalls++;
  @override
  Future<void> openSettings() async {}
  @override
  Future<List<SlipCandidate>> queryConfiguredAlbums() async => const [];
  @override
  Future<Uint8List?> readBytes(String assetId) async => null;
}

/// CLAUDE.md: never `Stream.multi()` in a fake exercised under `testWidgets`
/// — an `async*` generator that replays the current value then forwards the
/// broadcast controller's future events is the confirmed-safe shape. Needed
/// here because `TransactionListTile` reads `pendingActionsProvider`, which
/// is otherwise backed by a real drift db.
class _FakePendingActionsRepository implements PendingActionsRepository {
  List<PendingAction> _items = [];
  final _controller = StreamController<List<PendingAction>>.broadcast();

  @override
  Stream<List<PendingAction>> watchAll() async* {
    yield List.unmodifiable(_items);
    yield* _controller.stream;
  }

  /// Test-only seam: pushes a new snapshot to every current/future listener,
  /// same as a real drift row insert/delete would re-emit through
  /// `watchAll()`.
  void seed(List<PendingAction> items) {
    _items = items;
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Future<bool> recordIfTransient({
    required Failure failure,
    required PendingActionType actionType,
    required Map<String, dynamic> payload,
    int? targetTransactionId,
  }) => throw UnimplementedError('not exercised by this page test');

  @override
  Future<void> recordRetryFailure(int id, String? errorCode) => throw UnimplementedError('not exercised by this page test');

  @override
  Future<void> remove(int id) => throw UnimplementedError('not exercised by this page test');
}

/// Ticket 09: the page reads `lastAutoScanUploadProvider`, backed by
/// `SlipUploadRepository.watchLastSuccessfulAutoScanUpload` — a real
/// `AppDatabase` unless overridden, same reasoning as every other fake
/// repository in this file. `watchLastSuccessfulAutoScanUpload` is an
/// `async*` generator (CLAUDE.md: never `Stream.multi()` under
/// `testWidgets`) that replays the current value then forwards the
/// controller's future events — [seed] is the test-only hook that drives it,
/// standing in for a real successful auto-scan upload landing in
/// `scanned_slips`.
class _FakeSlipUploadRepository implements SlipUploadRepository {
  DateTime? _lastSuccessfulUpload;
  final _controller = StreamController<DateTime?>.broadcast();

  void seed(DateTime? value) {
    _lastSuccessfulUpload = value;
    _controller.add(value);
  }

  @override
  Stream<DateTime?> watchLastSuccessfulAutoScanUpload() async* {
    yield _lastSuccessfulUpload;
    yield* _controller.stream;
  }

  @override
  Future<List<SlipCandidate>> diffNewFiles(List<SlipCandidate> candidates) => throw UnimplementedError('not exercised by this page test');
  @override
  Future<Either<Failure, SlipUploadOutcome>> uploadOne(SlipCandidate candidate) => throw UnimplementedError('not exercised by this page test');
  @override
  Future<Either<Failure, SlipUploadOutcome>> uploadManual({required Uint8List bytes, required String filename}) =>
      throw UnimplementedError('not exercised by this page test');
}

/// Seeds `SlipScanPipeline`'s state directly (rather than driving it through
/// a real `runScan()`) — this ticket's DoD is that the Home banner is a pure
/// reader of `SlipScanProgress.accessLevel`, so the test only needs to
/// control that value, not re-exercise the scan pipeline itself (already
/// covered by slip_scan_pipeline_provider_test.dart).
class _FakeSlipScanPipeline extends SlipScanPipeline {
  _FakeSlipScanPipeline(this.initial);

  final SlipScanProgress initial;

  @override
  SlipScanProgress build() => initial;
}

SlipScanProgress _progress({GalleryAccessLevel? accessLevel}) => SlipScanProgress(
  isScanning: false,
  total: 0,
  completed: 0,
  currentFilename: null,
  results: const [],
  accessLevel: accessLevel,
);

DashboardSummary _summary(DateTime month, double totalExpense) => DashboardSummary(
  totalIncome: 0,
  totalExpense: totalExpense,
  totalTransfer: 0,
  year: month.year,
  month: month.month,
  income: const [],
  expense: const [],
);

Transaction _tx({
  required int id,
  TransactionType type = TransactionType.expense,
  int? categoryId,
  bool isJunk = false,
  String note = '',
  DateTime? date,
}) => Transaction(
  id: id,
  amount: isJunk ? 0 : 100,
  type: type,
  note: note,
  source: 'slip',
  transactionDate: date ?? DateTime.utc(2026, 9, id),
  categoryId: categoryId,
  isJunk: isJunk,
);

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
  late _FakeDashboardRepository fakeDashboard;
  late _FakePendingActionsRepository fakePendingActions;
  late _FakeSlipUploadRepository fakeSlipUpload;
  late DateTime thisMonth;

  setUp(() {
    fakeTransactions = _FakeTransactionsRepository();
    fakeDashboard = _FakeDashboardRepository();
    fakePendingActions = _FakePendingActionsRepository();
    fakeSlipUpload = _FakeSlipUploadRepository();
    final now = DateTime.now();
    thisMonth = DateTime.utc(now.year, now.month);
  });

  Widget buildApp({
    SlipScanProgress? pipelineState,
    _FakeSlipGalleryRepository? galleryRepo,
    List<Account> accounts = const [],
    List<Category> categories = const [],
  }) => ProviderScope(
    overrides: [
      accountsRepositoryProvider.overrideWithValue(_FakeAccountsRepository(accounts: accounts)),
      categoriesRepositoryProvider.overrideWithValue(_FakeCategoriesRepository(categories: categories)),
      transactionsRepositoryProvider.overrideWithValue(fakeTransactions),
      pendingActionsRepositoryProvider.overrideWithValue(fakePendingActions),
      slipGalleryRepositoryProvider.overrideWithValue(galleryRepo ?? _FakeSlipGalleryRepository()),
      slipScanPipelineProvider.overrideWith(() => _FakeSlipScanPipeline(pipelineState ?? _progress(accessLevel: GalleryAccessLevel.full))),
      dashboardRepositoryProvider.overrideWithValue(fakeDashboard),
      slipUploadRepositoryProvider.overrideWithValue(fakeSlipUpload),
    ],
    child: const MaterialApp(home: DashboardPage()),
  );

  PendingAction pendingAction(int id) => PendingAction(
    id: id,
    actionType: PendingActionType.createTransaction,
    payload: createTransactionPayload(type: TransactionType.expense, amount: 50, date: thisMonth, accountId: 1),
    createdAt: thisMonth,
  );

  group('ticket 06: Home is the full monthly transaction ledger', () {
    testWidgets('opening the app lands on the current month by default', (tester) async {
      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      expect(find.text(monthYearLabel(thisMonth)), findsOneWidget);
    });

    testWidgets(
      'renders every transaction for the month — categorized, junk, and transfer rows all included, not '
      'just ones needing attention',
      (tester) async {
        fakeTransactions.pages[(thisMonth.year, thisMonth.month, 1)] = TransactionPage(
          transactions: [
            _tx(id: 1, categoryId: 7, note: 'Categorized row', date: thisMonth),
            _tx(id: 2, note: 'Uncategorized row', date: thisMonth),
            _tx(id: 3, isJunk: true, note: 'Junk row', date: thisMonth),
            _tx(id: 4, type: TransactionType.transfer, note: 'Transfer row', date: thisMonth),
          ],
          currentPage: 1,
          totalPages: 1,
        );

        await tester.pumpWidget(buildApp());
        await _pumpBounded(tester);

        expect(find.text('ไม่มีรายการในเดือนนี้'), findsNothing);
        expect(find.byKey(const Key('transactionRowTapTarget')), findsNWidgets(4));
      },
    );

    testWidgets('a transaction remains visible after its category is set (regression test for the original bug)', (tester) async {
      const category = Category(id: 7, name: 'อาหาร', type: CategoryType.expense, iconKey: 'restaurant-fill', colorHex: '#EF4444');
      fakeTransactions.pages[(thisMonth.year, thisMonth.month, 1)] = TransactionPage(
        transactions: [_tx(id: 1, note: 'Needs a category', date: thisMonth)],
        currentPage: 1,
        totalPages: 1,
      );

      await tester.pumpWidget(buildApp(categories: const [category]));
      await _pumpBounded(tester);

      expect(find.text('Needs a category'), findsOneWidget);
      expect(find.text('ยังไม่ระบุหมวดหมู่'), findsOneWidget);

      // Simulate the drift row being upserted after a successful
      // `PATCH /transactions/1` that assigns a category — the same
      // `watchMonth` stream `TransactionsPage` relies on re-emits the
      // updated row in place, never dropping it.
      fakeTransactions.channelFor(thisMonth.year, thisMonth.month).replace([_tx(id: 1, categoryId: 7, note: 'Needs a category', date: thisMonth)]);
      await _pumpBounded(tester);

      expect(find.text('Needs a category'), findsOneWidget, reason: 'the row must stay visible once it is no longer pending');
      expect(find.text('ยังไม่ระบุหมวดหมู่'), findsNothing);
      expect(find.text('อาหาร'), findsOneWidget);
    });

    testWidgets('transactions are grouped by day within the selected month', (tester) async {
      final dayOne = DateTime.utc(thisMonth.year, thisMonth.month, 1);
      final dayFifteen = DateTime.utc(thisMonth.year, thisMonth.month, 15);
      fakeTransactions.pages[(thisMonth.year, thisMonth.month, 1)] = TransactionPage(
        transactions: [
          _tx(id: 1, note: 'Row on day one', date: dayOne),
          _tx(id: 2, note: 'Row on day fifteen', date: dayFifteen),
        ],
        currentPage: 1,
        totalPages: 1,
      );

      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      expect(find.text(relativeDayLabel(dayOne)), findsOneWidget);
      expect(find.text(relativeDayLabel(dayFifteen)), findsOneWidget);
    });

    testWidgets('renders page 1 on open and loads page 2 when scrolled to the bottom', (tester) async {
      // 20 rows is enough to fill the viewport and leave room to scroll.
      final pageOneRows = List.generate(20, (i) => _tx(id: i + 1, note: 'Page one row $i', date: thisMonth));
      final pageTwoRows = [_tx(id: 100, note: 'Page two exclusive row', date: thisMonth)];
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
        transactions: [_tx(id: 1, note: 'This month row', date: thisMonth)],
        currentPage: 1,
        totalPages: 1,
      );
      fakeTransactions.pages[(nextMonth.year, nextMonth.month, 1)] = TransactionPage(
        transactions: [_tx(id: 2, note: 'Next month row', date: nextMonth)],
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

    testWidgets('the account-info strip no longer renders here — it moved to the summary page in ticket 04', (tester) async {
      const account = Account(
        id: 1,
        name: 'Main Wallet',
        accountType: AccountType.bank,
        openingBalance: 0,
        matchingKeywords: [],
        bankIcon: 'scb',
        isActive: true,
      );

      await tester.pumpWidget(buildApp(accounts: const [account]));
      await _pumpBounded(tester);

      expect(find.byKey(const Key('accountInfoStrip')), findsNothing);
      expect(find.text('Main Wallet'), findsNothing);
    });

    testWidgets('shows an empty-state message when the month has no transactions', (tester) async {
      fakeTransactions.pages[(thisMonth.year, thisMonth.month, 1)] = const TransactionPage(transactions: [], currentPage: 1, totalPages: 1);

      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      expect(find.text('ไม่มีรายการในเดือนนี้'), findsOneWidget);
    });
  });

  group('ticket 07: expense-total widget with built-in month switcher', () {
    testWidgets('displays this month\'s total expense as a plain number — no chart, no breakdown', (tester) async {
      fakeDashboard.results[(thisMonth.year, thisMonth.month)] = Right(_summary(thisMonth, 4200));
      fakeTransactions.pages[(thisMonth.year, thisMonth.month, 1)] = TransactionPage(
        transactions: [_tx(id: 1, note: 'A row', date: thisMonth)],
        currentPage: 1,
        totalPages: 1,
      );

      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      expect(find.byKey(const Key('expenseTotalWidget')), findsOneWidget);
      expect(find.byKey(const Key('expenseTotalAmount')), findsOneWidget);
      expect(find.text(formatAmount(4200)), findsOneWidget);
      expect(find.byType(PieChart), findsNothing, reason: 'ticket 07 is a plain number, no chart — that is ticket 03, on a different page');
    });

    testWidgets('the month switcher lives inside this widget, not the AppBar title', (tester) async {
      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.title, isA<Text>());
      expect((appBar.title! as Text).data, 'หน้าแรก', reason: 'the AppBar title is a static page label now, not the month switcher');
      // Only ever rendered once on screen — proof it moved rather than
      // being duplicated between the AppBar and the widget.
      expect(find.text(monthYearLabel(thisMonth)), findsOneWidget);

      final widgetFinder = find.byKey(const Key('expenseTotalWidget'));
      expect(find.descendant(of: widgetFinder, matching: find.text(monthYearLabel(thisMonth))), findsOneWidget);
      expect(find.descendant(of: widgetFinder, matching: find.byIcon(RemixIcon.arrowLeftSLine)), findsOneWidget);
      expect(find.descendant(of: widgetFinder, matching: find.byIcon(RemixIcon.arrowRightSLine)), findsOneWidget);
    });

    testWidgets('changing the month via this widget updates the widget\'s total and the transaction list together', (tester) async {
      final nextMonth = DateTime.utc(thisMonth.year, thisMonth.month + 1);
      fakeDashboard.results[(thisMonth.year, thisMonth.month)] = Right(_summary(thisMonth, 2000));
      fakeDashboard.results[(nextMonth.year, nextMonth.month)] = Right(_summary(nextMonth, 900));
      fakeTransactions.pages[(thisMonth.year, thisMonth.month, 1)] = TransactionPage(
        transactions: [_tx(id: 1, note: 'This month row', date: thisMonth)],
        currentPage: 1,
        totalPages: 1,
      );
      fakeTransactions.pages[(nextMonth.year, nextMonth.month, 1)] = TransactionPage(
        transactions: [_tx(id: 2, note: 'Next month row', date: nextMonth)],
        currentPage: 1,
        totalPages: 1,
      );

      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      expect(find.text(formatAmount(2000)), findsOneWidget);
      expect(find.text('This month row'), findsOneWidget);

      await tester.tap(find.byIcon(RemixIcon.arrowRightSLine));
      await _pumpBounded(tester);

      expect(find.text(formatAmount(2000)), findsNothing);
      expect(find.text(formatAmount(900)), findsOneWidget);
      expect(find.text('This month row'), findsNothing);
      expect(find.text('Next month row'), findsOneWidget);
    });

    testWidgets('the widget sits above the transaction list', (tester) async {
      fakeDashboard.results[(thisMonth.year, thisMonth.month)] = Right(_summary(thisMonth, 1500));
      fakeTransactions.pages[(thisMonth.year, thisMonth.month, 1)] = TransactionPage(
        transactions: [_tx(id: 1, note: 'A row', date: thisMonth)],
        currentPage: 1,
        totalPages: 1,
      );

      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      final widgetTop = tester.getTopLeft(find.byKey(const Key('expenseTotalWidget'))).dy;
      final rowTop = tester.getTopLeft(find.byKey(const Key('transactionRowTapTarget')).first).dy;
      expect(widgetTop, lessThan(rowTop));
    });
  });

  group('ticket 08: pending-items banner', () {
    testWidgets('shows a live count sourced from the existing pending-actions query', (tester) async {
      fakePendingActions.seed([pendingAction(1), pendingAction(2)]);

      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      expect(find.byKey(const Key('pendingActionsBanner')), findsOneWidget);
      expect(find.text('มีรายการค้างอยู่ 2 รายการ — แตะเพื่อดำเนินการ'), findsOneWidget);
    });

    testWidgets('count updates live as the underlying pending-actions stream changes', (tester) async {
      fakePendingActions.seed([pendingAction(1)]);

      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);
      expect(find.textContaining('1 รายการ'), findsOneWidget);

      fakePendingActions.seed([pendingAction(1), pendingAction(2), pendingAction(3)]);
      await _pumpBounded(tester);

      expect(find.textContaining('3 รายการ'), findsOneWidget);
    });

    testWidgets('sits beneath the expense-total widget and above the transaction list', (tester) async {
      fakePendingActions.seed([pendingAction(1)]);
      fakeTransactions.pages[(thisMonth.year, thisMonth.month, 1)] = TransactionPage(
        transactions: [_tx(id: 1, note: 'A row', date: thisMonth)],
        currentPage: 1,
        totalPages: 1,
      );

      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      final expenseTotalTop = tester.getTopLeft(find.byKey(const Key('expenseTotalWidget'))).dy;
      final bannerTop = tester.getTopLeft(find.byKey(const Key('pendingActionsBanner'))).dy;
      final rowTop = tester.getTopLeft(find.byKey(const Key('transactionRowTapTarget')).first).dy;
      expect(expenseTotalTop, lessThan(bannerTop));
      expect(bannerTop, lessThan(rowTop));
    });

    testWidgets('tapping the banner opens the existing pending-actions page, unchanged', (tester) async {
      fakePendingActions.seed([pendingAction(1)]);

      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      await tester.tap(find.byKey(const Key('pendingActionsBanner')));
      await _pumpBounded(tester);

      expect(find.byType(PendingActionsPage), findsOneWidget);
    });

    testWidgets('zero pending items: no dead banner space, matching the app\'s existing zero-count convention', (tester) async {
      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      expect(find.byKey(const Key('pendingActionsBanner')), findsNothing);
    });

    testWidgets('no duplicate pending count/badge is added anywhere else on Home', (tester) async {
      fakePendingActions.seed([pendingAction(1)]);

      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      expect(find.byType(Badge), findsNothing, reason: 'the banner is the single source of this count on Home, unlike TransactionsPage\'s AppBar badge');
    });
  });

  group('ticket 09: last successful auto-scan upload timestamp', () {
    testWidgets('shows a placeholder when auto-scan has never uploaded anything successfully', (tester) async {
      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      expect(find.byKey(const Key('lastAutoScanUploadText')), findsOneWidget);
      expect(find.text('ยังไม่มีการอัปโหลดสลิปอัตโนมัติ'), findsOneWidget);
    });

    testWidgets('shows readable date/time text once auto-scan has uploaded a slip successfully', (tester) async {
      final uploadedAt = DateTime.now().subtract(const Duration(minutes: 5));
      fakeSlipUpload.seed(uploadedAt);

      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      expect(find.text('สแกนสลิปอัตโนมัติล่าสุด: ${dateTimeLabel(uploadedAt)}'), findsOneWidget);
    });

    testWidgets('updates live when a genuinely new successful auto-scan upload lands', (tester) async {
      final firstUpload = DateTime.now().subtract(const Duration(hours: 2));
      fakeSlipUpload.seed(firstUpload);

      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);
      expect(find.text('สแกนสลิปอัตโนมัติล่าสุด: ${dateTimeLabel(firstUpload)}'), findsOneWidget);

      final secondUpload = DateTime.now();
      fakeSlipUpload.seed(secondUpload);
      await _pumpBounded(tester);

      expect(find.text('สแกนสลิปอัตโนมัติล่าสุด: ${dateTimeLabel(firstUpload)}'), findsNothing);
      expect(find.text('สแกนสลิปอัตโนมัติล่าสุด: ${dateTimeLabel(secondUpload)}'), findsOneWidget);
    });

    testWidgets('stays fixed across repeated no-new-files scan cycles — a stale value is the intended signal', (tester) async {
      final onlyUpload = DateTime.now().subtract(const Duration(days: 1));
      fakeSlipUpload.seed(onlyUpload);

      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);
      expect(find.text('สแกนสลิปอัตโนมัติล่าสุด: ${dateTimeLabel(onlyUpload)}'), findsOneWidget);

      // A "scan cycle runs but finds nothing new" never calls anything that
      // touches `watchLastSuccessfulAutoScanUpload`'s backing data — no
      // seed() call here simulates exactly that repeatedly, across several
      // pumps, and the displayed text must not move.
      await _pumpBounded(tester);
      await _pumpBounded(tester);

      expect(find.text('สแกนสลิปอัตโนมัติล่าสุด: ${dateTimeLabel(onlyUpload)}'), findsOneWidget);
    });

    testWidgets('does not move when unrelated Home state changes (pending actions, transactions)', (tester) async {
      final onlyUpload = DateTime.now().subtract(const Duration(hours: 3));
      fakeSlipUpload.seed(onlyUpload);
      fakePendingActions.seed([pendingAction(1)]);
      fakeTransactions.pages[(thisMonth.year, thisMonth.month, 1)] = TransactionPage(
        transactions: [_tx(id: 1, note: 'A row', date: thisMonth)],
        currentPage: 1,
        totalPages: 1,
      );

      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);
      expect(find.text('สแกนสลิปอัตโนมัติล่าสุด: ${dateTimeLabel(onlyUpload)}'), findsOneWidget);

      // Simulates a manually-created transaction landing on Home (ticket
      // 05's FAB "create manually" option) and a pending-actions count
      // change — neither is a slip upload, so neither should touch this
      // text.
      fakeTransactions.channelFor(thisMonth.year, thisMonth.month).append([_tx(id: 2, note: 'Manually created row', date: thisMonth)]);
      fakePendingActions.seed([pendingAction(1), pendingAction(2)]);
      await _pumpBounded(tester);

      expect(find.text('สแกนสลิปอัตโนมัติล่าสุด: ${dateTimeLabel(onlyUpload)}'), findsOneWidget);
    });

    testWidgets('sits beneath the pending-actions banner, above the gallery-permission banner', (tester) async {
      final onlyUpload = DateTime.now();
      fakeSlipUpload.seed(onlyUpload);
      fakePendingActions.seed([pendingAction(1)]);

      await tester.pumpWidget(
        buildApp(pipelineState: _progress(accessLevel: GalleryAccessLevel.denied)),
      );
      await _pumpBounded(tester);

      final bannerTop = tester.getTopLeft(find.byKey(const Key('pendingActionsBanner'))).dy;
      final statusTop = tester.getTopLeft(find.byKey(const Key('lastAutoScanUploadText'))).dy;
      final galleryBannerTop = tester.getTopLeft(find.byKey(const Key('galleryPermissionBanner'))).dy;
      expect(bannerTop, lessThan(statusTop));
      expect(statusTop, lessThan(galleryBannerTop));
    });
  });

  group('gallery permission banner', () {
    testWidgets('full access shows no permission banner', (tester) async {
      await tester.pumpWidget(buildApp(pipelineState: _progress(accessLevel: GalleryAccessLevel.full)));
      await _pumpBounded(tester);

      expect(find.byKey(const Key('galleryPermissionBanner')), findsNothing);
    });

    testWidgets('no scan attempted yet (null accessLevel) shows no permission banner', (tester) async {
      await tester.pumpWidget(buildApp(pipelineState: _progress()));
      await _pumpBounded(tester);

      expect(find.byKey(const Key('galleryPermissionBanner')), findsNothing);
    });

    testWidgets('denied access shows a banner whose button triggers requestAccess', (tester) async {
      final galleryRepo = _FakeSlipGalleryRepository();
      await tester.pumpWidget(buildApp(pipelineState: _progress(accessLevel: GalleryAccessLevel.denied), galleryRepo: galleryRepo));
      await _pumpBounded(tester);

      expect(find.byKey(const Key('galleryPermissionBanner')), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'ให้สิทธิ์เข้าถึง'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'ให้สิทธิ์เข้าถึง'));
      await _pumpBounded(tester);

      expect(galleryRepo.requestAccessCalls, 1);
      expect(galleryRepo.presentLimitedSelectionCalls, 0);
    });

    testWidgets('limited access shows a banner whose button triggers presentLimitedSelection', (tester) async {
      final galleryRepo = _FakeSlipGalleryRepository();
      await tester.pumpWidget(buildApp(pipelineState: _progress(accessLevel: GalleryAccessLevel.limited), galleryRepo: galleryRepo));
      await _pumpBounded(tester);

      expect(find.byKey(const Key('galleryPermissionBanner')), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'เลือกรูปเพิ่มเติม'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'เลือกรูปเพิ่มเติม'));
      await _pumpBounded(tester);

      expect(galleryRepo.presentLimitedSelectionCalls, 1);
      expect(galleryRepo.requestAccessCalls, 0);
    });
  });
}

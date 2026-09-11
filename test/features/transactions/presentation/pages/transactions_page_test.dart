// Before any pumpWidget/pumpAndSettle, every repository the feed touches is
// overridden with a hand-written fake (same pattern as
// _FakeAccountsRepository in test/widget_test.dart / transaction_form_page_test.dart)
// — this is what keeps a real dio call from ever reaching Flutter's test
// HTTP stub, the exact thing that caused a hang in T4.
import 'dart:async';

import 'dart:typed_data';

import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/accounts/data/accounts_repository.dart';
import 'package:cashlog/features/accounts/domain/account.dart';
import 'package:cashlog/features/categories/data/categories_repository.dart';
import 'package:cashlog/features/categories/domain/category.dart';
import 'package:cashlog/features/slip_scan/data/slip_upload_repository.dart';
import 'package:cashlog/features/slip_scan/domain/slip_candidate.dart';
import 'package:cashlog/features/slip_scan/domain/slip_upload_outcome.dart';
import 'package:cashlog/features/slip_scan/presentation/widgets/manual_slip_attach_button.dart';
import 'package:cashlog/features/transactions/data/pending_action_mapper.dart';
import 'package:cashlog/features/transactions/data/pending_actions_repository.dart';
import 'package:cashlog/features/transactions/data/transactions_repository.dart';
import 'package:cashlog/features/transactions/domain/pending_action.dart';
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:cashlog/features/transactions/domain/transaction_page.dart';
import 'package:cashlog/features/transactions/presentation/pages/transactions_page.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class _FakeAccountsRepository implements AccountsRepository {
  @override
  Stream<List<Account>> watchActiveAccounts() => Stream.value(const []);

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

/// T21: stands in for `image_picker`'s `ImagePicker` — [pickImage] never
/// touches a real platform channel (which doesn't exist under
/// `flutter test`, CLAUDE.md's testing rule), just hands back whatever
/// [nextFile] a test has scripted.
class _FakeManualSlipImageSource implements ManualSlipImageSource {
  XFile? nextFile;
  final List<ImageSource> requestedSources = [];

  @override
  Future<XFile?> pickImage(ImageSource source) async {
    requestedSources.add(source);
    return nextFile;
  }
}

/// T21: records manual-attach calls only — [uploadOne]/[diffNewFiles] are
/// never exercised by this feed test (that's the auto-scan pipeline's own
/// test suite).
class _FakeSlipUploadRepository implements SlipUploadRepository {
  final List<(Uint8List, String)> manualCalls = [];
  Either<Failure, SlipUploadOutcome> Function(Uint8List bytes, String filename)? scriptManual;

  /// T21: when set, [uploadManual] blocks here before returning — lets a
  /// test observe the button's in-flight (disabled/spinner) state.
  Completer<void>? gate;

  @override
  Future<Either<Failure, SlipUploadOutcome>> uploadManual({required Uint8List bytes, required String filename}) async {
    if (gate != null) await gate!.future;
    manualCalls.add((bytes, filename));
    return (scriptManual ?? (_, _) => Right(SlipUploaded(_expense(999, 'from slip', DateTime.utc(2026, 9, 1)))))(bytes, filename);
  }

  @override
  Future<List<SlipCandidate>> diffNewFiles(List<SlipCandidate> candidates) => throw UnimplementedError('not exercised by this feed test');

  @override
  Future<Either<Failure, SlipUploadOutcome>> uploadOne(SlipCandidate candidate) => throw UnimplementedError('not exercised by this feed test');
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
  late _FakePendingActionsRepository pendingActions;
  late _FakeManualSlipImageSource manualImageSource;
  late _FakeSlipUploadRepository manualSlipUploadRepository;

  setUp(() {
    fakeTransactions = _FakeTransactionsRepository();
    final now = DateTime.now();
    thisMonth = DateTime.utc(now.year, now.month);
    // TransactionsPage's badge reads straight off this repository's own
    // watchAll() stream, so seeding rows here exercises the same code path
    // the badge uses, not a stand-in count.
    pendingActions = _FakePendingActionsRepository();
    manualImageSource = _FakeManualSlipImageSource();
    manualSlipUploadRepository = _FakeSlipUploadRepository();
  });

  Widget buildApp() => ProviderScope(
    overrides: [
      accountsRepositoryProvider.overrideWithValue(_FakeAccountsRepository()),
      categoriesRepositoryProvider.overrideWithValue(_FakeCategoriesRepository()),
      transactionsRepositoryProvider.overrideWithValue(fakeTransactions),
      pendingActionsRepositoryProvider.overrideWithValue(pendingActions),
      manualSlipImageSourceProvider.overrideWithValue(manualImageSource),
      slipUploadRepositoryProvider.overrideWithValue(manualSlipUploadRepository),
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

      expect(find.text('Stuck items'), findsOneWidget);
    });
  });

  group('T21 manual slip attach button', () {
    testWidgets('is present on the feed and opens a camera/gallery chooser on tap', (tester) async {
      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      expect(find.byKey(const Key('manualSlipAttachButton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('manualSlipAttachButton')));
      await _pumpBounded(tester);

      expect(find.byKey(const Key('manualSlipAttachCameraOption')), findsOneWidget);
      expect(find.byKey(const Key('manualSlipAttachGalleryOption')), findsOneWidget);
      // Never actually picked a source — the (fake) image source should
      // stay untouched by opening the chooser alone.
      expect(manualImageSource.requestedSources, isEmpty);
    });

    testWidgets('picking "choose from gallery" feeds the picked bytes into the same upload path T10 built', (tester) async {
      manualImageSource.nextFile = XFile.fromData(Uint8List.fromList([1, 2, 3]), path: '/fake/manual_slip.jpg');

      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      await tester.tap(find.byKey(const Key('manualSlipAttachButton')));
      await _pumpBounded(tester);
      await tester.tap(find.byKey(const Key('manualSlipAttachGalleryOption')));
      await _pumpBounded(tester);

      expect(manualImageSource.requestedSources, [ImageSource.gallery]);
      expect(manualSlipUploadRepository.manualCalls, hasLength(1));
      final (bytes, filename) = manualSlipUploadRepository.manualCalls.single;
      expect(bytes, [1, 2, 3]);
      expect(filename, 'manual_slip.jpg');
      expect(find.text('Slip uploaded'), findsOneWidget);
    });

    testWidgets('picking "take photo" requests the camera source', (tester) async {
      manualImageSource.nextFile = XFile.fromData(Uint8List.fromList([9]), path: '/fake/camera_slip.jpg');

      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      await tester.tap(find.byKey(const Key('manualSlipAttachButton')));
      await _pumpBounded(tester);
      await tester.tap(find.byKey(const Key('manualSlipAttachCameraOption')));
      await _pumpBounded(tester);

      expect(manualImageSource.requestedSources, [ImageSource.camera]);
    });

    testWidgets('the button disables and shows progress while a manual upload is in flight', (tester) async {
      manualImageSource.nextFile = XFile.fromData(Uint8List.fromList([1]), path: '/fake/manual_slip.jpg');
      final gate = Completer<void>();
      manualSlipUploadRepository.gate = gate;

      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);

      await tester.tap(find.byKey(const Key('manualSlipAttachButton')));
      await _pumpBounded(tester);
      await tester.tap(find.byKey(const Key('manualSlipAttachGalleryOption')));
      await _pumpBounded(tester);

      expect(
        find.descendant(of: find.byKey(const Key('manualSlipAttachButton')), matching: find.byType(CircularProgressIndicator)),
        findsOneWidget,
      );
      final button = tester.widget<IconButton>(find.byKey(const Key('manualSlipAttachButton')));
      expect(button.onPressed, isNull, reason: 'disabled while a manual upload is already in flight');

      gate.complete();
      await _pumpBounded(tester);
      expect(
        find.descendant(of: find.byKey(const Key('manualSlipAttachButton')), matching: find.byType(CircularProgressIndicator)),
        findsNothing,
      );
    });
  });
}

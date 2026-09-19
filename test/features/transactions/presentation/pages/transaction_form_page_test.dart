// Before any pumpWidget/pumpAndSettle, every repository this form touches
// is overridden with a hand-written fake (same pattern as
// _FakeAccountsRepository in test/widget_test.dart) — this is what keeps a
// real dio call from ever reaching Flutter's test HTTP stub, the exact
// thing that caused a hang in T4.
import 'dart:async';
import 'dart:typed_data';

import 'package:cashlog/core/cache/cache_invalidator.dart';
import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/accounts/data/accounts_repository.dart';
import 'package:cashlog/features/accounts/domain/account.dart';
import 'package:cashlog/features/categories/data/categories_repository.dart';
import 'package:cashlog/features/categories/domain/category.dart';
import 'package:cashlog/features/slip_scan/data/slip_gallery_repository.dart';
import 'package:cashlog/features/slip_scan/domain/gallery_access_level.dart';
import 'package:cashlog/features/slip_scan/domain/slip_candidate.dart';
import 'package:cashlog/features/transactions/data/pending_action_mapper.dart';
import 'package:cashlog/features/transactions/data/pending_actions_repository.dart';
import 'package:cashlog/features/transactions/data/transactions_repository.dart';
import 'package:cashlog/features/transactions/domain/pending_action.dart';
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:cashlog/features/transactions/domain/transaction_page.dart';
import 'package:cashlog/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

class _FakeAccountsRepository implements AccountsRepository {
  @override
  Stream<List<Account>> watchActiveAccounts() => Stream.value(const [
    Account(id: 1, name: 'Cash', accountType: AccountType.cash, openingBalance: 0, matchingKeywords: [], bankIcon: 'cash', isActive: true),
    Account(id: 2, name: 'SCB', accountType: AccountType.bank, openingBalance: 0, matchingKeywords: [], bankIcon: 'scb', isActive: true),
  ]);

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
  }) => throw UnimplementedError('not exercised by this form test');

  @override
  Future<Either<Failure, Account>> update(
    int id, {
    required String name,
    required AccountType accountType,
    required List<String> matchingKeywords,
    required String bankIcon,
  }) => throw UnimplementedError('not exercised by this form test');

  @override
  Future<Either<Failure, void>> close(int id) => throw UnimplementedError('not exercised by this form test');
}

class _FakeCategoriesRepository implements CategoriesRepository {
  @override
  Stream<List<Category>> watchAll() => Stream.value(const [
    Category(id: 10, name: 'Food', type: CategoryType.expense, iconKey: 'food', colorHex: '#EF4444'),
    Category(id: 20, name: 'Salary', type: CategoryType.income, iconKey: 'salary', colorHex: '#22C55E'),
  ]);

  @override
  Future<Either<Failure, void>> refreshFromApi() async => const Right(null);

  @override
  Future<Either<Failure, Category>> create({
    required String name,
    required CategoryType type,
    required String iconKey,
    required String colorHex,
  }) => throw UnimplementedError('not exercised by this form test');

  @override
  Future<Either<Failure, Category>> update(
    int id, {
    required String name,
    required CategoryType type,
    required String iconKey,
    required String colorHex,
  }) => throw UnimplementedError('not exercised by this form test');

  @override
  Future<int> countLinkedTransactions(int categoryId) => throw UnimplementedError('not exercised by this form test');

  @override
  Future<Either<Failure, void>> delete(int id) => throw UnimplementedError('not exercised by this form test');
}

/// A minimal valid 1x1 transparent PNG — `Image.memory` in the slip preview
/// widget actually decodes whatever bytes `readBytes` returns, so an
/// arbitrary byte list (as used by the upload-path fakes elsewhere in this
/// codebase, which never render the bytes) isn't enough here.
final _fakeSlipImageBytes = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

/// Ticket 05: fakes `SlipGalleryRepository` the same way
/// `slip_gallery_debug_page_test.dart` does — no real `photo_manager`
/// platform-channel call from ever happening under `flutter test`.
class _FakeSlipGalleryRepository implements SlipGalleryRepository {
  List<SlipCandidate> candidates = const [];
  final Map<String, Uint8List?> bytesById = {};
  int queryCalls = 0;

  @override
  Future<GalleryAccessLevel> currentAccess() async => GalleryAccessLevel.full;

  @override
  Future<GalleryAccessLevel> requestAccess() async => GalleryAccessLevel.full;

  @override
  Future<void> presentLimitedSelection() async {}

  @override
  Future<void> openSettings() async {}

  @override
  Future<List<SlipCandidate>> queryConfiguredAlbums() async {
    queryCalls++;
    return candidates;
  }

  @override
  Future<Uint8List?> readBytes(String assetId) async => bytesById[assetId];
}

class _FakeTransactionsRepository implements TransactionsRepository {
  int createCallCount = 0;
  // T13: when set, [create] returns this instead of its default success —
  // lets a test drive a real failure through the actual submit path.
  Either<Failure, Transaction>? nextCreateResult;

  @override
  Stream<List<Transaction>> watchMonth({required int year, required int month, int? categoryId}) =>
      throw UnimplementedError('not exercised by this form test');

  @override
  Future<Either<Failure, TransactionPage>> fetchPage({required int year, required int month, required int page, int limit = 20}) =>
      throw UnimplementedError('not exercised by this form test');

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
  }) async {
    createCallCount++;
    final forced = nextCreateResult;
    if (forced != null) return forced;
    return Right(
      Transaction(
        id: 1,
        amount: amount,
        type: type,
        accountId: accountId,
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        categoryId: categoryId,
        source: 'manual',
        transactionDate: date,
      ),
    );
  }

  int updateCallCount = 0;
  Either<Failure, Transaction>? nextUpdateResult;

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
  }) async {
    updateCallCount++;
    final forced = nextUpdateResult;
    if (forced != null) return forced;
    return Right(
      Transaction(
        id: id,
        amount: amount,
        type: type,
        accountId: accountId,
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        categoryId: categoryId,
        source: 'manual',
        transactionDate: date,
      ),
    );
  }

  final List<int> deleteCalls = [];
  Either<Failure, void> deleteResult = const Right(null);

  @override
  Future<Either<Failure, void>> delete(int id) async {
    deleteCalls.add(id);
    return deleteResult;
  }
}

/// T14: records exactly which months this form's mutation asked to
/// invalidate, without needing the real `monthTransactionsProvider`/
/// `dashboardSummaryProvider` families (and their repositories) wired up —
/// the actual invalidation mechanics are covered by
/// test/core/cache/cache_invalidator_test.dart.
class _RecordingCacheInvalidator implements CacheInvalidator {
  final List<Set<(int, int)>> invalidatedMonthSets = [];

  @override
  void invalidateMonth(int year, int month) => invalidatedMonthSets.add({(year, month)});

  @override
  void invalidateMonths(Set<(int, int)> months) => invalidatedMonthSets.add(months);
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
  Future<void> recordRetryFailure(int id, String? errorCode) => throw UnimplementedError('not exercised by this form test');

  @override
  Future<void> remove(int id) => throw UnimplementedError('not exercised by this form test');
}

/// pumpAndSettle can't tell "still legitimately loading" from "stuck
/// forever" — a bounded pump loop fails fast instead (same reasoning as
/// test/widget_test.dart's `_pumpBounded`).
Future<void> _pumpBounded(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Ticket 05's slip-image section makes the edit-mode form taller than the
/// test viewport, so fields further down the `ListView` (submit/delete) are
/// no longer built until scrolled into view — the sliver list only builds
/// visible (+cache-extent) children, same as any other scrollable list.
Future<void> _scrollToKey(WidgetTester tester, Key key) =>
    tester.scrollUntilVisible(find.byKey(key), 300, scrollable: find.byType(Scrollable).first);

void main() {
  late _FakeTransactionsRepository fakeTransactions;
  late _FakePendingActionsRepository pendingActions;
  late _RecordingCacheInvalidator cacheInvalidator;
  late _FakeSlipGalleryRepository fakeSlipGallery;

  setUp(() {
    fakeTransactions = _FakeTransactionsRepository();
    // T13's tests below assert against this repository's own state after
    // driving a failure through the actual submit path, not a pre-seeded
    // stand-in.
    pendingActions = _FakePendingActionsRepository();
    cacheInvalidator = _RecordingCacheInvalidator();
    fakeSlipGallery = _FakeSlipGalleryRepository();
    // Multiple tests in this file decode the same `_fakeSlipImageBytes` via
    // `Image.memory` — without clearing Flutter's global `ImageCache`
    // between tests, a resolve from an earlier test can be reused (or, in a
    // decode race between tests sharing the same isolate, occasionally
    // report a decode failure) for a later test's *different* `Image`
    // widget, which renders as Flutter's built-in unconstrained error
    // widget and overflows `_SlipInfoCard`'s Row — not a real app bug, just
    // test-image-cache pollution across `testWidgets` in the same file.
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  Widget buildEditApp(Transaction initial) => ProviderScope(
    overrides: [
      accountsRepositoryProvider.overrideWithValue(_FakeAccountsRepository()),
      categoriesRepositoryProvider.overrideWithValue(_FakeCategoriesRepository()),
      transactionsRepositoryProvider.overrideWithValue(fakeTransactions),
      pendingActionsRepositoryProvider.overrideWithValue(pendingActions),
      cacheInvalidatorProvider.overrideWithValue(cacheInvalidator),
      slipGalleryRepositoryProvider.overrideWithValue(fakeSlipGallery),
    ],
    child: MaterialApp(home: TransactionFormPage(initial: initial)),
  );

  group('T14 cache invalidation', () {
    testWidgets('editing a transaction without changing its date invalidates only that one month', (tester) async {
      final original = Transaction(
        id: 42,
        amount: 100,
        type: TransactionType.expense,
        source: 'manual',
        transactionDate: DateTime(2026, 9, 15),
      );
      await tester.pumpWidget(buildEditApp(original));
      await _pumpBounded(tester);

      await tester.tap(find.byKey(const Key('accountPill')));
      await _pumpBounded(tester);
      await tester.tap(find.byKey(const Key('accountOption_1')));
      await _pumpBounded(tester);

      await _scrollToKey(tester, const Key('submitButton'));
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pumpAndSettle(const Duration(milliseconds: 50), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));

      expect(fakeTransactions.updateCallCount, 1);
      expect(cacheInvalidator.invalidatedMonthSets, [
        {(2026, 9)},
      ]);
    });
  });

  /// Ticket 04: delete moved off `TransactionListTile`'s junk-only icon
  /// onto this page, for any transaction (junk or not). Same confirm-dialog
  /// copy, delete/invalidate/queue flow this page already had pre-ticket —
  /// this group is the test coverage that flow never had until now.
  group('delete action (ticket 04)', () {
    final existing = Transaction(
      id: 7,
      amount: 500,
      type: TransactionType.expense,
      source: 'manual',
      transactionDate: DateTime.utc(2026, 9, 5),
    );

    testWidgets('delete button appears when editing an existing transaction', (tester) async {
      await tester.pumpWidget(buildEditApp(existing));
      await _pumpBounded(tester);
      await _scrollToKey(tester, const Key('deleteTransactionButton'));

      expect(find.byKey(const Key('deleteTransactionButton')), findsOneWidget);
    });

    testWidgets('tapping delete shows the confirm dialog; canceling does not delete', (tester) async {
      await tester.pumpWidget(buildEditApp(existing));
      await _pumpBounded(tester);

      await _scrollToKey(tester, const Key('deleteTransactionButton'));
      await tester.tap(find.byKey(const Key('deleteTransactionButton')));
      await _pumpBounded(tester);
      expect(find.text('ลบรายการนี้ใช่ไหม'), findsOneWidget);
      expect(find.text('การลบไม่สามารถกู้คืนได้'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'ยกเลิก'));
      await _pumpBounded(tester);

      expect(fakeTransactions.deleteCalls, isEmpty);
    });

    testWidgets('confirming delete calls the repository and invalidates the deleted transaction\'s month', (tester) async {
      await tester.pumpWidget(buildEditApp(existing));
      await _pumpBounded(tester);

      await _scrollToKey(tester, const Key('deleteTransactionButton'));
      await tester.tap(find.byKey(const Key('deleteTransactionButton')));
      await _pumpBounded(tester);
      await tester.tap(find.widgetWithText(TextButton, 'ลบ'));
      await _pumpBounded(tester);

      expect(fakeTransactions.deleteCalls, [existing.id]);
      expect(cacheInvalidator.invalidatedMonthSets, [
        {(existing.transactionDate.year, existing.transactionDate.month)},
      ]);
    });

    testWidgets('a failed delete shows an error and never invalidates the cache', (tester) async {
      fakeTransactions.deleteResult = const Left(UnknownFailure(message: 'Could not delete transaction'));
      await tester.pumpWidget(buildEditApp(existing));
      await _pumpBounded(tester);

      await _scrollToKey(tester, const Key('deleteTransactionButton'));
      await tester.tap(find.byKey(const Key('deleteTransactionButton')));
      await _pumpBounded(tester);
      await tester.tap(find.widgetWithText(TextButton, 'ลบ'));
      await _pumpBounded(tester);

      expect(fakeTransactions.deleteCalls, [existing.id]);
      expect(find.text('Could not delete transaction'), findsOneWidget);
      expect(cacheInvalidator.invalidatedMonthSets, isEmpty);
    });

    testWidgets('a transient delete failure gets queued and shows the retry-queue snackbar', (tester) async {
      fakeTransactions.deleteResult = const Left(TimeoutFailure());
      await tester.pumpWidget(buildEditApp(existing));
      await _pumpBounded(tester);

      await _scrollToKey(tester, const Key('deleteTransactionButton'));
      await tester.tap(find.byKey(const Key('deleteTransactionButton')));
      await _pumpBounded(tester);
      await tester.tap(find.widgetWithText(TextButton, 'ลบ'));
      await _pumpBounded(tester);

      expect(find.text('ไม่มีการเชื่อมต่อ — บันทึกไว้ในคิวลองใหม่แล้ว'), findsOneWidget);
      final queued = await pendingActions.watchAll().first;
      expect(queued, hasLength(1));
      expect(queued.single.actionType, PendingActionType.deleteTransaction);
      expect(queued.single.targetTransactionId, existing.id);
    });

    testWidgets('a permanent delete failure is not queued — snackbar only', (tester) async {
      fakeTransactions.deleteResult = const Left(UnknownFailure(message: 'Could not delete transaction'));
      await tester.pumpWidget(buildEditApp(existing));
      await _pumpBounded(tester);

      await _scrollToKey(tester, const Key('deleteTransactionButton'));
      await tester.tap(find.byKey(const Key('deleteTransactionButton')));
      await _pumpBounded(tester);
      await tester.tap(find.widgetWithText(TextButton, 'ลบ'));
      await _pumpBounded(tester);

      expect(find.text('Could not delete transaction'), findsOneWidget);
      expect(await pendingActions.watchAll().first, isEmpty);
    });
  });

  group('slip image preview (ticket 05)', () {
    testWidgets('no localImageName shows the placeholder immediately with no gallery query attempted', (tester) async {
      final noSlip = Transaction(
        id: 1,
        amount: 100,
        type: TransactionType.expense,
        source: 'manual',
        transactionDate: DateTime.utc(2026, 9, 5),
      );

      await tester.pumpWidget(buildEditApp(noSlip));
      await _pumpBounded(tester);
      await _scrollToKey(tester, const Key('slipInfoCard'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('slipImagePlaceholder')), findsOneWidget);
      expect(fakeSlipGallery.queryCalls, 0);
    });

    testWidgets('a matching filename in a configured album renders the slip image', (tester) async {
      fakeSlipGallery.candidates = const [SlipCandidate(id: 'asset-1', filename: 'scb_001.jpg', sourceAlbum: 'SCB EASY')];
      fakeSlipGallery.bytesById['asset-1'] = _fakeSlipImageBytes;
      final withSlip = Transaction(
        id: 2,
        amount: 100,
        type: TransactionType.expense,
        source: 'auto_scan',
        localImageName: 'scb_001.jpg',
        transactionDate: DateTime.utc(2026, 9, 5),
      );

      await tester.pumpWidget(buildEditApp(withSlip));
      await _pumpBounded(tester);
      await _scrollToKey(tester, const Key('slipInfoCard'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('slipImagePlaceholder')), findsNothing);
      expect(find.byType(Image), findsOneWidget);
      expect(fakeSlipGallery.queryCalls, 1);
    });

    testWidgets('a filename with no matching gallery candidate falls back to the placeholder, not an error', (tester) async {
      fakeSlipGallery.candidates = const [SlipCandidate(id: 'asset-1', filename: 'scb_999.jpg', sourceAlbum: 'SCB EASY')];
      final withStaleSlip = Transaction(
        id: 3,
        amount: 100,
        type: TransactionType.expense,
        source: 'auto_scan',
        localImageName: 'scb_001.jpg',
        transactionDate: DateTime.utc(2026, 9, 5),
      );

      await tester.pumpWidget(buildEditApp(withStaleSlip));
      await _pumpBounded(tester);
      await _scrollToKey(tester, const Key('slipInfoCard'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('slipImagePlaceholder')), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('a matching filename whose asset was deleted (readBytes returns null) falls back to the placeholder', (tester) async {
      fakeSlipGallery.candidates = const [SlipCandidate(id: 'asset-1', filename: 'scb_001.jpg', sourceAlbum: 'SCB EASY')];
      // bytesById intentionally left without an entry for 'asset-1' — the
      // fake's readBytes returns null for unknown ids, mirroring the real
      // repository's null-on-deleted-asset contract.
      final withDeletedAsset = Transaction(
        id: 4,
        amount: 100,
        type: TransactionType.expense,
        source: 'auto_scan',
        localImageName: 'scb_001.jpg',
        transactionDate: DateTime.utc(2026, 9, 5),
      );

      await tester.pumpWidget(buildEditApp(withDeletedAsset));
      await _pumpBounded(tester);
      await _scrollToKey(tester, const Key('slipInfoCard'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('slipImagePlaceholder')), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });
  });

  group('Topbar trailing action (ticket 04)', () {
    final existing = Transaction(
      id: 7,
      amount: 500,
      type: TransactionType.expense,
      source: 'manual',
      transactionDate: DateTime.utc(2026, 9, 5),
    );

    testWidgets('edit mode shows a delete (trash) icon, not the old overflow ("...") button', (tester) async {
      await tester.pumpWidget(buildEditApp(existing));
      await _pumpBounded(tester);

      // Visible immediately, with no scrolling — it lives in the fixed
      // header, not the scrollable form body.
      expect(find.byIcon(RemixIcon.deleteBinLine), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz), findsNothing);
      expect(find.byKey(const Key('deleteTransactionButton')), findsOneWidget);
    });
  });

  group('"ข้อมูลจากสลิป" position (ticket 04)', () {
    testWidgets('the slip info card is the last item in the form, below the submit button', (tester) async {
      final existing = Transaction(
        id: 8,
        amount: 100,
        type: TransactionType.expense,
        source: 'manual',
        transactionDate: DateTime.utc(2026, 9, 5),
      );

      await tester.pumpWidget(buildEditApp(existing));
      await _pumpBounded(tester);
      await _scrollToKey(tester, const Key('slipInfoCard'));

      final submitTop = tester.getTopLeft(find.byKey(const Key('submitButton'))).dy;
      final slipCardTop = tester.getTopLeft(find.byKey(const Key('slipInfoCard'))).dy;
      expect(submitTop, lessThan(slipCardTop));
    });
  });

  group('full-screen slip viewer (ticket 04)', () {
    testWidgets('tapping the thumbnail opens a full-screen pinch-zoom viewer with a close button', (tester) async {
      fakeSlipGallery.candidates = const [SlipCandidate(id: 'asset-1', filename: 'scb_001.jpg', sourceAlbum: 'SCB EASY')];
      fakeSlipGallery.bytesById['asset-1'] = _fakeSlipImageBytes;
      final withSlip = Transaction(
        id: 9,
        amount: 100,
        type: TransactionType.expense,
        source: 'auto_scan',
        localImageName: 'scb_001.jpg',
        transactionDate: DateTime.utc(2026, 9, 5),
      );

      await tester.pumpWidget(buildEditApp(withSlip));
      await _pumpBounded(tester);
      await _scrollToKey(tester, const Key('slipInfoCard'));

      await tester.tap(find.byKey(const Key('slipThumbnailTapTarget')));
      await _pumpBounded(tester);

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byKey(const Key('closeFullScreenSlipViewer')), findsOneWidget);
    });

    testWidgets('closing the viewer returns to the form with previously-entered data intact', (tester) async {
      fakeSlipGallery.candidates = const [SlipCandidate(id: 'asset-1', filename: 'scb_001.jpg', sourceAlbum: 'SCB EASY')];
      fakeSlipGallery.bytesById['asset-1'] = _fakeSlipImageBytes;
      final withSlip = Transaction(
        id: 10,
        amount: 100,
        type: TransactionType.expense,
        source: 'auto_scan',
        localImageName: 'scb_001.jpg',
        transactionDate: DateTime.utc(2026, 9, 5),
      );

      await tester.pumpWidget(buildEditApp(withSlip));
      await _pumpBounded(tester);

      // Type into the note field before opening the viewer — this is the
      // "data I've filled in" the close button must not lose (spec: closing
      // returns to the form with unsaved input intact).
      await tester.enterText(find.byKey(const Key('noteField')), 'note before opening viewer');
      await _pumpBounded(tester);

      await _scrollToKey(tester, const Key('slipInfoCard'));
      await tester.tap(find.byKey(const Key('slipThumbnailTapTarget')));
      await _pumpBounded(tester);
      expect(find.byKey(const Key('closeFullScreenSlipViewer')), findsOneWidget);

      await tester.tap(find.byKey(const Key('closeFullScreenSlipViewer')));
      await _pumpBounded(tester);

      // The overlay is gone and the same TransactionFormPage instance (with
      // its typed note still intact) is what's left — not a fresh page.
      expect(find.byKey(const Key('closeFullScreenSlipViewer')), findsNothing);
      expect(find.byType(TransactionFormPage), findsOneWidget);
      expect(find.text('note before opening viewer'), findsOneWidget);
    });

    testWidgets('the placeholder (no resolved image) is not tappable — nothing to view yet', (tester) async {
      final noSlip = Transaction(
        id: 11,
        amount: 100,
        type: TransactionType.expense,
        source: 'manual',
        transactionDate: DateTime.utc(2026, 9, 5),
      );

      await tester.pumpWidget(buildEditApp(noSlip));
      await _pumpBounded(tester);
      await _scrollToKey(tester, const Key('slipInfoCard'));

      expect(find.byKey(const Key('slipThumbnailTapTarget')), findsNothing);
      await tester.tap(find.byKey(const Key('slipImagePlaceholder')));
      await _pumpBounded(tester);

      expect(find.byKey(const Key('closeFullScreenSlipViewer')), findsNothing);
    });
  });
}

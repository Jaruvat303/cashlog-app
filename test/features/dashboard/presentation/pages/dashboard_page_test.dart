// Before any pumpWidget/pumpAndSettle, every repository this page touches is
// overridden with a hand-written fake (same pattern as _FakeAccountsRepository
// in test/widget_test.dart) — this is what keeps a real dio call or a real
// photo_manager platform-channel call from ever happening in this test
// environment.
import 'dart:async';
import 'dart:typed_data';

import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/accounts/data/accounts_repository.dart';
import 'package:cashlog/features/accounts/domain/account.dart';
import 'package:cashlog/features/categories/data/categories_repository.dart';
import 'package:cashlog/features/categories/domain/category.dart';
import 'package:cashlog/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:cashlog/features/slip_scan/data/slip_gallery_repository.dart';
import 'package:cashlog/features/slip_scan/domain/gallery_access_level.dart';
import 'package:cashlog/features/slip_scan/domain/slip_candidate.dart';
import 'package:cashlog/features/slip_scan/presentation/providers/slip_scan_pipeline_provider.dart';
import 'package:cashlog/features/transactions/data/pending_actions_repository.dart';
import 'package:cashlog/features/transactions/data/transactions_repository.dart';
import 'package:cashlog/features/transactions/domain/pending_action.dart';
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:cashlog/features/transactions/domain/transaction_page.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

class _FakeTransactionsRepository implements TransactionsRepository {
  _FakeTransactionsRepository(this.transactions);

  final List<Transaction> transactions;

  @override
  Stream<List<Transaction>> watchMonth({required int year, required int month, int? categoryId}) => Stream.value(transactions);
  @override
  Future<Either<Failure, TransactionPage>> fetchPage({required int year, required int month, required int page, int limit = 20}) =>
      throw UnimplementedError('not exercised by this page test');
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
/// here because `TransactionListTile` (rendered by the attention feed) reads
/// `pendingActionsProvider`, which is otherwise backed by a real drift db.
class _FakePendingActionsRepository implements PendingActionsRepository {
  final List<PendingAction> _items = [];
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
  }) => throw UnimplementedError('not exercised by this page test');

  @override
  Future<void> recordRetryFailure(int id, String? errorCode) => throw UnimplementedError('not exercised by this page test');

  @override
  Future<void> remove(int id) => throw UnimplementedError('not exercised by this page test');
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

Transaction _tx({
  required int id,
  TransactionType type = TransactionType.expense,
  int? categoryId,
  bool isJunk = false,
  DateTime? date,
}) => Transaction(
  id: id,
  amount: isJunk ? 0 : 100,
  type: type,
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
  Widget buildApp({
    required SlipScanProgress pipelineState,
    required _FakeSlipGalleryRepository galleryRepo,
    List<Transaction> transactions = const [],
    List<Account> accounts = const [],
  }) => ProviderScope(
        overrides: [
          accountsRepositoryProvider.overrideWithValue(_FakeAccountsRepository(accounts: accounts)),
          categoriesRepositoryProvider.overrideWithValue(_FakeCategoriesRepository()),
          transactionsRepositoryProvider.overrideWithValue(_FakeTransactionsRepository(transactions)),
          pendingActionsRepositoryProvider.overrideWithValue(_FakePendingActionsRepository()),
          slipGalleryRepositoryProvider.overrideWithValue(galleryRepo),
          slipScanPipelineProvider.overrideWith(() => _FakeSlipScanPipeline(pipelineState)),
        ],
        child: const MaterialApp(home: DashboardPage()),
      );

  testWidgets('full access shows no permission banner', (tester) async {
    await tester.pumpWidget(
      buildApp(pipelineState: _progress(accessLevel: GalleryAccessLevel.full), galleryRepo: _FakeSlipGalleryRepository()),
    );
    await _pumpBounded(tester);

    expect(find.byKey(const Key('galleryPermissionBanner')), findsNothing);
  });

  testWidgets('no scan attempted yet (null accessLevel) shows no permission banner', (tester) async {
    await tester.pumpWidget(buildApp(pipelineState: _progress(), galleryRepo: _FakeSlipGalleryRepository()));
    await _pumpBounded(tester);

    expect(find.byKey(const Key('galleryPermissionBanner')), findsNothing);
  });

  testWidgets('denied access shows a banner whose button triggers requestAccess', (tester) async {
    final galleryRepo = _FakeSlipGalleryRepository();
    await tester.pumpWidget(
      buildApp(pipelineState: _progress(accessLevel: GalleryAccessLevel.denied), galleryRepo: galleryRepo),
    );
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
    await tester.pumpWidget(
      buildApp(pipelineState: _progress(accessLevel: GalleryAccessLevel.limited), galleryRepo: galleryRepo),
    );
    await _pumpBounded(tester);

    expect(find.byKey(const Key('galleryPermissionBanner')), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'เลือกรูปเพิ่มเติม'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'เลือกรูปเพิ่มเติม'));
    await _pumpBounded(tester);

    expect(galleryRepo.presentLimitedSelectionCalls, 1);
    expect(galleryRepo.requestAccessCalls, 0);
  });

  testWidgets('shows an empty-state message when nothing needs attention', (tester) async {
    await tester.pumpWidget(
      buildApp(
        pipelineState: _progress(accessLevel: GalleryAccessLevel.full),
        galleryRepo: _FakeSlipGalleryRepository(),
        transactions: [_tx(id: 1, categoryId: 7)],
      ),
    );
    await _pumpBounded(tester);

    expect(find.text('ไม่มีรายการที่ต้องดำเนินการ'), findsOneWidget);
  });

  testWidgets('attention feed lists junk and uncategorized income/expense rows, most recent first, '
      'excluding categorized rows and category-less transfers', (tester) async {
    final categorized = _tx(id: 1, categoryId: 7, date: DateTime.utc(2026, 9, 10));
    final uncategorized = _tx(id: 2, date: DateTime.utc(2026, 9, 5));
    final junk = _tx(id: 3, isJunk: true, date: DateTime.utc(2026, 9, 12));
    final transfer = _tx(id: 4, type: TransactionType.transfer, date: DateTime.utc(2026, 9, 20));

    await tester.pumpWidget(
      buildApp(
        pipelineState: _progress(accessLevel: GalleryAccessLevel.full),
        galleryRepo: _FakeSlipGalleryRepository(),
        transactions: [categorized, uncategorized, junk, transfer],
      ),
    );
    await _pumpBounded(tester);

    expect(find.text('ไม่มีรายการที่ต้องดำเนินการ'), findsNothing);
    expect(find.byType(Divider), findsOneWidget); // exactly 2 rows -> 1 divider between them

    final tileFinder = find.byKey(const Key('transactionRowTapTarget'));
    expect(tileFinder, findsNWidgets(2));
  });

  testWidgets('ticket 04: the account-info strip no longer renders here — it moved to the summary page', (tester) async {
    const account = Account(
      id: 1,
      name: 'Main Wallet',
      accountType: AccountType.bank,
      openingBalance: 0,
      matchingKeywords: [],
      bankIcon: 'scb',
      isActive: true,
    );

    await tester.pumpWidget(
      buildApp(pipelineState: _progress(accessLevel: GalleryAccessLevel.full), galleryRepo: _FakeSlipGalleryRepository(), accounts: const [account]),
    );
    await _pumpBounded(tester);

    expect(find.byKey(const Key('accountInfoStrip')), findsNothing);
    expect(find.text('Main Wallet'), findsNothing);
  });
}

// T3 nav shell smoke test: all 4 tabs are reachable without crashing, plus
// (moved here from transactions_page_test.dart when T21's manual-attach
// button became the AppShell's raised camera FAB per the mockup redesign,
// reachable from every tab rather than only the Transactions page) the
// manual slip-attach flow.
//
// AccountsPage (T4) is a real page now, not a placeholder, so this test
// fakes AccountsRepository out entirely rather than letting it hit dio for
// real: Flutter's built-in "every HTTP request comes back 400" test stub is
// not a controlled fake response, it's a genuine round-trip through the
// real client/retry stack with unspecified timing — not something this
// nav-shell test should depend on.
import 'dart:async';
import 'dart:typed_data';

import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/accounts/data/accounts_repository.dart';
import 'package:cashlog/features/accounts/domain/account.dart';
import 'package:cashlog/features/accounts/presentation/pages/accounts_page.dart';
import 'package:cashlog/features/categories/data/categories_repository.dart';
import 'package:cashlog/features/categories/domain/category.dart';
import 'package:cashlog/features/categories/presentation/pages/categories_page.dart';
import 'package:cashlog/features/dashboard/data/dashboard_repository.dart';
import 'package:cashlog/features/dashboard/domain/dashboard_summary.dart';
import 'package:cashlog/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:cashlog/features/slip_scan/data/slip_gallery_repository.dart';
import 'package:cashlog/features/slip_scan/data/slip_upload_repository.dart';
import 'package:cashlog/features/slip_scan/domain/gallery_access_level.dart';
import 'package:cashlog/features/slip_scan/domain/slip_candidate.dart';
import 'package:cashlog/features/slip_scan/domain/slip_upload_outcome.dart';
import 'package:cashlog/features/slip_scan/presentation/widgets/manual_slip_attach_button.dart';
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

import 'package:cashlog/main.dart';

/// Canned, instant results — no ApiClient, no AppDatabase, nothing async
/// for the test to ever get stuck waiting on.
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
  }) => throw UnimplementedError('not exercised by the nav-shell smoke test');

  @override
  Future<Either<Failure, Account>> update(
    int id, {
    required String name,
    required AccountType accountType,
    required List<String> matchingKeywords,
    required String bankIcon,
  }) => throw UnimplementedError('not exercised by the nav-shell smoke test');

  @override
  Future<Either<Failure, void>> close(int id) => throw UnimplementedError('not exercised by the nav-shell smoke test');
}

/// T5 replaced the Categories placeholder with a real page — same reasoning
/// as [_FakeAccountsRepository]: fake the repository entirely so this
/// nav-shell test never lets a real dio call hit Flutter's test HTTP stub.
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
  }) => throw UnimplementedError('not exercised by the nav-shell smoke test');

  @override
  Future<Either<Failure, Category>> update(
    int id, {
    required String name,
    required CategoryType type,
    required String iconKey,
    required String colorHex,
  }) => throw UnimplementedError('not exercised by the nav-shell smoke test');

  @override
  Future<int> countLinkedTransactions(int categoryId) => throw UnimplementedError('not exercised by the nav-shell smoke test');

  @override
  Future<Either<Failure, void>> delete(int id) => throw UnimplementedError('not exercised by the nav-shell smoke test');
}

/// T7 replaced the Transactions placeholder with a real page — same
/// reasoning as [_FakeAccountsRepository]: fake the repository entirely so
/// this nav-shell test never lets a real dio call hit Flutter's test HTTP
/// stub (the feed's initState kicks off a page-1 fetch as soon as the tab
/// mounts).
class _FakeTransactionsRepository implements TransactionsRepository {
  @override
  Stream<List<Transaction>> watchMonth({required int year, required int month, int? categoryId}) => Stream.value(const []);

  @override
  Future<Either<Failure, TransactionPage>> fetchPage({required int year, required int month, required int page, int limit = 20}) async =>
      const Right(TransactionPage(transactions: [], currentPage: 1, totalPages: 1));

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
  }) => throw UnimplementedError('not exercised by the nav-shell smoke test');

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
  }) => throw UnimplementedError('not exercised by the nav-shell smoke test');

  @override
  Future<Either<Failure, void>> delete(int id) => throw UnimplementedError('not exercised by the nav-shell smoke test');
}

/// T8 replaced the Dashboard placeholder with a real page — same reasoning
/// as [_FakeAccountsRepository]: fake the repository entirely so this
/// nav-shell test never lets a real dio call hit Flutter's test HTTP stub
/// (the page's build kicks off a summary fetch as soon as it mounts).
class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<Either<Failure, DashboardSummary>> fetchSummary({required int year, required int month}) async => Right(
    DashboardSummary(totalIncome: 0, totalExpense: 0, totalTransfer: 0, year: year, month: month, income: const [], expense: const []),
  );
}

/// T13 replaced the Transactions placeholder's AppBar with a stuck-items
/// badge — fake the repository entirely (empty queue, always) rather than a
/// real drift-backed instance: a real one inside a testWidgets test hits a
/// known drift/flutter_test interaction (cancelling a live `.watch()`
/// stream during widget-tree disposal schedules a zero-duration Timer that
/// never fires before the test framework's post-test check, see
/// https://github.com/simolus3/drift/issues/3323 — confirmed during T13
/// verification).
class _FakePendingActionsRepository implements PendingActionsRepository {
  @override
  Stream<List<PendingAction>> watchAll() => Stream.value(const []);

  @override
  Future<bool> recordIfTransient({
    required Failure failure,
    required PendingActionType actionType,
    required Map<String, dynamic> payload,
    int? targetTransactionId,
  }) => throw UnimplementedError('not exercised by the nav-shell smoke test');

  @override
  Future<void> recordRetryFailure(int id, String? errorCode) => throw UnimplementedError('not exercised by the nav-shell smoke test');

  @override
  Future<void> remove(int id) => throw UnimplementedError('not exercised by the nav-shell smoke test');
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
/// never exercised by this nav-shell test (that's the auto-scan pipeline's
/// own test suite).
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
  Future<List<SlipCandidate>> diffNewFiles(List<SlipCandidate> candidates) => throw UnimplementedError('not exercised by this nav-shell test');

  @override
  Future<Either<Failure, SlipUploadOutcome>> uploadOne(SlipCandidate candidate) => throw UnimplementedError('not exercised by this nav-shell test');
}

/// This test pumps the real `MyApp()` (needed since `AppShell` — home of
/// T21's FAB — only exists inside go_router's shell route, unlike the old
/// per-page test that pumped `TransactionsPage` directly) — which means
/// `main.dart`'s real `slipScanLifecycleProvider` cold-start trigger also
/// runs for real. Faking gallery access as permanently `denied` makes that
/// trigger a safe no-op (same fake shape as main_test.dart's own
/// lifecycle-wiring tests), so it can never race the manual-upload path
/// this suite is actually testing.
class _FakeSlipGalleryRepository implements SlipGalleryRepository {
  @override
  Future<GalleryAccessLevel> currentAccess() async => GalleryAccessLevel.denied;
  @override
  Future<GalleryAccessLevel> requestAccess() => throw UnimplementedError('not exercised by this nav-shell test');
  @override
  Future<void> presentLimitedSelection() => throw UnimplementedError('not exercised by this nav-shell test');
  @override
  Future<void> openSettings() => throw UnimplementedError('not exercised by this nav-shell test');
  @override
  Future<List<SlipCandidate>> queryConfiguredAlbums() =>
      throw UnimplementedError('access is always denied in this test, so runScan() should short-circuit before ever reaching this');
  @override
  Future<Uint8List?> readBytes(String assetId) => throw UnimplementedError('not exercised by this nav-shell test');
}

Transaction _expense(int id, String note, DateTime date) =>
    Transaction(id: id, amount: 100, type: TransactionType.expense, note: note, source: 'manual', transactionDate: date);

/// pumpAndSettle can't tell "still legitimately loading" from "stuck
/// forever" — it just keeps pumping until nothing's scheduled, up to its
/// own 10-minute default timeout. A bounded pump loop fails fast instead of
/// hanging for the length of that default.
Future<void> _pumpBounded(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late _FakeManualSlipImageSource manualImageSource;
  late _FakeSlipUploadRepository manualSlipUploadRepository;

  setUp(() {
    manualImageSource = _FakeManualSlipImageSource();
    manualSlipUploadRepository = _FakeSlipUploadRepository();
  });

  Widget buildApp() => ProviderScope(
    overrides: [
      accountsRepositoryProvider.overrideWithValue(_FakeAccountsRepository()),
      categoriesRepositoryProvider.overrideWithValue(_FakeCategoriesRepository()),
      transactionsRepositoryProvider.overrideWithValue(_FakeTransactionsRepository()),
      dashboardRepositoryProvider.overrideWithValue(_FakeDashboardRepository()),
      // T13: TransactionsPage now watches this for its stuck-items badge
      // as soon as it's built (IndexedStack builds every tab up front,
      // not just the one currently selected).
      pendingActionsRepositoryProvider.overrideWithValue(_FakePendingActionsRepository()),
      slipGalleryRepositoryProvider.overrideWithValue(_FakeSlipGalleryRepository()),
      manualSlipImageSourceProvider.overrideWithValue(manualImageSource),
      slipUploadRepositoryProvider.overrideWithValue(manualSlipUploadRepository),
    ],
    child: const MyApp(),
  );

  testWidgets('switches between all 4 bottom nav tabs', (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);

    // T8 replaced the placeholder with the real dashboard feature — just
    // confirm the tab itself is reachable, per this smoke test's scope.
    expect(find.byType(DashboardPage), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'รายการ'));
    await _pumpBounded(tester);
    // T7 replaced the placeholder with the real transaction feed — just
    // confirm the tab itself is reachable, per this smoke test's scope.
    expect(find.byType(TransactionsPage), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'บัญชี'));
    await _pumpBounded(tester);
    // T4 replaced the placeholder with the real accounts feature — just
    // confirm the tab itself is reachable, per this smoke test's scope.
    expect(find.byType(AccountsPage), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'เพิ่มเติม'));
    await _pumpBounded(tester);
    // T5 replaced the placeholder with the real categories feature — just
    // confirm the tab itself is reachable, per this smoke test's scope.
    expect(find.byType(CategoriesPage), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'หน้าแรก'));
    await _pumpBounded(tester);
    expect(find.byType(DashboardPage), findsOneWidget);
  });

  group('T21 manual slip attach FAB (AppShell)', () {
    testWidgets('is present on every tab and opens a camera/gallery chooser on tap', (tester) async {
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
      expect(find.text('อัปโหลดสลิปแล้ว'), findsOneWidget);
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
      final button = tester.widget<FloatingActionButton>(find.byKey(const Key('manualSlipAttachButton')));
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

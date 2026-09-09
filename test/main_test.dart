// T11: verifies the app-root wiring between AppLifecycleState transitions
// and SlipScanPipeline.runScan(), including that the wiring genuinely
// respects T10's re-entrancy guard end-to-end (not just "was runScan()
// called"). This uses the REAL SlipScanPipeline — only its dependency
// (SlipGalleryRepository) is faked — specifically so T10's actual guard
// code runs for real: an earlier version of this file overrode
// slipScanPipelineProvider itself with a spy whose runScan() never touched
// `state`, which meant the guard it's supposed to be testing never
// actually ran, and it silently missed a real production bug (see below).
// No photo_manager platform channel, no real network, per CLAUDE.md's
// testing rule — GalleryAccessLevel.denied is used throughout so the
// pipeline short-circuits before ever needing SlipUploadRepository.
//
// tester.binding.handleAppLifecycleStateChanged(...) genuinely drives the
// same WidgetsBindingObserver.didChangeAppLifecycleState callback path a
// real backgrounding event would — this is what makes a widget test
// sufficient for this ticket's DoD instead of requiring a real device.
//
// Same "fake every repository MyApp's tree touches" reasoning as
// widget_test.dart (T3's nav-shell smoke test) — MyApp's initState also
// kicks off appStartupProvider (accounts+categories refresh), and the first
// tab's build touches the dashboard summary, so all of those need faking
// here too, not just the gallery repository, to keep this a pure
// lifecycle-wiring test rather than a re-run of every other feature's own
// tests.
import 'dart:async';
import 'dart:typed_data';

import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/accounts/data/accounts_repository.dart';
import 'package:cashlog/features/accounts/domain/account.dart';
import 'package:cashlog/features/categories/data/categories_repository.dart';
import 'package:cashlog/features/categories/domain/category.dart';
import 'package:cashlog/features/dashboard/data/dashboard_repository.dart';
import 'package:cashlog/features/dashboard/domain/dashboard_summary.dart';
import 'package:cashlog/features/slip_scan/data/slip_gallery_repository.dart';
import 'package:cashlog/features/slip_scan/domain/gallery_access_level.dart';
import 'package:cashlog/features/slip_scan/domain/slip_candidate.dart';
import 'package:cashlog/features/slip_scan/presentation/providers/slip_scan_pipeline_provider.dart';
import 'package:cashlog/features/transactions/data/transactions_repository.dart';
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:cashlog/features/transactions/domain/transaction_page.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cashlog/main.dart';

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
  }) => throw UnimplementedError('not exercised by the lifecycle-wiring test');
  @override
  Future<Either<Failure, Account>> update(
    int id, {
    required String name,
    required AccountType accountType,
    required List<String> matchingKeywords,
    required String bankIcon,
  }) => throw UnimplementedError('not exercised by the lifecycle-wiring test');
  @override
  Future<Either<Failure, void>> close(int id) => throw UnimplementedError('not exercised by the lifecycle-wiring test');
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
  }) => throw UnimplementedError('not exercised by the lifecycle-wiring test');
  @override
  Future<Either<Failure, Category>> update(
    int id, {
    required String name,
    required CategoryType type,
    required String iconKey,
    required String colorHex,
  }) => throw UnimplementedError('not exercised by the lifecycle-wiring test');
  @override
  Future<int> countLinkedTransactions(int categoryId) => throw UnimplementedError('not exercised by the lifecycle-wiring test');
  @override
  Future<Either<Failure, void>> delete(int id) => throw UnimplementedError('not exercised by the lifecycle-wiring test');
}

class _FakeTransactionsRepository implements TransactionsRepository {
  @override
  Stream<List<Transaction>> watchMonth({required int year, required int month}) => Stream.value(const []);
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
  }) => throw UnimplementedError('not exercised by the lifecycle-wiring test');
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
  }) => throw UnimplementedError('not exercised by the lifecycle-wiring test');
}

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<Either<Failure, DashboardSummary>> fetchSummary({required int year, required int month}) async => Right(
    DashboardSummary(totalIncome: 0, totalExpense: 0, totalTransfer: 0, year: year, month: month, income: const [], expense: const []),
  );
}

/// [currentAccess] is the first thing the real `SlipScanPipeline.runScan()`
/// awaits after its synchronous guard check/claim — so counting calls to it
/// counts exactly "how many times a `runScan()` call got past the guard and
/// actually started a scan attempt", which is the signal every test below
/// needs. [pendingAccess], when set, holds that call open indefinitely (via
/// a `Completer`) so a test can simulate "a scan is still mid-flight" and
/// probe whether a second trigger gets deduplicated — `denied` is otherwise
/// returned immediately, which is enough to make `runScan()` short-circuit
/// cleanly without ever needing `SlipUploadRepository`.
class _FakeSlipGalleryRepository implements SlipGalleryRepository {
  int currentAccessCalls = 0;
  Completer<GalleryAccessLevel>? pendingAccess;

  @override
  Future<GalleryAccessLevel> currentAccess() {
    currentAccessCalls++;
    final pending = pendingAccess;
    return pending != null ? pending.future : Future.value(GalleryAccessLevel.denied);
  }

  @override
  Future<GalleryAccessLevel> requestAccess() => throw UnimplementedError('not exercised by the lifecycle-wiring test');
  @override
  Future<void> presentLimitedSelection() => throw UnimplementedError('not exercised by the lifecycle-wiring test');
  @override
  Future<void> openSettings() => throw UnimplementedError('not exercised by the lifecycle-wiring test');
  @override
  Future<List<SlipCandidate>> queryConfiguredAlbums() =>
      throw UnimplementedError('access is always denied in this test, so runScan() should short-circuit before ever reaching this');
  @override
  Future<Uint8List?> readBytes(String assetId) => throw UnimplementedError('not exercised by the lifecycle-wiring test');
}

Future<void> _pumpBounded(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late _FakeSlipGalleryRepository galleryRepository;

  Widget buildApp() => ProviderScope(
    overrides: [
      accountsRepositoryProvider.overrideWithValue(_FakeAccountsRepository()),
      categoriesRepositoryProvider.overrideWithValue(_FakeCategoriesRepository()),
      transactionsRepositoryProvider.overrideWithValue(_FakeTransactionsRepository()),
      dashboardRepositoryProvider.overrideWithValue(_FakeDashboardRepository()),
      slipGalleryRepositoryProvider.overrideWithValue(galleryRepository),
    ],
    child: const MyApp(),
  );

  setUp(() {
    galleryRepository = _FakeSlipGalleryRepository();
  });

  testWidgets('cold start triggers a scan', (tester) async {
    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);

    expect(galleryRepository.currentAccessCalls, greaterThanOrEqualTo(1));
  });

  testWidgets('backgrounding then resuming triggers exactly one more scan', (tester) async {
    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);
    final afterColdStart = galleryRepository.currentAccessCalls;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await _pumpBounded(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _pumpBounded(tester);

    // Exactly +1, not "some positive amount": the cold-start scan and this
    // resumed transition are two fully-settled, independent triggers (the
    // first has long finished by the time the second fires), so both
    // should genuinely proceed past the guard once each — no more, no
    // fewer. A loose "greaterThan" here wouldn't catch T10's re-entrancy
    // guard silently breaking in a way that let extra scans through.
    expect(galleryRepository.currentAccessCalls, afterColdStart + 1);
  });

  testWidgets('pausing/inactive/detached alone never trigger a scan — only resumed does', (tester) async {
    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);
    final afterColdStart = galleryRepository.currentAccessCalls;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await _pumpBounded(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await _pumpBounded(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.detached);
    await _pumpBounded(tester);

    expect(galleryRepository.currentAccessCalls, afterColdStart, reason: 'only AppLifecycleState.resumed should trigger a scan');
  });

  testWidgets('unmounting removes the lifecycle observer — no further calls after dispose', (tester) async {
    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);
    final afterColdStart = galleryRepository.currentAccessCalls;

    // Replace the whole tree (same effect as MyApp being disposed).
    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpBounded(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _pumpBounded(tester);

    expect(
      galleryRepository.currentAccessCalls,
      afterColdStart,
      reason: 'the observer should have been removed on dispose, so this resumed event has no listener left to react to it',
    );
  });

  testWidgets('a resume firing while a scan is still mid-flight is deduplicated by T10\'s guard, not run concurrently', (tester) async {
    final pending = Completer<GalleryAccessLevel>();
    galleryRepository.pendingAccess = pending;

    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);
    // Cold start's scan should have reached currentAccess() exactly once
    // and now be stuck there, awaiting `pending` — i.e. genuinely mid-flight
    // (isScanning still true on the real SlipScanPipeline), not settled.
    expect(galleryRepository.currentAccessCalls, 1, reason: 'cold start should be stuck mid-scan at this point');

    // Rapid re-trigger while the first scan is still in flight — this is
    // exactly the scenario T10's re-entrancy guard exists for.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await _pumpBounded(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _pumpBounded(tester);

    expect(
      galleryRepository.currentAccessCalls,
      1,
      reason: 'a resume firing mid-scan must be rejected by the guard before ever reaching currentAccess() again — if this is 2, T10\'s '
          'sequential-upload guarantee has been violated: two overlapping scans are now running concurrently',
    );

    // Let the first (and only) scan finish, then confirm a later resume,
    // now that nothing is in flight, proceeds normally.
    pending.complete(GalleryAccessLevel.denied);
    await _pumpBounded(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await _pumpBounded(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _pumpBounded(tester);

    expect(galleryRepository.currentAccessCalls, 2, reason: 'once the first scan has finished, a fresh resume should proceed normally');
  });

  testWidgets('a manual trigger firing while a lifecycle-triggered scan is mid-flight does not double-fire either', (tester) async {
    // T9/T10's debug page keeps its own manual "Scan & Upload" button
    // alongside the automatic triggers (T11's own choice, flagged at the
    // time) — its onPressed handler is exactly
    // `ref.read(slipScanPipelineProvider.notifier).runScan`, the same
    // method and the same guard as every trigger above, so calling it
    // directly here (rather than navigating to and tapping the actual
    // button) exercises the identical code path a real tap would. The
    // button is additionally disabled in the UI while `isScanning` is true
    // (`onPressed: progress.isScanning ? null : onScan` in
    // slip_gallery_debug_page.dart) — a second, UI-level line of defense on
    // top of the guard this test targets, not exercised here since this
    // test calls the notifier directly.
    final pending = Completer<GalleryAccessLevel>();
    galleryRepository.pendingAccess = pending;

    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);
    expect(galleryRepository.currentAccessCalls, 1, reason: 'cold start should be stuck mid-scan at this point');

    final element = tester.element(find.byType(MyApp));
    final container = ProviderScope.containerOf(element);
    await container.read(slipScanPipelineProvider.notifier).runScan();
    await _pumpBounded(tester);

    expect(
      galleryRepository.currentAccessCalls,
      1,
      reason: 'a manual trigger firing mid-scan must be rejected by the same guard — no double-fire alongside the automatic lifecycle trigger',
    );

    // Never leave a Completer permanently incomplete at test end — an
    // earlier version of this suite did exactly that and, combined with a
    // real production bug that defeated the guard, caused a genuine 10
    // minute test hang instead of a fast, clear failure.
    pending.complete(GalleryAccessLevel.denied);
    await _pumpBounded(tester);
  });
}

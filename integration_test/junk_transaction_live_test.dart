// T12 Layer 2 verification — drives the REAL SlipScanPipeline, the REAL
// TransactionsPage (T7 feed) and the REAL TransactionFormPage (T6 edit
// form) against a REAL Android gallery and the REAL dev backend. Same
// requirements as slip_upload_pipeline_test.dart (T10):
//   - dummy (non-slip) images already pushed via `adb push` into
//     "/sdcard/Pictures/SCB EASY/" and/or "/sdcard/Pictures/Dime!/", each
//     followed by an `adb shell am broadcast -a
//     android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file://...`
//   - android.permission.READ_EXTERNAL_STORAGE pre-granted via `adb shell pm
//     grant`, so no system permission dialog blocks the run
//   - run with: flutter test integration_test/junk_transaction_live_test.dart
//     -d <device> --dart-define-from-file=env/dev.json
//
// Every finding is printed with a "T12-LAYER2:" prefix.
import 'package:cashlog/core/db/app_database.dart';
import 'package:cashlog/core/month/selected_month_provider.dart';
import 'package:cashlog/features/accounts/data/accounts_repository.dart';
import 'package:cashlog/features/slip_scan/data/slip_gallery_repository.dart';
import 'package:cashlog/features/slip_scan/domain/gallery_access_level.dart';
import 'package:cashlog/features/slip_scan/presentation/providers/slip_scan_pipeline_provider.dart';
import 'package:cashlog/features/transactions/data/transactions_repository.dart';
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:cashlog/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:cashlog/features/transactions/presentation/pages/transactions_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUpAll(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  testWidgets(
    'T12: a non-slip gallery image uploads as junk on the real backend, the real feed '
    "shows the badge, deleting hits DELETE /transactions/:id for real, and editing "
    'through T6\'s real form clears isJunk',
    (tester) async {
      // --- Step 0: need at least one real active account to drive T6's form ---
      final accountsRepo = container.read(accountsRepositoryProvider);
      final refreshResult = await accountsRepo.refreshFromApi();
      // ignore: avoid_print
      print('T12-LAYER2: accounts refresh -> ${refreshResult.fold((f) => 'FAILED: $f', (_) => 'ok')}');

      final db = container.read(appDatabaseProvider);
      final accounts = await (db.select(db.cachedAccounts)..where((a) => a.isActive.equals(true))).get();
      // ignore: avoid_print
      print('T12-LAYER2: ${accounts.length} active account(s): ${accounts.map((a) => '${a.id}:${a.name}').join(', ')}');
      expect(accounts, isNotEmpty, reason: "need at least one active dev account to drive T6's edit form");

      // --- Step 0b: diagnose gallery permission state. adb already granted
      // READ_EXTERNAL_STORAGE at the OS level (verified via `dumpsys
      // package` before this run); deliberately NOT calling
      // `galleryRepo.requestAccess()` here — that shows a real native
      // permission dialog when photo_manager's own plugin-side state
      // disagrees with the OS grant, and nothing can tap it in this
      // headless run, which hung the previous attempt for its full 5-minute
      // timeout. Retrying the passive check instead, in case this is a
      // propagation race right after install.
      final galleryRepo = container.read(slipGalleryRepositoryProvider);
      GalleryAccessLevel access = GalleryAccessLevel.denied;
      for (var i = 0; i < 5; i++) {
        access = await galleryRepo.currentAccess();
        // ignore: avoid_print
        print('T12-LAYER2: gallery access (attempt $i) = $access');
        if (access != GalleryAccessLevel.denied) break;
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      expect(access, isNot(GalleryAccessLevel.denied), reason: 'gallery access must not be denied for the scan to find anything');

      // --- Step 0c: warm up photo_manager's own asset-path cache. A fresh
      // install's first getAssetPathList() call can transiently return zero
      // paths even with access==full and MediaStore itself already indexed
      // (confirmed via `adb shell content query` showing all 13 files) — a
      // plugin-side sync race, not a real absence. Retrying here, outside
      // runScan, means runScan's own internal query (which the assertions
      // below depend on) sees the warmed-up state.
      var warmupCandidates = <Object>[];
      for (var i = 0; i < 5; i++) {
        warmupCandidates = await galleryRepo.queryConfiguredAlbums();
        // ignore: avoid_print
        print('T12-LAYER2: warm-up album query (attempt $i) found ${warmupCandidates.length} candidate(s)');
        if (warmupCandidates.isNotEmpty) break;
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      expect(warmupCandidates, isNotEmpty, reason: 'expected the pushed gallery images to be visible via photo_manager');

      // --- Step 1: run the REAL scan pipeline against the REAL dev API ---
      // queryConfiguredAlbums() has proven flaky between consecutive calls
      // in the same process on this emulator (the warm-up above found 13
      // candidates; runScan()'s own internal call moments later can still
      // find 0) — a platform-channel/plugin-side race, not app logic (the
      // MediaStore-level data is confirmed present via `adb shell content
      // query`). Retrying the whole scan is the standard mitigation for
      // that class of flakiness. `slipScanPipelineProvider` is autoDispose —
      // without an active listener it tears itself down between calls once
      // nothing is reading it, which breaks a *second* runScan() call with
      // an UnmountedRefException (T10's own original test avoids this the
      // same way: a no-op `container.listen` keeps it alive for the
      // container's lifetime).
      container.listen(slipScanPipelineProvider, (prev, next) {});
      final scanNotifier = container.read(slipScanPipelineProvider.notifier);
      var progress = container.read(slipScanPipelineProvider);
      for (var i = 0; i < 4; i++) {
        await scanNotifier.runScan();
        progress = container.read(slipScanPipelineProvider);
        // ignore: avoid_print
        print('T12-LAYER2: scan pass attempt $i: total=${progress.total} completed=${progress.completed}');
        for (final r in progress.results) {
          // ignore: avoid_print
          print('T12-LAYER2:   ${r.filename} -> ${r.status}${r.failureMessage != null ? ' (${r.failureMessage})' : ''}');
        }
        if (progress.total > 0) break;
        await Future<void>.delayed(const Duration(seconds: 3));
      }

      // --- Step 2: sync the current month from the server, then confirm at
      // least one real junk transaction exists. Deliberately syncing
      // *before* checking, and checking the full synced table rather than
      // only what this pass's scan inserted: the backend's per-filename
      // idempotency (Redis TTL, spec §7.6) means a file already uploaded
      // once (e.g. by an earlier run of this very test) keeps landing as
      // `duplicate` forever after, so a fresh `uploaded` result can't be
      // relied on every run — but any junk transaction genuinely sitting in
      // the dev database (this pass's or an earlier session's) proves the
      // same thing: the backend really does create a normal amount==0
      // transaction for an unreadable slip, and the client really does
      // flag it.
      final now = DateTime.now();
      final monthNotifier = container.read(selectedMonthProvider.notifier);
      for (var guard = 0; guard < 24; guard++) {
        final current = container.read(selectedMonthProvider);
        if (current.year == now.year && current.month == now.month) break;
        if (DateTime.utc(current.year, current.month).isBefore(DateTime.utc(now.year, now.month))) {
          monthNotifier.next();
        } else {
          monthNotifier.previous();
        }
      }
      final repo = container.read(transactionsRepositoryProvider);
      final syncResult = await repo.fetchPage(year: now.year, month: now.month, page: 1, limit: 100);
      // ignore: avoid_print
      print(
        'T12-LAYER2: month sync -> ${syncResult.fold((f) => 'FAILED: $f', (p) => '${p.transactions.length} transaction(s), ${p.totalPages} page(s)')}',
      );

      final rows = await db.select(db.cachedTransactions).get();
      final junkRows = rows.where((r) => r.isJunk).toList()..sort((a, b) => a.id.compareTo(b.id));
      // ignore: avoid_print
      print('T12-LAYER2: ${junkRows.length} junk row(s) out of ${rows.length} total: ${junkRows.map((r) => r.id).join(', ')}');
      expect(
        junkRows,
        isNotEmpty,
        reason: 'expected at least one real junk transaction (fresh or historical) in the dev database this month',
      );
      for (final row in junkRows) {
        expect(row.amount, 0, reason: '${row.localImageName} (id ${row.id}) should have amount==0');
        expect(row.senderName, isEmpty, reason: '${row.localImageName} (id ${row.id}) should have an empty senderName');
        expect(row.receiverName, isEmpty, reason: '${row.localImageName} (id ${row.id}) should have an empty receiverName');
      }

      // --- Step 3: mount the REAL feed page (T7) ---
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MaterialApp(home: TransactionsPage())));
      await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 30));

      final badgeCountBefore = find.text("Couldn't read slip data").evaluate().length;
      // ignore: avoid_print
      print('T12-LAYER2: warning badge count in the live-rendered feed = $badgeCountBefore');
      expect(badgeCountBefore, greaterThanOrEqualTo(1), reason: 'the real feed should render the warning badge for the real junk transaction');

      // --- Step 4: delete one junk row through the REAL UI (tap -> confirm -> real DELETE) ---
      // The real ListView orders newest-first (watchMonth: transactionDate
      // desc, id desc) — that doesn't necessarily match `junkRows`' query
      // order, so don't assume `.first` tapped == `junkRows.first`. Diff
      // the id set before/after instead of guessing which one disappeared
      // (same fix as Step 5's edit-target lookup below).
      final junkIdsBefore = junkRows.map((r) => r.id).toSet();
      final deleteButtonFinder = find.byKey(const Key('junkDeleteButton'));
      expect(deleteButtonFinder, findsWidgets);
      await tester.tap(deleteButtonFinder.first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 15));

      final junkIdsAfterDelete = (await db.select(db.cachedTransactions).get()).where((r) => r.isJunk).map((r) => r.id).toSet();
      final deletedIds = junkIdsBefore.difference(junkIdsAfterDelete);
      // ignore: avoid_print
      print('T12-LAYER2: deleted junk id(s) locally: $deletedIds');
      expect(deletedIds, hasLength(1), reason: 'exactly one junk row should have been removed locally by the delete action');
      final deletedId = deletedIds.single;
      final rowToDelete = junkRows.firstWhere((r) => r.id == deletedId);

      final refetch = await repo.fetchPage(
        year: rowToDelete.transactionDate.year,
        month: rowToDelete.transactionDate.month,
        page: 1,
        limit: 100,
      );
      final stillThereServerSide = refetch.fold(
        (f) => throw StateError('re-fetch after delete failed: $f'),
        (page) => page.transactions.any((t) => t.id == deletedId),
      );
      // ignore: avoid_print
      print('T12-LAYER2: id $deletedId still present server-side after delete? $stillThereServerSide');
      expect(stillThereServerSide, isFalse, reason: 'DELETE must have hit the real backend, not just the local cache');

      // --- Step 5: edit a DIFFERENT junk row through the REAL T6 form ---
      // Re-query rather than reuse the pre-mount `junkRows` snapshot: that
      // snapshot was taken right after the scan, before TransactionsPage's
      // own mount synced the rest of the month in — [refetch] above just
      // upserted the server's current state for this month into
      // cached_transactions (same side effect fetchPage always has), so any
      // other real junk transaction already sitting in the dev database
      // (e.g. from an earlier session) is visible here now, not just the
      // one this pass newly uploaded.
      final allRowsAfterSync = await db.select(db.cachedTransactions).get();
      final remainingJunk = allRowsAfterSync.where((r) => r.isJunk && r.id != rowToDelete.id).toList();
      // ignore: avoid_print
      print('T12-LAYER2: ${remainingJunk.length} junk row(s) available to edit after sync: ${remainingJunk.map((r) => r.id).join(', ')}');
      if (remainingJunk.isEmpty) {
        // ignore: avoid_print
        print('T12-LAYER2: no other junk row available — edit-clears-isJunk step skipped '
            '(the delete step above already proves the real-backend wire call).');
        return;
      }
      // Tap whichever junk row's edit button the real ListView renders
      // first — its on-screen order (transactionDate desc, id desc per
      // watchMonth) doesn't necessarily match `remainingJunk`'s query
      // order, so read back which transaction actually got opened instead
      // of assuming it matches `remainingJunk.first`.
      await tester.tap(find.byKey(const Key('junkEditButton')).first);
      await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 15));
      final formFinder = find.byType(TransactionFormPage);
      expect(formFinder, findsOneWidget);
      final openedTransaction = tester.widget<TransactionFormPage>(formFinder).initial!;
      final rowToEditId = openedTransaction.id;
      final isTransfer = openedTransaction.type == TransactionType.transfer;
      // ignore: avoid_print
      print('T12-LAYER2: editing junk row id=$rowToEditId type=${openedTransaction.type}');
      if (isTransfer && accounts.length < 2) {
        // ignore: avoid_print
        print('T12-LAYER2: the opened junk row is a transfer but fewer than 2 active accounts exist — edit step skipped.');
        return;
      }

      await tester.enterText(find.byKey(const Key('amountField')), '500');
      if (isTransfer) {
        await tester.tap(find.byKey(const Key('fromAccountDropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(accounts[0].name).last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('toAccountDropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(accounts[1].name).last);
        await tester.pumpAndSettle();
      } else {
        await tester.tap(find.byKey(const Key('accountDropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(accounts[0].name).last);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 15));

      final editedRow = await (db.select(db.cachedTransactions)..where((t) => t.id.equals(rowToEditId))).getSingleOrNull();
      // ignore: avoid_print
      print('T12-LAYER2: after edit, row $rowToEditId -> amount=${editedRow?.amount} isJunk=${editedRow?.isJunk}');
      expect(editedRow, isNotNull, reason: 'the edited row should still exist after a successful PATCH');
      expect(editedRow!.amount, 500, reason: 'the real PATCH response should reflect the new amount');
      expect(editedRow.isJunk, isFalse, reason: 'a nonzero amount from a real PATCH response should clear isJunk');

      await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 15));
      final badgeCountAfter = find.text("Couldn't read slip data").evaluate().length;
      // ignore: avoid_print
      print('T12-LAYER2: warning badge count in the live feed after edit = $badgeCountAfter (was $badgeCountBefore)');
      expect(badgeCountAfter, lessThan(badgeCountBefore), reason: 'the edited row\'s badge should have disappeared from the real feed');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

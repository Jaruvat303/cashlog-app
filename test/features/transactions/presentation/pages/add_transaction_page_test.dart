// Before any pumpWidget/pumpAndSettle, every repository this page touches is
// overridden with a hand-written fake — this is what keeps a real dio call
// from ever reaching Flutter's test HTTP stub, the exact thing that caused a
// hang in T4. Split out of transaction_form_page_test.dart when the
// post-launch redesign moved transaction *creation* off that page onto this
// new numpad-driven one — TransactionFormPage stays the edit-only escape
// hatch, covered separately.
import 'package:cashlog/core/cache/cache_invalidator.dart';
import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/accounts/data/accounts_repository.dart';
import 'package:cashlog/features/accounts/domain/account.dart';
import 'package:cashlog/features/categories/data/categories_repository.dart';
import 'package:cashlog/features/categories/domain/category.dart';
import 'package:cashlog/features/transactions/data/pending_action_mapper.dart';
import 'package:cashlog/features/transactions/data/pending_actions_repository.dart';
import 'package:cashlog/features/transactions/data/transactions_repository.dart';
import 'package:cashlog/features/transactions/domain/pending_action.dart';
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:cashlog/features/transactions/domain/transaction_page.dart';
import 'package:cashlog/features/transactions/presentation/pages/add_transaction_page.dart';
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
  int createCallCount = 0;
  Either<Failure, Transaction>? nextCreateResult;

  @override
  Stream<List<Transaction>> watchMonth({required int year, required int month, int? categoryId}) =>
      throw UnimplementedError('not exercised by this page test');

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

/// Same reasoning as `transaction_form_page_test.dart`'s copy: records which
/// months got invalidated without needing the real drift-backed families.
class _RecordingCacheInvalidator implements CacheInvalidator {
  final List<Set<(int, int)>> invalidatedMonthSets = [];

  @override
  void invalidateMonth(int year, int month) => invalidatedMonthSets.add({(year, month)});

  @override
  void invalidateMonths(Set<(int, int)> months) => invalidatedMonthSets.add(months);
}

/// In-memory stand-in — same reasoning as `transaction_form_page_test.dart`'s
/// copy (a real drift-backed repository hits a known drift/flutter_test
/// stream-cancellation interaction inside `testWidgets`).
class _FakePendingActionsRepository implements PendingActionsRepository {
  final List<PendingAction> _items = [];
  int _nextId = 1;

  @override
  Stream<List<PendingAction>> watchAll() => Stream.value(List.unmodifiable(_items));

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
    return true;
  }

  @override
  Future<void> recordRetryFailure(int id, String? errorCode) => throw UnimplementedError('not exercised by this page test');

  @override
  Future<void> remove(int id) => throw UnimplementedError('not exercised by this page test');
}

/// pumpAndSettle can't tell "still legitimately loading" from "stuck
/// forever" — a bounded pump loop fails fast instead.
Future<void> _pumpBounded(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late _FakeTransactionsRepository fakeTransactions;
  late _FakePendingActionsRepository pendingActions;
  late _RecordingCacheInvalidator cacheInvalidator;

  setUp(() {
    fakeTransactions = _FakeTransactionsRepository();
    pendingActions = _FakePendingActionsRepository();
    cacheInvalidator = _RecordingCacheInvalidator();
  });

  Widget buildApp() => ProviderScope(
    overrides: [
      accountsRepositoryProvider.overrideWithValue(_FakeAccountsRepository()),
      categoriesRepositoryProvider.overrideWithValue(_FakeCategoriesRepository()),
      transactionsRepositoryProvider.overrideWithValue(fakeTransactions),
      pendingActionsRepositoryProvider.overrideWithValue(pendingActions),
      cacheInvalidatorProvider.overrideWithValue(cacheInvalidator),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddTransactionPage())),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  Future<void> tapDigits(WidgetTester tester, String digits) async {
    for (final digit in digits.split('')) {
      final finder = find.text(digit);
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder);
      await tester.pump();
    }
  }

  group('Topbar trailing action (ticket 04)', () {
    testWidgets('no delete button on the create-transaction page', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('open'));
      await _pumpBounded(tester);

      expect(find.byKey(const Key('deleteTransactionButton')), findsNothing);
    });

    testWidgets('the create-transaction Topbar has no trailing action at all — only the close button on the left', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('open'));
      await _pumpBounded(tester);

      // The close ("X") button is the page's only interactive Topbar
      // control — create mode never shows a right-side action (spec: "ไม่มี
      // ปุ่มขวา"), whether delete, overflow, or anything else.
      expect(find.byIcon(RemixIcon.closeLine), findsOneWidget);
      expect(find.byIcon(RemixIcon.deleteBinLine), findsNothing);
      expect(find.byIcon(Icons.more_horiz), findsNothing);
    });
  });

  testWidgets('a transfer with the same account on both sides is blocked before any create call', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('open'));
    await _pumpBounded(tester);

    await tester.tap(find.text('ย้ายเงิน'));
    await _pumpBounded(tester);

    await tester.tap(find.byKey(const Key('fromAccountPill')));
    await _pumpBounded(tester);
    await tester.tap(find.byKey(const Key('accountOption_1')));
    await _pumpBounded(tester);

    await tester.tap(find.byKey(const Key('toAccountPill')));
    await _pumpBounded(tester);
    await tester.tap(find.byKey(const Key('accountOption_1')));
    await _pumpBounded(tester);

    await tapDigits(tester, '100');
    await tester.ensureVisible(find.byKey(const Key('submitButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('submitButton')));
    await _pumpBounded(tester);

    expect(find.text('บัญชีต้นทางและปลายทางต้องไม่ใช่บัญชีเดียวกัน'), findsOneWidget);
    expect(fakeTransactions.createCallCount, 0);
    expect(find.byType(AddTransactionPage), findsOneWidget);
  });

  testWidgets('creating a valid income transaction calls create and pops the page', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('open'));
    await _pumpBounded(tester);

    await tester.tap(find.text('รายรับ'));
    await _pumpBounded(tester);

    await tester.tap(find.byKey(const Key('accountPill')));
    await _pumpBounded(tester);
    await tester.tap(find.byKey(const Key('accountOption_1')));
    await _pumpBounded(tester);

    await tapDigits(tester, '5000');
    await tester.ensureVisible(find.byKey(const Key('submitButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('submitButton')));
    await _pumpBounded(tester);
    await tester.pumpAndSettle(const Duration(milliseconds: 50), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));

    expect(fakeTransactions.createCallCount, 1);
    expect(find.byType(AddTransactionPage), findsNothing);
    expect(find.text('open'), findsOneWidget);

    final today = DateTime.now();
    expect(cacheInvalidator.invalidatedMonthSets, [
      {(today.year, today.month)},
    ]);
  });

  group('T13 pending-actions queue', () {
    Future<void> fillAndSubmitIncome(WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('open'));
      await _pumpBounded(tester);

      await tester.tap(find.text('รายรับ'));
      await _pumpBounded(tester);

      await tester.tap(find.byKey(const Key('accountPill')));
      await _pumpBounded(tester);
      await tester.tap(find.byKey(const Key('accountOption_1')));
      await _pumpBounded(tester);

      await tapDigits(tester, '5000');
      await tester.ensureVisible(find.byKey(const Key('submitButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('submitButton')));
      await _pumpBounded(tester);
    }

    testWidgets('a transient create failure gets queued and shows the retry-queue snackbar', (tester) async {
      fakeTransactions.nextCreateResult = const Left(TimeoutFailure());
      await fillAndSubmitIncome(tester);

      expect(find.text('ไม่มีการเชื่อมต่อ — บันทึกไว้ในคิวลองใหม่แล้ว'), findsOneWidget);
      expect(find.byType(AddTransactionPage), findsOneWidget);

      final queued = await pendingActions.watchAll().first;
      expect(queued, hasLength(1));
      expect(queued.single.actionType, PendingActionType.createTransaction);
      expect(queued.single.targetTransactionId, isNull);
    });

    testWidgets('a permanent create failure is not queued — snackbar only', (tester) async {
      fakeTransactions.nextCreateResult = const Left(InvalidInputFailure(message: 'Invalid input'));
      await fillAndSubmitIncome(tester);

      expect(find.text('Invalid input'), findsOneWidget);
      expect(await pendingActions.watchAll().first, isEmpty);
    });
  });
}

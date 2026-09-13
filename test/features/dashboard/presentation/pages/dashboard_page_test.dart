// Before any pumpWidget/pumpAndSettle, dashboardRepositoryProvider is
// overridden with a hand-written fake (same pattern as
// _FakeAccountsRepository in test/widget_test.dart) — this is what keeps a
// real dio call from ever reaching Flutter's test HTTP stub.
import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/accounts/data/accounts_repository.dart';
import 'package:cashlog/features/accounts/domain/account.dart';
import 'package:cashlog/features/categories/data/categories_repository.dart';
import 'package:cashlog/features/categories/domain/category.dart';
import 'package:cashlog/features/dashboard/data/dashboard_repository.dart';
import 'package:cashlog/features/dashboard/domain/dashboard_summary.dart';
import 'package:cashlog/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:cashlog/features/transactions/data/transactions_repository.dart';
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:cashlog/features/transactions/domain/transaction_page.dart';
import 'package:cashlog/shared/format/money.dart';
import 'package:dartz/dartz.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

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
  @override
  Stream<List<Transaction>> watchMonth({required int year, required int month}) => Stream.value(const []);
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

class _FakeDashboardRepository implements DashboardRepository {
  final Map<(int, int), Either<Failure, DashboardSummary>> results = {};
  final List<(int, int)> fetchCalls = [];

  @override
  Future<Either<Failure, DashboardSummary>> fetchSummary({required int year, required int month}) async {
    fetchCalls.add((year, month));
    return results[(year, month)] ?? const Left(UnknownFailure(message: 'no result configured for this month'));
  }
}

CategoryBreakdown _breakdown(int id, String name, double amount, {String iconKey = 'restaurant-fill', String colorHex = '#EF4444'}) =>
    CategoryBreakdown(categoryId: id, categoryName: name, iconKey: iconKey, colorHex: colorHex, totalAmount: amount);

/// pumpAndSettle can't tell "still legitimately loading" from "stuck
/// forever" — a bounded pump loop fails fast instead (same reasoning as
/// test/widget_test.dart's `_pumpBounded`).
Future<void> _pumpBounded(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late _FakeDashboardRepository fakeRepository;
  late DateTime thisMonth;

  setUp(() {
    fakeRepository = _FakeDashboardRepository();
    final now = DateTime.now();
    thisMonth = DateTime.utc(now.year, now.month);
  });

  Widget buildApp() => ProviderScope(
    overrides: [
      dashboardRepositoryProvider.overrideWithValue(fakeRepository),
      accountsRepositoryProvider.overrideWithValue(_FakeAccountsRepository()),
      categoriesRepositoryProvider.overrideWithValue(_FakeCategoriesRepository()),
      transactionsRepositoryProvider.overrideWithValue(_FakeTransactionsRepository()),
    ],
    child: const MaterialApp(home: DashboardPage()),
  );

  testWidgets('renders totals from the summary and never shows total_transfer', (tester) async {
    fakeRepository.results[(thisMonth.year, thisMonth.month)] = Right(
      DashboardSummary(
        totalIncome: 5000,
        totalExpense: 2000,
        totalTransfer: 999999,
        year: thisMonth.year,
        month: thisMonth.month,
        income: const [],
        expense: [_breakdown(1, 'Food', 2000)],
      ),
    );

    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);

    expect(find.text(formatAmount(5000)), findsOneWidget);
    expect(find.text(formatAmount(2000)), findsOneWidget); // total expense card only — the legend shows a % share, not the amount
    expect(find.text('100%'), findsOneWidget); // the one expense category is 100% of the (2000) total
    expect(find.text(formatAmount(999999)), findsNothing);
    expect(find.textContaining('999999'), findsNothing);
  });

  testWidgets('expense rows render sorted descending by amount, with a pie chart', (tester) async {
    fakeRepository.results[(thisMonth.year, thisMonth.month)] = Right(
      DashboardSummary(
        totalIncome: 0,
        totalExpense: 300,
        totalTransfer: 0,
        year: thisMonth.year,
        month: thisMonth.month,
        income: const [],
        expense: [_breakdown(1, 'Small', 50), _breakdown(2, 'Big', 200), _breakdown(3, 'Medium', 50)],
      ),
    );

    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);

    expect(find.byType(PieChart), findsOneWidget);
    final names = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
    expect(names.indexOf('Big'), lessThan(names.indexOf('Small')));
  });

  testWidgets('shows an empty-state message instead of a chart when expense is empty', (tester) async {
    fakeRepository.results[(thisMonth.year, thisMonth.month)] = Right(
      DashboardSummary(
        totalIncome: 1000,
        totalExpense: 0,
        totalTransfer: 0,
        year: thisMonth.year,
        month: thisMonth.month,
        income: const [],
        expense: const [],
      ),
    );

    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);

    expect(find.text('ไม่มีรายจ่ายในเดือนนี้'), findsOneWidget);
    expect(find.byType(PieChart), findsNothing);
  });

  testWidgets('switching month via the shared selector refetches and swaps displayed totals', (tester) async {
    // Expense deliberately nonzero and distinct from income so "net" never
    // collides in text with "income"/"expense" (net = income - expense).
    final nextMonth = DateTime.utc(thisMonth.year, thisMonth.month + 1);
    fakeRepository.results[(thisMonth.year, thisMonth.month)] = Right(
      DashboardSummary(totalIncome: 100, totalExpense: 30, totalTransfer: 0, year: thisMonth.year, month: thisMonth.month, income: const [], expense: const []),
    );
    fakeRepository.results[(nextMonth.year, nextMonth.month)] = Right(
      DashboardSummary(totalIncome: 700, totalExpense: 200, totalTransfer: 0, year: nextMonth.year, month: nextMonth.month, income: const [], expense: const []),
    );

    await tester.pumpWidget(buildApp());
    await _pumpBounded(tester);
    expect(find.text(formatAmount(100)), findsOneWidget);

    await tester.tap(find.byIcon(RemixIcon.arrowRightSLine));
    await _pumpBounded(tester);

    expect(find.text(formatAmount(100)), findsNothing);
    expect(find.text(formatAmount(700)), findsOneWidget);
    expect(fakeRepository.fetchCalls, contains((nextMonth.year, nextMonth.month)));
  });
}

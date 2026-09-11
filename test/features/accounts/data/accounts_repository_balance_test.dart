// BR-7 current_balance formula:
//   opening_balance
//   + SUM(income, accountId == this)
//   - SUM(expense, accountId == this)
//   - SUM(transfer, fromAccountId == this)
//   + SUM(transfer, toAccountId == this)
// Computed entirely in SQL (AccountsRepository.watchCurrentBalance) against
// an in-memory drift db — no network involved, so no ApiClient/dio fake is
// needed here, unlike the other *_repository_test.dart files in this repo.
import 'package:cashlog/core/db/app_database.dart';
import 'package:cashlog/core/network/api_client.dart';
import 'package:cashlog/features/accounts/data/accounts_repository.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AccountsRepository repository;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    repository = AccountsRepository(ApiClient(Dio()), db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedAccount(int id, {required double openingBalance, bool isActive = true}) => db
      .into(db.cachedAccounts)
      .insert(
        CachedAccountsCompanion.insert(
          id: Value(id),
          name: 'Account $id',
          accountType: 'bank',
          openingBalance: openingBalance,
          matchingKeywordsJson: '[]',
          bankIcon: 'scb',
          isActive: isActive,
        ),
      );

  var nextTxId = 1000;
  Future<void> seedTransaction({
    required String type,
    required double amount,
    int? accountId,
    int? fromAccountId,
    int? toAccountId,
  }) => db
      .into(db.cachedTransactions)
      .insert(
        CachedTransactionsCompanion.insert(
          id: Value(nextTxId++),
          amount: amount,
          transactionType: type,
          accountId: Value(accountId),
          fromAccountId: Value(fromAccountId),
          toAccountId: Value(toAccountId),
          source: 'manual',
          transactionDate: DateTime.utc(2026, 9, 1),
        ),
      );

  test('computes opening_balance + income - expense - outgoing transfer + incoming transfer', () async {
    await seedAccount(1, openingBalance: 1000);
    // income and expense on this account.
    await seedTransaction(type: 'income', amount: 500, accountId: 1);
    await seedTransaction(type: 'expense', amount: 200, accountId: 1);
    // transfer out of this account, and a transfer into this account.
    await seedTransaction(type: 'transfer', amount: 100, fromAccountId: 1, toAccountId: 2);
    await seedTransaction(type: 'transfer', amount: 50, fromAccountId: 2, toAccountId: 1);
    // Noise: rows that belong to a different account entirely, and must not
    // affect account 1's balance.
    await seedAccount(2, openingBalance: 9999);
    await seedTransaction(type: 'income', amount: 12345, accountId: 2);
    await seedTransaction(type: 'expense', amount: 999, accountId: 2);

    final balance = await repository.watchCurrentBalance(1).first;

    // 1000 + 500 - 200 - 100 + 50 = 1250
    expect(balance, 1250.0);
  });

  test('an account with no transactions returns exactly its opening_balance', () async {
    await seedAccount(3, openingBalance: 750.5);

    final balance = await repository.watchCurrentBalance(3).first;

    expect(balance, 750.5);
  });

  test('a closed (soft-deleted) account still computes its balance from cache, no network call', () async {
    await seedAccount(4, openingBalance: 300, isActive: false);
    await seedTransaction(type: 'income', amount: 100, accountId: 4);

    final balance = await repository.watchCurrentBalance(4).first;

    expect(balance, 400.0);
  });

  test('reacts to a newly inserted transaction (drift readsFrom both tables)', () async {
    await seedAccount(5, openingBalance: 0);

    final stream = repository.watchCurrentBalance(5);
    final emissions = <double>[];
    final sub = stream.listen(emissions.add);
    addTearDown(sub.cancel);

    await pumpEventQueue();
    await seedTransaction(type: 'income', amount: 42, accountId: 5);
    await pumpEventQueue();

    expect(emissions, [0.0, 42.0]);
  });
}

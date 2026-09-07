import 'package:cashlog/features/transactions/data/transaction_mapper.dart';
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('transactionFromJson parses an income transaction response with a nested category', () {
    // Live response shape (confirmed against the dev swagger doc/a real
    // response): category is nested as `category: {id, name, type,
    // icon_key, color_hex}`, never a flat `category_id`.
    final transaction = transactionFromJson({
      'id': 1,
      'amount': 50000,
      'transaction_type': 'income',
      'account_id': 7,
      'transaction_date': '2026-09-01T00:00:00.000Z',
      'category': {'id': 3, 'name': 'Salary', 'type': 'income', 'icon_key': 'salary', 'color_hex': '#22C55E'},
    });

    expect(transaction.id, 1);
    expect(transaction.amount, 50000.0);
    expect(transaction.type, TransactionType.income);
    expect(transaction.accountId, 7);
    expect(transaction.categoryId, 3);
    expect(transaction.fromAccountId, isNull);
  });

  test('transactionFromJson treats a null category as uncategorized', () {
    final transaction = transactionFromJson({
      'id': 4,
      'amount': 100,
      'transaction_type': 'expense',
      'account_id': 1,
      'transaction_date': '2026-09-01T00:00:00.000Z',
      'category': null,
    });

    expect(transaction.categoryId, isNull);
  });

  test('transactionFromJson parses a transfer transaction response', () {
    final transaction = transactionFromJson({
      'id': 2,
      'amount': 1000,
      'transaction_type': 'transfer',
      'from_account_id': 1,
      'to_account_id': 2,
      'transaction_date': '2026-09-01T00:00:00.000Z',
    });

    expect(transaction.type, TransactionType.transfer);
    expect(transaction.fromAccountId, 1);
    expect(transaction.toAccountId, 2);
    expect(transaction.accountId, isNull);
    expect(transaction.categoryId, isNull);
  });

  group('createTransactionBody (POST /transactions — income/expense only)', () {
    test('carries account_id, transaction_type, and an optional category_id', () {
      final body = createTransactionBody(
        type: TransactionType.expense,
        amount: 100,
        date: DateTime.utc(2026, 9, 1),
        accountId: 5,
        categoryId: 9,
      );

      expect(body['transaction_type'], 'expense');
      expect(body['account_id'], 5);
      expect(body['category_id'], 9);
      expect(body.containsKey('from_account_id'), isFalse);
      expect(body.containsKey('to_account_id'), isFalse);
    });

    test('rejects a transfer type — that DTO does not exist for this endpoint', () {
      expect(
        () => createTransactionBody(type: TransactionType.transfer, amount: 100, date: DateTime.utc(2026, 9, 1), accountId: 1),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('createTransferBody (POST /transactions/transfer)', () {
    test('carries from_account_id/to_account_id, never a transaction_type, category_id optional', () {
      final body = createTransferBody(amount: 100, date: DateTime.utc(2026, 9, 1), fromAccountId: 1, toAccountId: 2, categoryId: 9);

      expect(body['from_account_id'], 1);
      expect(body['to_account_id'], 2);
      expect(body['category_id'], 9);
      expect(body.containsKey('transaction_type'), isFalse);
      expect(body.containsKey('account_id'), isFalse);
    });

    test('omits category_id entirely when none is given', () {
      final body = createTransferBody(amount: 100, date: DateTime.utc(2026, 9, 1), fromAccountId: 1, toAccountId: 2);

      expect(body.containsKey('category_id'), isFalse);
    });
  });

  test('round-trips through a CachedTransactionsCompanion', () {
    final transaction = Transaction(
      id: 1,
      amount: 250.5,
      type: TransactionType.expense,
      accountId: 5,
      categoryId: 9,
      source: 'manual',
      transactionDate: DateTime.utc(2026, 9, 1),
    );

    final companion = transactionToCompanion(transaction);
    expect(companion.amount.value, 250.5);
    expect(companion.transactionType.value, 'expense');
    expect(companion.accountId.value, 5);
    expect(companion.categoryId.value, 9);
    expect(companion.fromAccountId.value, isNull);
  });

  test('transactionTypeFromWire falls back to expense for an unrecognized value', () {
    expect(transactionTypeFromWire('bogus'), TransactionType.expense);
    expect(transactionTypeFromWire('income'), TransactionType.income);
    expect(transactionTypeFromWire('transfer'), TransactionType.transfer);
  });
}

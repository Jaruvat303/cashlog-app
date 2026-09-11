import 'package:cashlog/features/transactions/domain/pending_action.dart';
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PendingActionType wire round-trip', () {
    test('every value round-trips through toWire/pendingActionTypeFromWire', () {
      for (final type in PendingActionType.values) {
        expect(pendingActionTypeFromWire(type.toWire()), type);
      }
    });

    test('matches spec §8\'s exact documented strings', () {
      expect(PendingActionType.createTransaction.toWire(), 'create_transaction');
      expect(PendingActionType.createTransfer.toWire(), 'create_transfer');
      expect(PendingActionType.updateTransaction.toWire(), 'update_transaction');
      expect(PendingActionType.deleteTransaction.toWire(), 'delete_transaction');
    });
  });

  group('createTransactionPayload round-trip', () {
    test('required fields only', () {
      final payload = createTransactionPayload(type: TransactionType.income, amount: 100, date: DateTime.utc(2026, 9, 5), accountId: 3);
      final args = readCreateTransactionPayload(payload);

      expect(args.type, TransactionType.income);
      expect(args.amount, 100);
      expect(args.date, DateTime.utc(2026, 9, 5));
      expect(args.note, isNull);
      expect(args.accountId, 3);
      expect(args.categoryId, isNull);
    });

    test('optional note/categoryId round-trip when present', () {
      final payload = createTransactionPayload(
        type: TransactionType.expense,
        amount: 50,
        date: DateTime.utc(2026, 9, 5),
        note: 'Coffee',
        accountId: 3,
        categoryId: 9,
      );
      final args = readCreateTransactionPayload(payload);

      expect(args.note, 'Coffee');
      expect(args.categoryId, 9);
    });
  });

  test('createTransferPayload round-trip', () {
    final payload = createTransferPayload(amount: 200, date: DateTime.utc(2026, 9, 5), fromAccountId: 1, toAccountId: 2, categoryId: 7);
    final args = readCreateTransferPayload(payload);

    expect(args.amount, 200);
    expect(args.date, DateTime.utc(2026, 9, 5));
    expect(args.fromAccountId, 1);
    expect(args.toAccountId, 2);
    expect(args.categoryId, 7);
  });

  test('updateTransactionPayload round-trip, including originalDate for month-boundary invalidation', () {
    final payload = updateTransactionPayload(
      type: TransactionType.expense,
      amount: 75,
      date: DateTime.utc(2026, 9, 5),
      accountId: 4,
      categoryId: 11,
      originalDate: DateTime.utc(2026, 8, 31),
    );
    final args = readUpdateTransactionPayload(payload);

    expect(args.type, TransactionType.expense);
    expect(args.amount, 75);
    expect(args.date, DateTime.utc(2026, 9, 5));
    expect(args.accountId, 4);
    expect(args.fromAccountId, isNull);
    expect(args.toAccountId, isNull);
    expect(args.categoryId, 11);
    expect(args.originalDate, DateTime.utc(2026, 8, 31));
  });

  test('deleteTransactionPayload round-trip', () {
    final payload = deleteTransactionPayload(date: DateTime.utc(2026, 9, 5));
    final args = readDeleteTransactionPayload(payload);

    expect(args.date, DateTime.utc(2026, 9, 5));
  });
}

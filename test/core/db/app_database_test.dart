import 'package:cashlog/core/db/app_database.dart';
import 'package:cashlog/core/db/tables/scanned_slips.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('writes and reads a ScannedSlips row', () async {
    await db
        .into(db.scannedSlips)
        .insert(
          ScannedSlipsCompanion.insert(
            localImageName: 'slip_001.jpg',
            sourceFolder: 'SCB EASY',
            status: SlipStatus.uploaded,
            scannedAt: DateTime.utc(2026, 9, 1),
          ),
        );

    final row = await (db.select(
      db.scannedSlips,
    )..where((t) => t.localImageName.equals('slip_001.jpg'))).getSingle();

    expect(row.sourceFolder, 'SCB EASY');
    expect(row.status, SlipStatus.uploaded);
    expect(row.retryCount, 0);
  });

  test('writes and reads a CachedTransactions row', () async {
    await db
        .into(db.cachedTransactions)
        .insert(
          CachedTransactionsCompanion.insert(
            id: const Value(1),
            amount: 250.5,
            transactionType: 'expense',
            source: 'slip',
            transactionDate: DateTime.utc(2026, 9, 1),
          ),
        );

    final row = await (db.select(
      db.cachedTransactions,
    )..where((t) => t.id.equals(1))).getSingle();

    expect(row.amount, 250.5);
    expect(row.transactionType, 'expense');
    expect(row.isJunk, false);
  });

  test('writes and reads a CachedAccounts row', () async {
    await db
        .into(db.cachedAccounts)
        .insert(
          CachedAccountsCompanion.insert(
            id: const Value(1),
            name: 'Main SCB',
            accountType: 'bank',
            openingBalance: 1000,
            matchingKeywordsJson: '["SCB"]',
            bankIcon: 'scb',
            isActive: true,
          ),
        );

    final row = await (db.select(
      db.cachedAccounts,
    )..where((t) => t.id.equals(1))).getSingle();

    expect(row.name, 'Main SCB');
    expect(row.bankIcon, 'scb');
    expect(row.isActive, true);
  });

  test('writes and reads a CachedCategories row', () async {
    await db
        .into(db.cachedCategories)
        .insert(
          CachedCategoriesCompanion.insert(
            id: const Value(1),
            name: 'Food',
            type: 'expense',
            iconKey: 'food',
            colorHex: '#FF0000',
          ),
        );

    final row = await (db.select(
      db.cachedCategories,
    )..where((t) => t.id.equals(1))).getSingle();

    expect(row.name, 'Food');
    expect(row.colorHex, '#FF0000');
  });

  test('writes and reads a PendingManualActions row', () async {
    final id = await db
        .into(db.pendingManualActions)
        .insert(
          PendingManualActionsCompanion.insert(
            actionType: 'create_transaction',
            payloadJson: '{"amount": 100}',
            createdAt: DateTime.utc(2026, 9, 1),
          ),
        );

    final row = await (db.select(
      db.pendingManualActions,
    )..where((t) => t.id.equals(id))).getSingle();

    expect(row.actionType, 'create_transaction');
    expect(row.retryCount, 0);
  });
}

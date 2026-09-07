// Same fake-HttpClientAdapter + in-memory drift pattern as
// categories_repository_test.dart: a canned-success dio adapter stands in
// for the network so `ApiClient.post`/`patch` succeed without a real
// request reaching Flutter's test HTTP stub. This adapter also mirrors two
// live-backend quirks (confirmed against the dev API) that a naive echo
// would miss: income/expense and transfer are two different endpoints, and
// a `category_id` sent on create comes back nested as `category: {...}`,
// never as a flat `category_id`.
import 'dart:convert';
import 'dart:typed_data';

import 'package:cashlog/core/db/app_database.dart';
import 'package:cashlog/core/network/api_client.dart';
import 'package:cashlog/features/transactions/data/transactions_repository.dart';
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTransactionResponseAdapter implements HttpClientAdapter {
  _FakeTransactionResponseAdapter(this._nextId);

  int _nextId;
  final List<String> requestedPaths = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requestedPaths.add(options.path);
    final isTransfer = options.path.endsWith('/transfer');
    final sentBody = options.data is Map ? Map<String, dynamic>.from(options.data as Map) : <String, dynamic>{};
    final categoryId = sentBody.remove('category_id');

    final responseData = <String, dynamic>{
      'id': _nextId++,
      // /transactions/transfer's CreateTransferInput has no
      // transaction_type field at all, so the live response's
      // "transaction_type": "transfer" isn't an echo of anything sent —
      // synthesize it the same way the real backend does.
      'transaction_type': isTransfer ? 'transfer' : sentBody['transaction_type'],
      ...sentBody,
      // The live response nests category info, never a flat category_id —
      // reproduce that here instead of echoing category_id back flat.
      'category': categoryId == null
          ? null
          : {'id': categoryId, 'name': 'Food', 'type': 'expense', 'icon_key': 'food', 'color_hex': '#EF4444'},
    };
    return ResponseBody.fromString(
      jsonEncode({'data': responseData}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late AppDatabase db;
  late _FakeTransactionResponseAdapter adapter;
  late TransactionsRepository repository;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    adapter = _FakeTransactionResponseAdapter(1);
    repository = TransactionsRepository(ApiClient(Dio()..httpClientAdapter = adapter), db);
  });

  tearDown(() async {
    await db.close();
  });

  test('create expense hits POST /transactions and round-trips categoryId from the nested category', () async {
    final result = await repository.create(
      type: TransactionType.expense,
      amount: 100,
      date: DateTime.utc(2026, 9, 1),
      accountId: 5,
      categoryId: 9,
    );
    expect(result.isRight(), isTrue, reason: 'expected success, got failure: ${result.fold((f) => f, (_) => null)}');
    expect(adapter.requestedPaths, ['/api/v1/transactions']);

    final row = await db.select(db.cachedTransactions).getSingle();
    expect(row.transactionType, 'expense');
    expect(row.accountId, 5);
    expect(row.categoryId, 9);
    expect(row.fromAccountId, isNull);
    expect(row.toAccountId, isNull);
  });

  test('create income hits POST /transactions, categoryId optional', () async {
    final result = await repository.create(type: TransactionType.income, amount: 5000, date: DateTime.utc(2026, 9, 1), accountId: 3);
    expect(result.isRight(), isTrue, reason: 'expected success, got failure: ${result.fold((f) => f, (_) => null)}');
    expect(adapter.requestedPaths, ['/api/v1/transactions']);

    final row = await db.select(db.cachedTransactions).getSingle();
    expect(row.transactionType, 'income');
    expect(row.accountId, 3);
    expect(row.categoryId, isNull);
  });

  test('create transfer hits the dedicated POST /transactions/transfer endpoint, never a categoryId', () async {
    final result = await repository.create(
      type: TransactionType.transfer,
      amount: 200,
      date: DateTime.utc(2026, 9, 1),
      fromAccountId: 1,
      toAccountId: 2,
    );
    expect(result.isRight(), isTrue, reason: 'expected success, got failure: ${result.fold((f) => f, (_) => null)}');
    expect(adapter.requestedPaths, ['/api/v1/transactions/transfer']);

    final row = await db.select(db.cachedTransactions).getSingle();
    expect(row.transactionType, 'transfer');
    expect(row.fromAccountId, 1);
    expect(row.toAccountId, 2);
    expect(row.accountId, isNull);
    expect(row.categoryId, isNull);
  });
}

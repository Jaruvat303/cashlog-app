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
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTransactionResponseAdapter implements HttpClientAdapter {
  _FakeTransactionResponseAdapter(this._nextId);

  int _nextId;
  final List<String> requestedPaths = [];
  final List<Map<String, dynamic>> getQueryParameters = [];

  /// Canned `GET /transactions` pages, keyed by the requested `page` query
  /// param — `(rows, totalPages)`. Tests populate this before calling
  /// [TransactionsRepository.fetchPage]; an unconfigured page responds with
  /// an empty page rather than throwing, so tests only need to set up the
  /// page(s) they actually exercise.
  Map<int, (List<Map<String, dynamic>>, int)> getPages = {};

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requestedPaths.add(options.path);

    if (options.method == 'GET') {
      getQueryParameters.add(options.queryParameters);
      final page = options.queryParameters['page'] as int;
      final (rows, totalPages) = getPages[page] ?? (const <Map<String, dynamic>>[], 1);
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': rows,
          'meta': {'current_page': page, 'page_size': options.queryParameters['limit'], 'total_items': 0, 'total_pages': totalPages},
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (options.method == 'DELETE') {
      return ResponseBody.fromString(
        jsonEncode({'success': true, 'message': 'Transaction deleted successfully'}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

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

/// A DELETE that never succeeds — stands in for the backend rejecting the
/// request (e.g. 404), used to confirm [TransactionsRepository.delete]
/// leaves the local cache untouched when the network call fails, same
/// invariant `categories_repository_test.dart`'s delete guard tests care
/// about (never lose local state on a failed mutation).
class _FailingDeleteAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    return ResponseBody.fromString(jsonEncode({'success': false, 'message': 'not found'}), 404);
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

  group('fetchPage (GET /transactions)', () {
    test('sends year/month/page/limit as query parameters', () async {
      adapter.getPages = {
        1: (const [], 1),
      };
      await repository.fetchPage(year: 2026, month: 9, page: 1, limit: 15);

      expect(adapter.requestedPaths, ['/api/v1/transactions']);
      expect(adapter.getQueryParameters.single, {'year': 2026, 'month': 9, 'page': 1, 'limit': 15});
    });

    test('upserts the returned page into cached_transactions and parses pagination meta', () async {
      adapter.getPages = {
        1: ([
          {
            'id': 101,
            'amount': 50,
            'transaction_type': 'expense',
            'account_id': 1,
            'transaction_date': '2026-09-05T00:00:00.000Z',
            'category': null,
          },
        ], 2),
      };

      final result = await repository.fetchPage(year: 2026, month: 9, page: 1);
      expect(result.isRight(), isTrue, reason: 'expected success, got failure: ${result.fold((f) => f, (_) => null)}');
      final page = result.fold((f) => throw StateError('unreachable'), (p) => p);
      expect(page.currentPage, 1);
      expect(page.totalPages, 2);
      expect(page.hasMore, isTrue);

      final row = await db.select(db.cachedTransactions).getSingle();
      expect(row.id, 101);
      expect(row.transactionType, 'expense');
    });

    test('hasMore is false once currentPage reaches totalPages', () async {
      adapter.getPages = {
        2: (const [], 2),
      };

      final result = await repository.fetchPage(year: 2026, month: 9, page: 2);
      final page = result.fold((f) => throw StateError('unreachable'), (p) => p);
      expect(page.hasMore, isFalse);
    });
  });

  group('watchMonth', () {
    Future<void> seed(int id, DateTime date) => db
        .into(db.cachedTransactions)
        .insert(
          CachedTransactionsCompanion.insert(id: Value(id), amount: 10, transactionType: 'expense', source: 'manual', transactionDate: date),
        );

    test('only emits rows within the given month, newest first', () async {
      await seed(1, DateTime.utc(2026, 8, 31, 23, 59, 59)); // just before September — excluded
      await seed(2, DateTime.utc(2026, 9, 1)); // start of September — included
      await seed(3, DateTime.utc(2026, 9, 15));
      await seed(4, DateTime.utc(2026, 10, 1)); // October — excluded

      final rows = await repository.watchMonth(year: 2026, month: 9).first;

      expect(rows.map((t) => t.id).toList(), [3, 2]);
    });

    test('a December query rolls the exclusive upper bound into January of the next year', () async {
      await seed(1, DateTime.utc(2026, 12, 31, 23, 59, 59));
      await seed(2, DateTime.utc(2027, 1, 1)); // next year, next month — excluded

      final rows = await repository.watchMonth(year: 2026, month: 12).first;

      expect(rows.map((t) => t.id).toList(), [1]);
    });
  });

  group('delete (DELETE /transactions/:id — spec §7.7 junk delete path)', () {
    Future<void> seedRow(int id) => db
        .into(db.cachedTransactions)
        .insert(
          CachedTransactionsCompanion.insert(
            id: Value(id),
            amount: 0,
            transactionType: 'expense',
            source: 'slip',
            transactionDate: DateTime.utc(2026, 9, 1),
            isJunk: const Value(true),
          ),
        );

    test('a successful delete hits DELETE /transactions/:id and removes the local row', () async {
      await seedRow(42);

      final result = await repository.delete(42);

      expect(result.isRight(), isTrue, reason: 'expected success, got failure: ${result.fold((f) => f, (_) => null)}');
      expect(adapter.requestedPaths, ['/api/v1/transactions/42']);
      final remaining = await db.select(db.cachedTransactions).get();
      expect(remaining, isEmpty);
    });

    test('a failed delete leaves the local row untouched — never lose data on a rejected mutation', () async {
      await seedRow(42);
      final failingRepository = TransactionsRepository(ApiClient(Dio()..httpClientAdapter = _FailingDeleteAdapter()), db);

      final result = await failingRepository.delete(42);

      expect(result.isLeft(), isTrue);
      final remaining = await db.select(db.cachedTransactions).get();
      expect(remaining.map((r) => r.id), [42]);
    });
  });
}

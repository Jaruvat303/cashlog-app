// Repository-level test for the delete guard's core invariant (spec §12.4 /
// FR-2.2): deleting a category must never leave a dangling categoryId, and
// must never delete the transactions themselves. A fake dio HttpClientAdapter
// (not a new dependency — dio already ships this interface) stands in for
// the network so `ApiClient.delete` succeeds without a real request, exactly
// the same "don't let a real dio call happen in a test" concern noted for
// widget tests, just for a plain unit test instead.
import 'dart:typed_data';

import 'package:cashlog/core/db/app_database.dart';
import 'package:cashlog/core/network/api_client.dart';
import 'package:cashlog/features/categories/data/categories_repository.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSuccessAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    return ResponseBody.fromString('', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late AppDatabase db;
  late CategoriesRepository repository;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    final dio = Dio()..httpClientAdapter = _FakeSuccessAdapter();
    repository = CategoriesRepository(ApiClient(dio), db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedCategory(int id) => db
      .into(db.cachedCategories)
      .insert(CachedCategoriesCompanion.insert(id: Value(id), name: 'Food', type: 'expense', iconKey: 'food', colorHex: '#EF4444'));

  Future<void> seedTransaction(int id, {int? categoryId}) => db
      .into(db.cachedTransactions)
      .insert(
        CachedTransactionsCompanion.insert(
          id: Value(id),
          amount: 100,
          transactionType: 'expense',
          source: 'manual',
          transactionDate: DateTime.utc(2026, 9, 1),
          categoryId: Value(categoryId),
        ),
      );

  test('countLinkedTransactions counts only rows pointing at that category', () async {
    await seedCategory(1);
    await seedTransaction(1, categoryId: 1);
    await seedTransaction(2, categoryId: 1);
    await seedTransaction(3, categoryId: null);

    expect(await repository.countLinkedTransactions(1), 2);
    expect(await repository.countLinkedTransactions(999), 0);
  });

  test('delete removes the category and reassigns linked transactions to uncategorized', () async {
    await seedCategory(1);
    await seedTransaction(1, categoryId: 1);
    await seedTransaction(2, categoryId: 1);
    await seedTransaction(3, categoryId: null);

    final result = await repository.delete(1);
    expect(result.isRight(), isTrue, reason: 'expected success, got failure: ${result.fold((f) => f, (_) => null)}');

    final remainingCategories = await db.select(db.cachedCategories).get();
    expect(remainingCategories, isEmpty);

    final transactions = await db.select(db.cachedTransactions).get();
    expect(transactions, hasLength(3));
    expect(transactions.every((t) => t.categoryId == null), isTrue);
  });
}

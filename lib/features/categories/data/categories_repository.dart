import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import '../domain/category.dart';
import 'category_mapper.dart';

part 'categories_repository.g.dart';

/// Categories have no `isActive`/soft-close concept (unlike accounts), so
/// [delete] is a real hard delete. The local delete guard (spec §12.4 /
/// FR-2.2) is what keeps that safe: callers must count
/// [countLinkedTransactions] and confirm with the user before calling
/// [delete] — this repository doesn't gate the call itself, it just
/// guarantees that once a delete happens, every transaction that pointed at
/// this category becomes uncategorized (`categoryId = null`) rather than
/// being deleted itself.
class CategoriesRepository {
  CategoriesRepository(this._apiClient, this._db);

  final ApiClient _apiClient;
  final AppDatabase _db;

  Stream<List<Category>> watchAll() =>
      _db.select(_db.cachedCategories).watch().map((rows) => rows.map(categoryFromCached).toList());

  Future<Either<Failure, void>> refreshFromApi() async {
    final result = await _apiClient.get<List<Category>>(
      '/api/v1/categories',
      parse: (data) => ((data as Map)['data'] as List).map((e) => categoryFromJson(e as Map<String, dynamic>)).toList(),
    );
    return result.fold(
      (failure) async => Left(failure),
      (categories) async {
        await _db.batch((b) => b.insertAllOnConflictUpdate(_db.cachedCategories, categories.map(categoryToCompanion)));
        return const Right(null);
      },
    );
  }

  Future<Either<Failure, Category>> create({
    required String name,
    required CategoryType type,
    required String iconKey,
    required String colorHex,
  }) async {
    final result = await _apiClient.post<Category>(
      '/api/v1/categories',
      data: createCategoryBody(name: name, type: type, iconKey: iconKey, colorHex: colorHex),
      parse: (data) => categoryFromJson((data as Map)['data'] as Map<String, dynamic>),
    );
    return result.fold((failure) async => Left(failure), (category) async {
      await _db.into(_db.cachedCategories).insertOnConflictUpdate(categoryToCompanion(category));
      return Right(category);
    });
  }

  Future<Either<Failure, Category>> update(
    int id, {
    required String name,
    required CategoryType type,
    required String iconKey,
    required String colorHex,
  }) async {
    final result = await _apiClient.patch<Category>(
      '/api/v1/categories/$id',
      data: updateCategoryBody(name: name, type: type, iconKey: iconKey, colorHex: colorHex),
      parse: (data) => categoryFromJson((data as Map)['data'] as Map<String, dynamic>),
    );
    return result.fold((failure) async => Left(failure), (category) async {
      await _db.into(_db.cachedCategories).insertOnConflictUpdate(categoryToCompanion(category));
      return Right(category);
    });
  }

  /// Pure local read — powers the delete-guard dialog before the user
  /// confirms. No network call.
  Future<int> countLinkedTransactions(int categoryId) async {
    final rows = await (_db.select(_db.cachedTransactions)..where((t) => t.categoryId.equals(categoryId))).get();
    return rows.length;
  }

  /// `DELETE /api/v1/categories/:id`. On success, removing the local
  /// category row and reassigning every linked transaction to
  /// `categoryId = null` happen in one transaction — the two must never
  /// happen separately (a category-deleted-but-transactions-still-linked
  /// state has nothing to resolve the category name/color from).
  Future<Either<Failure, void>> delete(int id) async {
    final result = await _apiClient.delete<void>('/api/v1/categories/$id', parse: (_) {});
    return result.fold((failure) async => Left(failure), (_) async {
      await _db.transaction(() async {
        await (_db.delete(_db.cachedCategories)..where((t) => t.id.equals(id))).go();
        await (_db.update(_db.cachedTransactions)..where((t) => t.categoryId.equals(id))).write(
          const CachedTransactionsCompanion(categoryId: Value(null)),
        );
      });
      return const Right(null);
    });
  }
}

@riverpod
CategoriesRepository categoriesRepository(Ref ref) => CategoriesRepository(ref.watch(apiClientProvider), ref.watch(appDatabaseProvider));

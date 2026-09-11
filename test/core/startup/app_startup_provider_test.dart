// Root-cause fix (CLAUDE.md "App startup"): both caches must sync exactly
// once at app startup, regardless of which tab builds first — verified here
// with fakes that only need to prove the two refresh calls happen, no
// dio/drift involved.
import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/core/startup/app_startup_provider.dart';
import 'package:cashlog/features/accounts/data/accounts_repository.dart';
import 'package:cashlog/features/accounts/domain/account.dart';
import 'package:cashlog/features/categories/data/categories_repository.dart';
import 'package:cashlog/features/categories/domain/category.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAccountsRepository implements AccountsRepository {
  int refreshCallCount = 0;

  @override
  Stream<List<Account>> watchActiveAccounts() => Stream.value(const []);
  @override
  Stream<Account?> watchCached(int id) => Stream.value(null);
  @override
  Stream<double> watchCurrentBalance(int accountId) => Stream.value(0);
  @override
  Future<Either<Failure, void>> refreshFromApi() async {
    refreshCallCount++;
    return const Right(null);
  }

  @override
  Future<Either<Failure, Account>> create({
    required String name,
    required AccountType accountType,
    required double openingBalance,
    required List<String> matchingKeywords,
    required String bankIcon,
  }) => throw UnimplementedError('not exercised by this test');
  @override
  Future<Either<Failure, Account>> update(
    int id, {
    required String name,
    required AccountType accountType,
    required List<String> matchingKeywords,
    required String bankIcon,
  }) => throw UnimplementedError('not exercised by this test');
  @override
  Future<Either<Failure, void>> close(int id) => throw UnimplementedError('not exercised by this test');
}

class _FakeCategoriesRepository implements CategoriesRepository {
  int refreshCallCount = 0;

  @override
  Stream<List<Category>> watchAll() => Stream.value(const []);
  @override
  Future<Either<Failure, void>> refreshFromApi() async {
    refreshCallCount++;
    return const Right(null);
  }

  @override
  Future<Either<Failure, Category>> create({
    required String name,
    required CategoryType type,
    required String iconKey,
    required String colorHex,
  }) => throw UnimplementedError('not exercised by this test');
  @override
  Future<Either<Failure, Category>> update(
    int id, {
    required String name,
    required CategoryType type,
    required String iconKey,
    required String colorHex,
  }) => throw UnimplementedError('not exercised by this test');
  @override
  Future<int> countLinkedTransactions(int categoryId) => throw UnimplementedError('not exercised by this test');
  @override
  Future<Either<Failure, void>> delete(int id) => throw UnimplementedError('not exercised by this test');
}

void main() {
  test('appStartup refreshes both accounts and categories exactly once, regardless of who reads it', () async {
    final fakeAccounts = _FakeAccountsRepository();
    final fakeCategories = _FakeCategoriesRepository();
    final container = ProviderContainer(
      overrides: [
        accountsRepositoryProvider.overrideWithValue(fakeAccounts),
        categoriesRepositoryProvider.overrideWithValue(fakeCategories),
      ],
    );
    addTearDown(container.dispose);

    await container.read(appStartupProvider.future);

    expect(fakeAccounts.refreshCallCount, 1);
    expect(fakeCategories.refreshCallCount, 1);

    // A second, independent read (simulating some other screen also
    // depending on this provider) must not trigger a second sync —
    // keepAlive means the same completed future is shared.
    await container.read(appStartupProvider.future);
    expect(fakeAccounts.refreshCallCount, 1);
    expect(fakeCategories.refreshCallCount, 1);
  });
}

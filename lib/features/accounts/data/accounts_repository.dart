import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import '../domain/account.dart';
import 'account_mapper.dart';

part 'accounts_repository.g.dart';

/// Every mutation writes straight through to `cached_accounts`, but sync
/// from `GET /accounts` is upsert-only (BR-10/spec §12.2): that endpoint
/// filters to `is_active=true`, so a delete-then-reinsert sync would erase
/// closed accounts a transaction still needs to resolve a name/logo from.
class AccountsRepository {
  AccountsRepository(this._apiClient, this._db);

  final ApiClient _apiClient;
  final AppDatabase _db;

  /// Read-time filter (not a sync-time one) — closed accounts stay cached.
  Stream<List<Account>> watchActiveAccounts() => (_db.select(
    _db.cachedAccounts,
  )..where((t) => t.isActive.equals(true))).watch().map((rows) => rows.map(accountFromCached).toList());

  /// No `GET /accounts/:id` exists (spec §12.1) — account detail is always a
  /// direct local read, never a network call.
  Stream<Account?> watchCached(int id) =>
      (_db.select(_db.cachedAccounts)..where((t) => t.id.equals(id))).watchSingleOrNull().map(
        (row) => row == null ? null : accountFromCached(row),
      );

  Future<Either<Failure, void>> refreshFromApi() async {
    final result = await _apiClient.get<List<Account>>(
      '/api/v1/accounts',
      parse: (data) => ((data as Map)['data'] as List).map((e) => accountFromJson(e as Map<String, dynamic>)).toList(),
    );
    return result.fold(
      (failure) async => Left(failure),
      (accounts) async {
        await _db.batch((b) => b.insertAllOnConflictUpdate(_db.cachedAccounts, accounts.map(accountToCompanion)));
        return const Right(null);
      },
    );
  }

  Future<Either<Failure, Account>> create({
    required String name,
    required AccountType accountType,
    required double openingBalance,
    required List<String> matchingKeywords,
    required String bankIcon,
  }) async {
    final result = await _apiClient.post<Account>(
      '/api/v1/accounts',
      data: createAccountBody(
        name: name,
        accountType: accountType,
        openingBalance: openingBalance,
        matchingKeywords: matchingKeywords,
        bankIcon: bankIcon,
      ),
      parse: (data) => accountFromJson((data as Map)['data'] as Map<String, dynamic>),
    );
    return result.fold((failure) async => Left(failure), (account) async {
      await _db.into(_db.cachedAccounts).insertOnConflictUpdate(accountToCompanion(account));
      return Right(account);
    });
  }

  Future<Either<Failure, Account>> update(
    int id, {
    required String name,
    required AccountType accountType,
    required List<String> matchingKeywords,
    required String bankIcon,
  }) async {
    final result = await _apiClient.patch<Account>(
      '/api/v1/accounts/$id',
      data: updateAccountBody(name: name, accountType: accountType, matchingKeywords: matchingKeywords, bankIcon: bankIcon),
      parse: (data) => accountFromJson((data as Map)['data'] as Map<String, dynamic>),
    );
    return result.fold((failure) async => Left(failure), (account) async {
      await _db.into(_db.cachedAccounts).insertOnConflictUpdate(accountToCompanion(account));
      return Right(account);
    });
  }

  /// Soft-delete (`DELETE /accounts/:id`). The response carries no body to
  /// upsert from, so the local row is flipped in place — never removed —
  /// which is what keeps old transactions resolving this account's
  /// name/logo after it's closed.
  Future<Either<Failure, void>> close(int id) async {
    final result = await _apiClient.delete<void>('/api/v1/accounts/$id', parse: (_) {});
    return result.fold((failure) async => Left(failure), (_) async {
      await (_db.update(_db.cachedAccounts)..where((t) => t.id.equals(id))).write(const CachedAccountsCompanion(isActive: Value(false)));
      return const Right(null);
    });
  }
}

@riverpod
AccountsRepository accountsRepository(Ref ref) => AccountsRepository(ref.watch(apiClientProvider), ref.watch(appDatabaseProvider));

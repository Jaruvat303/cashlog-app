import 'package:dartz/dartz.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import '../domain/transaction.dart';
import 'transaction_mapper.dart';

part 'transactions_repository.g.dart';

/// No list/watch/detail method here — T7 owns the feed query over
/// `cached_transactions`, and there's no `GET /transactions/:id` to call
/// for a detail view either (same reasoning as accounts §12.1/categories):
/// edit mode is always entered with an already-in-hand [Transaction], never
/// a fetch.
class TransactionsRepository {
  TransactionsRepository(this._apiClient, this._db);

  final ApiClient _apiClient;
  final AppDatabase _db;

  /// Create splits by type across two different backend endpoints/DTOs
  /// (confirmed against the live swagger doc) — income/expense go to
  /// `POST /transactions` (`CreateTransactionInput`, requires `account_id`),
  /// a transfer goes to the dedicated `POST /transactions/transfer`
  /// (`CreateTransferInput`, requires `from_account_id`/`to_account_id`).
  /// Callers are expected to supply the fields matching `type` — the form
  /// already enforces this before calling create.
  Future<Either<Failure, Transaction>> create({
    required TransactionType type,
    required double amount,
    required DateTime date,
    String? note,
    int? accountId,
    int? fromAccountId,
    int? toAccountId,
    int? categoryId,
  }) async {
    final result = type == TransactionType.transfer
        ? await _apiClient.post<Transaction>(
            '/api/v1/transactions/transfer',
            data: createTransferBody(
              amount: amount,
              date: date,
              fromAccountId: fromAccountId!,
              toAccountId: toAccountId!,
              note: note,
              categoryId: categoryId,
            ),
            parse: (data) => transactionFromJson((data as Map)['data'] as Map<String, dynamic>),
          )
        : await _apiClient.post<Transaction>(
            '/api/v1/transactions',
            data: createTransactionBody(type: type, amount: amount, date: date, note: note, accountId: accountId!, categoryId: categoryId),
            parse: (data) => transactionFromJson((data as Map)['data'] as Map<String, dynamic>),
          );
    return result.fold((failure) async => Left(failure), (transaction) async {
      await _db.into(_db.cachedTransactions).insertOnConflictUpdate(transactionToCompanion(transaction));
      return Right(transaction);
    });
  }

  Future<Either<Failure, Transaction>> update(
    int id, {
    required TransactionType type,
    required double amount,
    required DateTime date,
    String? note,
    int? accountId,
    int? fromAccountId,
    int? toAccountId,
    int? categoryId,
  }) async {
    final result = await _apiClient.patch<Transaction>(
      '/api/v1/transactions/$id',
      data: updateTransactionBody(
        type: type,
        amount: amount,
        date: date,
        note: note,
        accountId: accountId,
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        categoryId: categoryId,
      ),
      parse: (data) => transactionFromJson((data as Map)['data'] as Map<String, dynamic>),
    );
    return result.fold((failure) async => Left(failure), (transaction) async {
      await _db.into(_db.cachedTransactions).insertOnConflictUpdate(transactionToCompanion(transaction));
      return Right(transaction);
    });
  }
}

@riverpod
TransactionsRepository transactionsRepository(Ref ref) =>
    TransactionsRepository(ref.watch(apiClientProvider), ref.watch(appDatabaseProvider));

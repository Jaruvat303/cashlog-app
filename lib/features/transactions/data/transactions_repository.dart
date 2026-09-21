import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import '../domain/transaction.dart';
import '../domain/transaction_page.dart';
import 'transaction_mapper.dart';

part 'transactions_repository.g.dart';

/// No `GET /transactions/:id` exists (same reasoning as accounts
/// §12.1/categories): edit mode (T6) is always entered with an
/// already-in-hand [Transaction], never a fetch.
class TransactionsRepository {
  TransactionsRepository(this._apiClient, this._db);

  final ApiClient _apiClient;
  final AppDatabase _db;

  /// T7's feed source: reads straight from the `cached_transactions`
  /// read-through mirror, so the list works offline (CLAUDE.md: online-only
  /// + read cache) and updates reactively as [fetchPage] upserts more pages
  /// in. Month bounds are UTC to match how `transaction_date` is parsed
  /// (`DateTime.parse` on an ISO string with a `Z` suffix) and sent
  /// (`.toUtc()` in [createTransactionBody]/[updateTransactionBody]) —
  /// `DateTime.utc(year, month + 1)` normalizes a December `month=13` into
  /// January of the next year on its own.
  /// [categoryId] (ticket 07: Transaction List category drill-through) narrows
  /// the same month-scoped query with an extra `WHERE`, rather than adding a
  /// second/parallel query path — the read stays a single reactive drift
  /// `.watch()`, so it keeps updating live as [fetchPage] upserts more of the
  /// month in, exactly like the unfiltered case. Deliberately not plumbed
  /// into [fetchPage]/pagination at all: the network sync for a given
  /// (year, month) is unconditional and unaffected by which category (if any)
  /// the UI is currently drilled into, so pagination can't regress once a
  /// filter is active.
  ///
  /// Ticket 12: [kUncategorizedCategoryId] gets its own branch rather than
  /// falling into the plain `.equals(categoryId)` case — a real
  /// uncategorized [Transaction] has `categoryId == null` in this very
  /// table, never `0`, so matching it needs `IS NULL`, not `= 0` (see
  /// [kUncategorizedCategoryId]'s doc comment for why the caller can end up
  /// passing `0` here at all).
  ///
  /// [type] (ticket 12): a real category id already implies a type, so
  /// [categoryId] alone was a sufficient filter for one — but `categoryId ==
  /// null` (Uncategorized) is true of every uncategorized income row,
  /// every uncategorized expense row, *and* every transfer (transfers never
  /// carry a category, full stop). Without also narrowing by [type], the
  /// Uncategorized filter pulled in every transfer for the month regardless
  /// of which tab (Income/Expense) it was opened from, so its total no
  /// longer matched the tab-scoped Uncategorized figure the breakdown card
  /// shows. Callers pass [type] whenever a category filter of any kind is
  /// active — see `TransactionsPage._categoryFilterType`.
  Stream<List<Transaction>> watchMonth({required int year, required int month, int? categoryId, TransactionType? type}) {
    final start = DateTime.utc(year, month);
    final end = DateTime.utc(year, month + 1);
    return (_db.select(_db.cachedTransactions)
          ..where(
            (t) =>
                t.transactionDate.isBiggerOrEqualValue(start) &
                t.transactionDate.isSmallerThanValue(end) &
                (type == null ? const Constant(true) : t.transactionType.equals(type.name)) &
                switch (categoryId) {
                  null => const Constant(true),
                  kUncategorizedCategoryId => t.categoryId.isNull(),
                  _ => t.categoryId.equals(categoryId),
                },
          )
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate), (t) => OrderingTerm.desc(t.id)]))
        .watch()
        .map((rows) => rows.map(transactionFromCached).toList());
  }

  /// `GET /api/v1/transactions` (`year`/`month`/`page`/`limit` query params,
  /// confirmed against the live dev swagger doc — default `page=1`,
  /// `limit=20`). Every transaction on the page is upserted into
  /// `cached_transactions`, same as [watchMonth]'s source — this is what
  /// makes a fetched page show up in the feed with no separate wiring.
  Future<Either<Failure, TransactionPage>> fetchPage({
    required int year,
    required int month,
    required int page,
    int limit = 20,
  }) async {
    final result = await _apiClient.get<TransactionPage>(
      '/api/v1/transactions',
      queryParameters: {'year': year, 'month': month, 'page': page, 'limit': limit},
      parse: (data) => transactionPageFromJson(data as Map<String, dynamic>),
    );
    return result.fold((failure) async => Left(failure), (page) async {
      await _db.batch((b) => b.insertAllOnConflictUpdate(_db.cachedTransactions, page.transactions.map(transactionToCompanion)));
      return Right(page);
    });
  }

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

  /// `DELETE /api/v1/transactions/:id` — spec §7.7's junk-transaction delete
  /// path, always an explicit user action (never auto-triggered). Unlike
  /// accounts (soft-delete, row kept for old-transaction lookups), a
  /// transaction delete is a hard delete, so the local row is removed
  /// outright — drift's reactive `watch()` behind [watchMonth] drops it from
  /// the feed immediately.
  Future<Either<Failure, void>> delete(int id) async {
    final result = await _apiClient.delete<void>('/api/v1/transactions/$id', parse: (_) {});
    return result.fold((failure) async => Left(failure), (_) async {
      await (_db.delete(_db.cachedTransactions)..where((t) => t.id.equals(id))).go();
      return const Right(null);
    });
  }
}

@riverpod
TransactionsRepository transactionsRepository(Ref ref) =>
    TransactionsRepository(ref.watch(apiClientProvider), ref.watch(appDatabaseProvider));

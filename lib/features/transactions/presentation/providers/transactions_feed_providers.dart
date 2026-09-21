import 'package:dartz/dartz.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/failure.dart';
import '../../data/transactions_repository.dart';
import '../../domain/transaction.dart';

part 'transactions_feed_providers.g.dart';

/// The feed's list source — always reads from the `cached_transactions`
/// drift watch (same idiom as `activeAccountsProvider`/`allCategoriesProvider`),
/// so it paints instantly from cache and updates reactively as
/// [TransactionsFeedSync] upserts more pages in.
///
/// [categoryId] (ticket 07) is an optional narrowing of the same family
/// instance space, not a second provider — omitting it (the existing call
/// shape everywhere else in the app) is exactly equivalent to passing `null`,
/// so every pre-existing caller/override is unaffected.
///
/// [type] (ticket 12): every real category id is already type-specific (an
/// expense category's id never appears on an income or transfer
/// transaction), so [categoryId] alone was enough to scope a real-category
/// filter correctly. `categoryId: kUncategorizedCategoryId` breaks that
/// assumption — "no category" spans every transaction type, transfers
/// included, since a transfer never carries a category at all. Without
/// [type], selecting "Uncategorized" from the Expense tab pulled in every
/// transfer for the month too, so its total silently stopped matching the
/// Uncategorized figure the breakdown card shows for that tab.
@riverpod
Stream<List<Transaction>> monthTransactions(Ref ref, int year, int month, {int? categoryId, TransactionType? type}) =>
    ref.watch(transactionsRepositoryProvider).watchMonth(year: year, month: month, categoryId: categoryId, type: type);

/// Pagination progress for one (year, month) — separate from the list
/// itself so switching pages never re-renders/re-fetches the whole list,
/// only appends.
class TransactionsFeedMeta {
  const TransactionsFeedMeta({
    required this.currentPage,
    required this.totalPages,
    this.isLoadingMore = false,
  });

  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;

  bool get hasMore => currentPage < totalPages;

  TransactionsFeedMeta copyWith({int? currentPage, int? totalPages, bool? isLoadingMore}) => TransactionsFeedMeta(
    currentPage: currentPage ?? this.currentPage,
    totalPages: totalPages ?? this.totalPages,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

/// Drives the paged API sync for one month (mirrors `AccountsRefresh`'s
/// "state signals loading/error, caller also gets an Either back" shape,
/// extended with page-progress payload for infinite scroll). `null` state
/// means "no page fetched yet for this month" — the page calls
/// [loadFirstPage] on open and on every month switch, so this always gets
/// populated before [loadNextPage] can be called meaningfully.
@riverpod
class TransactionsFeedSync extends _$TransactionsFeedSync {
  @override
  TransactionsFeedMeta? build(int year, int month) => null;

  Future<Either<Failure, void>> loadFirstPage() async {
    state = null;
    final result = await ref.read(transactionsRepositoryProvider).fetchPage(year: year, month: month, page: 1);
    // autoDispose: nothing keeps this alive across the await (e.g. a month
    // switch mid-request) — writing state after it's gone throws, so bail
    // per riverpod's own guidance (same reasoning as AccountsRefresh).
    if (ref.mounted) {
      state = result.fold((failure) => null, (page) => TransactionsFeedMeta(currentPage: page.currentPage, totalPages: page.totalPages));
    }
    return result.fold((failure) => Left(failure), (_) => const Right(null));
  }

  Future<Either<Failure, void>> loadNextPage() async {
    final meta = state;
    if (meta == null || meta.isLoadingMore || !meta.hasMore) return const Right(null);

    state = meta.copyWith(isLoadingMore: true);
    final result = await ref.read(transactionsRepositoryProvider).fetchPage(year: year, month: month, page: meta.currentPage + 1);
    if (ref.mounted) {
      state = result.fold(
        (failure) => meta.copyWith(isLoadingMore: false),
        (page) => TransactionsFeedMeta(currentPage: page.currentPage, totalPages: page.totalPages),
      );
    }
    return result.fold((failure) => Left(failure), (_) => const Right(null));
  }
}

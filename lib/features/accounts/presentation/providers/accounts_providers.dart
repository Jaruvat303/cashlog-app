import 'package:dartz/dartz.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/failure.dart';
import '../../data/accounts_repository.dart';
import '../../domain/account.dart';

part 'accounts_providers.g.dart';

@riverpod
Stream<List<Account>> activeAccounts(Ref ref) => ref.watch(accountsRepositoryProvider).watchActiveAccounts();

@riverpod
Stream<Account?> cachedAccount(Ref ref, int id) => ref.watch(accountsRepositoryProvider).watchCached(id);

/// BR-7 current_balance (see [AccountsRepository.watchCurrentBalance]) — a
/// derived value recomputed from cache, never fetched or persisted.
@riverpod
Stream<double> accountCurrentBalance(Ref ref, int accountId) =>
    ref.watch(accountsRepositoryProvider).watchCurrentBalance(accountId);

/// Drives the pull-to-refresh / initial-load API sync. The list itself is
/// always sourced from [activeAccountsProvider]'s drift watch, so a
/// successful refresh here shows up there automatically once it upserts.
@riverpod
class AccountsRefresh extends _$AccountsRefresh {
  @override
  FutureOr<void> build() {}

  Future<Either<Failure, void>> refresh() async {
    state = const AsyncLoading();
    final result = await ref.read(accountsRepositoryProvider).refreshFromApi();
    // Nothing keeps this autoDispose provider alive across the await (e.g.
    // a tab switch while the request is in flight) — writing `state` after
    // it's gone throws, so bail out instead per riverpod's own guidance.
    if (ref.mounted) {
      state = result.fold((failure) => AsyncError<void>(failure, StackTrace.current), (_) => const AsyncData(null));
    }
    return result;
  }
}

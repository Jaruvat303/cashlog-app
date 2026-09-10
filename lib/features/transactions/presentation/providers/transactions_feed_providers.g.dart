// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transactions_feed_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The feed's list source — always reads from the `cached_transactions`
/// drift watch (same idiom as `activeAccountsProvider`/`allCategoriesProvider`),
/// so it paints instantly from cache and updates reactively as
/// [TransactionsFeedSync] upserts more pages in.

@ProviderFor(monthTransactions)
final monthTransactionsProvider = MonthTransactionsFamily._();

/// The feed's list source — always reads from the `cached_transactions`
/// drift watch (same idiom as `activeAccountsProvider`/`allCategoriesProvider`),
/// so it paints instantly from cache and updates reactively as
/// [TransactionsFeedSync] upserts more pages in.

final class MonthTransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Transaction>>,
          List<Transaction>,
          Stream<List<Transaction>>
        >
    with
        $FutureModifier<List<Transaction>>,
        $StreamProvider<List<Transaction>> {
  /// The feed's list source — always reads from the `cached_transactions`
  /// drift watch (same idiom as `activeAccountsProvider`/`allCategoriesProvider`),
  /// so it paints instantly from cache and updates reactively as
  /// [TransactionsFeedSync] upserts more pages in.
  MonthTransactionsProvider._({
    required MonthTransactionsFamily super.from,
    required (int, int) super.argument,
  }) : super(
         retry: null,
         name: r'monthTransactionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$monthTransactionsHash();

  @override
  String toString() {
    return r'monthTransactionsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<Transaction>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Transaction>> create(Ref ref) {
    final argument = this.argument as (int, int);
    return monthTransactions(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthTransactionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$monthTransactionsHash() => r'82adb8b0df552bee127a1a2d7c17dab16136fc66';

/// The feed's list source — always reads from the `cached_transactions`
/// drift watch (same idiom as `activeAccountsProvider`/`allCategoriesProvider`),
/// so it paints instantly from cache and updates reactively as
/// [TransactionsFeedSync] upserts more pages in.

final class MonthTransactionsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Transaction>>, (int, int)> {
  MonthTransactionsFamily._()
    : super(
        retry: null,
        name: r'monthTransactionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The feed's list source — always reads from the `cached_transactions`
  /// drift watch (same idiom as `activeAccountsProvider`/`allCategoriesProvider`),
  /// so it paints instantly from cache and updates reactively as
  /// [TransactionsFeedSync] upserts more pages in.

  MonthTransactionsProvider call(int year, int month) =>
      MonthTransactionsProvider._(argument: (year, month), from: this);

  @override
  String toString() => r'monthTransactionsProvider';
}

/// Drives the paged API sync for one month (mirrors `AccountsRefresh`'s
/// "state signals loading/error, caller also gets an Either back" shape,
/// extended with page-progress payload for infinite scroll). `null` state
/// means "no page fetched yet for this month" — the page calls
/// [loadFirstPage] on open and on every month switch, so this always gets
/// populated before [loadNextPage] can be called meaningfully.

@ProviderFor(TransactionsFeedSync)
final transactionsFeedSyncProvider = TransactionsFeedSyncFamily._();

/// Drives the paged API sync for one month (mirrors `AccountsRefresh`'s
/// "state signals loading/error, caller also gets an Either back" shape,
/// extended with page-progress payload for infinite scroll). `null` state
/// means "no page fetched yet for this month" — the page calls
/// [loadFirstPage] on open and on every month switch, so this always gets
/// populated before [loadNextPage] can be called meaningfully.
final class TransactionsFeedSyncProvider
    extends $NotifierProvider<TransactionsFeedSync, TransactionsFeedMeta?> {
  /// Drives the paged API sync for one month (mirrors `AccountsRefresh`'s
  /// "state signals loading/error, caller also gets an Either back" shape,
  /// extended with page-progress payload for infinite scroll). `null` state
  /// means "no page fetched yet for this month" — the page calls
  /// [loadFirstPage] on open and on every month switch, so this always gets
  /// populated before [loadNextPage] can be called meaningfully.
  TransactionsFeedSyncProvider._({
    required TransactionsFeedSyncFamily super.from,
    required (int, int) super.argument,
  }) : super(
         retry: null,
         name: r'transactionsFeedSyncProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$transactionsFeedSyncHash();

  @override
  String toString() {
    return r'transactionsFeedSyncProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  TransactionsFeedSync create() => TransactionsFeedSync();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionsFeedMeta? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionsFeedMeta?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionsFeedSyncProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transactionsFeedSyncHash() =>
    r'7799e8559262ef2ee9388e020a9845ed280dbe76';

/// Drives the paged API sync for one month (mirrors `AccountsRefresh`'s
/// "state signals loading/error, caller also gets an Either back" shape,
/// extended with page-progress payload for infinite scroll). `null` state
/// means "no page fetched yet for this month" — the page calls
/// [loadFirstPage] on open and on every month switch, so this always gets
/// populated before [loadNextPage] can be called meaningfully.

final class TransactionsFeedSyncFamily extends $Family
    with
        $ClassFamilyOverride<
          TransactionsFeedSync,
          TransactionsFeedMeta?,
          TransactionsFeedMeta?,
          TransactionsFeedMeta?,
          (int, int)
        > {
  TransactionsFeedSyncFamily._()
    : super(
        retry: null,
        name: r'transactionsFeedSyncProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Drives the paged API sync for one month (mirrors `AccountsRefresh`'s
  /// "state signals loading/error, caller also gets an Either back" shape,
  /// extended with page-progress payload for infinite scroll). `null` state
  /// means "no page fetched yet for this month" — the page calls
  /// [loadFirstPage] on open and on every month switch, so this always gets
  /// populated before [loadNextPage] can be called meaningfully.

  TransactionsFeedSyncProvider call(int year, int month) =>
      TransactionsFeedSyncProvider._(argument: (year, month), from: this);

  @override
  String toString() => r'transactionsFeedSyncProvider';
}

/// Drives the paged API sync for one month (mirrors `AccountsRefresh`'s
/// "state signals loading/error, caller also gets an Either back" shape,
/// extended with page-progress payload for infinite scroll). `null` state
/// means "no page fetched yet for this month" — the page calls
/// [loadFirstPage] on open and on every month switch, so this always gets
/// populated before [loadNextPage] can be called meaningfully.

abstract class _$TransactionsFeedSync extends $Notifier<TransactionsFeedMeta?> {
  late final _$args = ref.$arg as (int, int);
  int get year => _$args.$1;
  int get month => _$args.$2;

  TransactionsFeedMeta? build(int year, int month);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TransactionsFeedMeta?, TransactionsFeedMeta?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TransactionsFeedMeta?, TransactionsFeedMeta?>,
              TransactionsFeedMeta?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

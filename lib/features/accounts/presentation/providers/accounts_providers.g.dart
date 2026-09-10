// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounts_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(activeAccounts)
final activeAccountsProvider = ActiveAccountsProvider._();

final class ActiveAccountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Account>>,
          List<Account>,
          Stream<List<Account>>
        >
    with $FutureModifier<List<Account>>, $StreamProvider<List<Account>> {
  ActiveAccountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeAccountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeAccountsHash();

  @$internal
  @override
  $StreamProviderElement<List<Account>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Account>> create(Ref ref) {
    return activeAccounts(ref);
  }
}

String _$activeAccountsHash() => r'e082465d9192e6a6abba7691706dfb5f875442bd';

@ProviderFor(cachedAccount)
final cachedAccountProvider = CachedAccountFamily._();

final class CachedAccountProvider
    extends
        $FunctionalProvider<AsyncValue<Account?>, Account?, Stream<Account?>>
    with $FutureModifier<Account?>, $StreamProvider<Account?> {
  CachedAccountProvider._({
    required CachedAccountFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'cachedAccountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cachedAccountHash();

  @override
  String toString() {
    return r'cachedAccountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Account?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Account?> create(Ref ref) {
    final argument = this.argument as int;
    return cachedAccount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CachedAccountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cachedAccountHash() => r'c4dd31b6385bfcdd3f18358891880a0897f7eb8c';

final class CachedAccountFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Account?>, int> {
  CachedAccountFamily._()
    : super(
        retry: null,
        name: r'cachedAccountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CachedAccountProvider call(int id) =>
      CachedAccountProvider._(argument: id, from: this);

  @override
  String toString() => r'cachedAccountProvider';
}

/// Drives the pull-to-refresh / initial-load API sync. The list itself is
/// always sourced from [activeAccountsProvider]'s drift watch, so a
/// successful refresh here shows up there automatically once it upserts.

@ProviderFor(AccountsRefresh)
final accountsRefreshProvider = AccountsRefreshProvider._();

/// Drives the pull-to-refresh / initial-load API sync. The list itself is
/// always sourced from [activeAccountsProvider]'s drift watch, so a
/// successful refresh here shows up there automatically once it upserts.
final class AccountsRefreshProvider
    extends $AsyncNotifierProvider<AccountsRefresh, void> {
  /// Drives the pull-to-refresh / initial-load API sync. The list itself is
  /// always sourced from [activeAccountsProvider]'s drift watch, so a
  /// successful refresh here shows up there automatically once it upserts.
  AccountsRefreshProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountsRefreshProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountsRefreshHash();

  @$internal
  @override
  AccountsRefresh create() => AccountsRefresh();
}

String _$accountsRefreshHash() => r'c833874ee4095c4fd7a7eb198ad6165f1bd2ca87';

/// Drives the pull-to-refresh / initial-load API sync. The list itself is
/// always sourced from [activeAccountsProvider]'s drift watch, so a
/// successful refresh here shows up there automatically once it upserts.

abstract class _$AccountsRefresh extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_actions_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Same wrap-the-repository-stream convention as `activeAccountsProvider`/
/// `allCategoriesProvider` — backs both `PendingActionsPage`'s list and
/// `TransactionsPage`'s AppBar badge count off one drift `.watch()`.

@ProviderFor(pendingActions)
final pendingActionsProvider = PendingActionsProvider._();

/// Same wrap-the-repository-stream convention as `activeAccountsProvider`/
/// `allCategoriesProvider` — backs both `PendingActionsPage`'s list and
/// `TransactionsPage`'s AppBar badge count off one drift `.watch()`.

final class PendingActionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PendingAction>>,
          List<PendingAction>,
          Stream<List<PendingAction>>
        >
    with
        $FutureModifier<List<PendingAction>>,
        $StreamProvider<List<PendingAction>> {
  /// Same wrap-the-repository-stream convention as `activeAccountsProvider`/
  /// `allCategoriesProvider` — backs both `PendingActionsPage`'s list and
  /// `TransactionsPage`'s AppBar badge count off one drift `.watch()`.
  PendingActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingActionsHash();

  @$internal
  @override
  $StreamProviderElement<List<PendingAction>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<PendingAction>> create(Ref ref) {
    return pendingActions(ref);
  }
}

String _$pendingActionsHash() => r'dd177c08989738b01012d745e01dd02b8ddc38ce';

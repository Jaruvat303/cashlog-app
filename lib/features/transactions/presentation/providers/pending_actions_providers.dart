import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/pending_actions_repository.dart';
import '../../domain/pending_action.dart';

part 'pending_actions_providers.g.dart';

/// Same wrap-the-repository-stream convention as `activeAccountsProvider`/
/// `allCategoriesProvider` — backs both `PendingActionsPage`'s list and
/// `TransactionsPage`'s AppBar badge count off one drift `.watch()`.
@riverpod
Stream<List<PendingAction>> pendingActions(Ref ref) => ref.watch(pendingActionsRepositoryProvider).watchAll();

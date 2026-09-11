import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/accounts_providers.dart';

/// BR-7: current_balance is always a client-side estimate derived from
/// locally cached transactions, never a backend-confirmed figure — this
/// disclaimer must sit next to every balance shown, with no exceptions.
const currentBalanceDisclaimer = 'Estimated from recorded data';

/// Renders one account's current_balance (see
/// `AccountsRepository.watchCurrentBalance`) plus its mandatory disclaimer.
/// Used on both the accounts list (one per row) and the account detail
/// screen so the disclaimer never appears without the balance it qualifies.
class CurrentBalanceText extends ConsumerWidget {
  const CurrentBalanceText({super.key, required this.accountId, this.style});

  final int accountId;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(accountCurrentBalanceProvider(accountId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        balanceAsync.when(
          loading: () => const Text('Calculating balance…'),
          error: (error, _) => const Text('Balance unavailable'),
          data: (balance) => Text(balance.toStringAsFixed(2), style: style),
        ),
        Text(currentBalanceDisclaimer, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

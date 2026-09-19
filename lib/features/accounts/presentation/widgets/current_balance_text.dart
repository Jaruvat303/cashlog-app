import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/format/money.dart';
import '../providers/accounts_providers.dart';

/// BR-7: current_balance is always a client-side estimate derived from
/// locally cached transactions, never a backend-confirmed figure — this
/// disclaimer must sit next to every balance shown, with no exceptions.
const currentBalanceDisclaimer = 'ประมาณการจากรายการที่บันทึกไว้';

/// Renders one account's current_balance (see
/// `AccountsRepository.watchCurrentBalance`) plus a subtitle line — the
/// mandatory BR-7 disclaimer by default, everywhere this widget is used
/// without overriding it. [subtitle]/[subtitleStyle] let one specific caller
/// swap that line for something else (post-launch UI polish ticket 03:
/// Summary's Account Card shows the account's `matching_keywords` instead,
/// in white, per that screen's own mockup decision) without changing the
/// disclaimer everywhere else this widget renders. [showSubtitle] lets
/// another caller (ticket 05: the Accounts list rows) drop the subtitle line
/// entirely, same reasoning — a per-screen mockup decision, not a change to
/// what every other caller still shows.
class CurrentBalanceText extends ConsumerWidget {
  const CurrentBalanceText({super.key, required this.accountId, this.style, this.subtitle, this.subtitleStyle, this.showSubtitle = true});

  final int accountId;
  final TextStyle? style;
  final String? subtitle;
  final TextStyle? subtitleStyle;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(accountCurrentBalanceProvider(accountId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        balanceAsync.when(
          loading: () => const Text('กำลังคำนวณยอดคงเหลือ…'),
          error: (error, _) => const Text('ไม่สามารถแสดงยอดคงเหลือ'),
          data: (balance) => Text(formatAmount(balance), style: style),
        ),
        if (showSubtitle) Text(subtitle ?? currentBalanceDisclaimer, style: subtitleStyle ?? Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

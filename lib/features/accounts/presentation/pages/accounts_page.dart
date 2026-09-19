import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/format/money.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/gradient_hero_card.dart';
import '../../domain/account.dart';
import '../providers/accounts_providers.dart';
import '../widgets/bank_icon_avatar.dart';
import '../widgets/current_balance_text.dart';
import 'account_detail_page.dart';
import 'account_form_page.dart';

/// Not one of the mockup's 6 named screens, but reachable from the same
/// AppShell nav bar as Dashboard/Transactions — restyled to the app's new
/// visual language (gradient hero, cards, brand colors) for consistency,
/// same design-system tokens as everywhere else.
class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {
  @override
  void initState() {
    super.initState();
    // Cache paints first via activeAccountsProvider's drift watch; this
    // kicks off the API sync that keeps it fresh (CLAUDE.md: online-only +
    // read cache). Silent: nobody asked for this one, so a failure (e.g.
    // offline on app open) shouldn't interrupt with a SnackBar — the cached
    // list is already on screen either way.
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh(showErrorSnackBar: false));
  }

  Future<void> _refresh({bool showErrorSnackBar = true}) async {
    final result = await ref.read(accountsRefreshProvider.notifier).refresh();
    if (!mounted || !showErrorSnackBar) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message ?? 'รีเฟรชบัญชีไม่สำเร็จ'))),
      (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(activeAccountsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('บัญชี', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  CircularIconButton(
                    icon: RemixIcon.addLine,
                    gradient: AppColors.accentGradient,
                    iconColor: Colors.white,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountFormPage())),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: accountsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('โหลดบัญชีไม่สำเร็จ: $error')),
                  data: (accounts) {
                    if (accounts.isEmpty) {
                      return ListView(
                        children: const [
                          Padding(padding: EdgeInsets.all(32), child: Center(child: Text('ยังไม่มีบัญชี — แตะ + เพื่อเพิ่มบัญชี'))),
                        ],
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                      children: [
                        _NetWorthHero(accounts: accounts),
                        const SizedBox(height: 20),
                        const Text('บัญชีทั้งหมด', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                        const SizedBox(height: 10),
                        for (final account in accounts) ...[
                          _AccountRow(account: account),
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sums each account's already-loaded [accountCurrentBalanceProvider] value
/// (client-side estimate, same disclaimer as everywhere else) — no new
/// backend call, just an aggregate over data the list already fetches.
class _NetWorthHero extends ConsumerWidget {
  const _NetWorthHero({required this.accounts});

  final List<Account> accounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var assets = 0.0;
    var debts = 0.0;
    for (final account in accounts) {
      final balance = ref.watch(accountCurrentBalanceProvider(account.id)).value ?? 0;
      if (balance < 0) {
        debts += -balance;
      } else {
        assets += balance;
      }
    }

    return GradientHeroCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('สินทรัพย์รวมทั้งหมด', style: TextStyle(fontSize: 13, color: Color(0xD9FFFFFF))),
          const SizedBox(height: 6),
          Text(formatAmount(assets - debts), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.card),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AccountDetailPage(accountId: account.id))),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.card), boxShadow: const [AppShadows.card]),
        child: Row(
          children: [
            BankIconAvatar(bankIconCode: account.bankIcon, radius: 21),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(account.accountType.label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            CurrentBalanceText(
              accountId: account.id,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
              // Post-launch UI polish ticket 05: no subtitle placeholder text
              // on this row at all — just the balance figure itself.
              showSubtitle: false,
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }
}

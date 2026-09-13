import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/account.dart';
import '../providers/accounts_providers.dart';
import '../widgets/bank_icon_avatar.dart';
import '../widgets/current_balance_text.dart';
import 'account_detail_page.dart';
import 'account_form_page.dart';

/// Not one of the mockup's 6 named screens, but reachable from the same
/// AppShell nav bar as Dashboard/Transactions — restyled to the app's new
/// visual language (cards, rounded corners, brand colors) for consistency,
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
      appBar: AppBar(title: const Text('บัญชี')),
      body: RefreshIndicator(
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
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: accounts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final account = accounts[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AccountDetailPage(accountId: account.id))),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        BankIconAvatar(bankIconCode: account.bankIcon, radius: 22),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(account.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  ),
                                  const SizedBox(width: 8),
                                  _typeTag(account.accountType),
                                ],
                              ),
                              const SizedBox(height: 6),
                              CurrentBalanceText(accountId: account.id, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 19)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textFaint),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountFormPage())),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _typeTag(AccountType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: AppColors.screenBackground, borderRadius: BorderRadius.circular(6)),
      child: Text(type.label, style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary)),
    );
  }
}

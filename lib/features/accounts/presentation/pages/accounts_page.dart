import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/account.dart';
import '../providers/accounts_providers.dart';
import '../widgets/bank_icon_avatar.dart';
import '../widgets/current_balance_text.dart';
import 'account_detail_page.dart';
import 'account_form_page.dart';

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
      ).showSnackBar(SnackBar(content: Text(failure.message ?? 'Could not refresh accounts'))),
      (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(activeAccountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: accountsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Failed to load accounts: $error')),
          data: (accounts) {
            if (accounts.isEmpty) {
              return ListView(
                children: const [
                  Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No accounts yet — tap + to add one'))),
                ],
              );
            }
            return ListView.builder(
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];
                return ListTile(
                  leading: BankIconAvatar(bankIconCode: account.bankIcon),
                  title: Text(account.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(account.accountType.label),
                      CurrentBalanceText(accountId: account.id),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AccountDetailPage(accountId: account.id))),
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
}

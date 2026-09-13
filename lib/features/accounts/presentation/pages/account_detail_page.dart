import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/accounts_repository.dart';
import '../../domain/account.dart';
import '../../domain/bank_icon.dart';
import '../providers/accounts_providers.dart';
import '../widgets/bank_icon_avatar.dart';
import '../widgets/current_balance_text.dart';
import 'account_form_page.dart';

/// Reads `cached_accounts` directly — there is no `GET /accounts/:id` to
/// call (spec §12.1), and the list response already carries every field
/// this screen needs.
class AccountDetailPage extends ConsumerWidget {
  const AccountDetailPage({super.key, required this.accountId});

  final int accountId;

  Future<void> _confirmClose(BuildContext context, WidgetRef ref, Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ปิดบัญชีนี้ใช่ไหม'),
        content: const Text('บัญชีนี้จะไม่แสดงในรายการบัญชีอีกต่อไป ธุรกรรมเดิมยังคงอยู่และแสดงบัญชีนี้เหมือนเดิม'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('ปิดบัญชี')),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await ref.read(accountsRepositoryProvider).close(account.id);
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message ?? 'ทำรายการไม่สำเร็จ ลองใหม่อีกครั้ง'))),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ปิดบัญชีแล้ว')));
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(cachedAccountProvider(accountId));

    return Scaffold(
      appBar: AppBar(title: const Text('บัญชี')),
      body: accountAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('โหลดไม่สำเร็จ: $error')),
        data: (account) {
          if (account == null) return const Center(child: Text('ไม่พบบัญชีนี้'));

          final bankIcon = resolveBankIcon(account.bankIcon);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  BankIconAvatar(bankIconCode: account.bankIcon, radius: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(account.name, style: Theme.of(context).textTheme.titleLarge),
                        Text(bankIcon.label, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  if (!account.isActive)
                    const Padding(padding: EdgeInsets.only(left: 8), child: Chip(label: Text('ปิดแล้ว'))),
                ],
              ),
              const Divider(height: 32),
              ListTile(
                title: const Text('ยอดคงเหลือปัจจุบัน'),
                subtitle: CurrentBalanceText(accountId: account.id),
              ),
              ListTile(title: const Text('ประเภท'), subtitle: Text(account.accountType.label)),
              ListTile(title: const Text('ยอดเปิดบัญชี'), subtitle: Text(account.openingBalance.toStringAsFixed(2))),
              ListTile(
                title: const Text('คำค้นหาที่ใช้จับคู่'),
                subtitle: Text(account.matchingKeywords.isEmpty ? '—' : account.matchingKeywords.join(', ')),
              ),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => AccountFormPage(initial: account))),
                child: const Text('แก้ไข'),
              ),
              if (account.isActive) ...[
                const SizedBox(height: 8),
                OutlinedButton(onPressed: () => _confirmClose(context, ref, account), child: const Text('ปิดบัญชี')),
              ],
            ],
          );
        },
      ),
    );
  }
}

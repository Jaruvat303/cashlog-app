import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/gradient_hero_card.dart';
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
      body: SafeArea(
        child: accountAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('โหลดไม่สำเร็จ: $error')),
          data: (account) {
            if (account == null) {
              return const Center(child: Text('ไม่พบบัญชีนี้'));
            }

            final bankIcon = resolveBankIcon(account.bankIcon);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircularIconButton(icon: RemixIcon.arrowLeftLine, onTap: () => Navigator.of(context).pop()),
                      Expanded(
                        child: Text(
                          account.name,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 38, height: 38),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                    children: [
                      GradientHeroCard(
                        gradient: const LinearGradient(colors: [AppColors.accentB, Color(0xFF6D28D9)]),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                BankIconAvatar(bankIconCode: account.bankIcon, radius: 12),
                                const SizedBox(width: 8),
                                Text(bankIcon.label, style: const TextStyle(fontSize: 13, color: Color(0xD9FFFFFF))),
                                if (!account.isActive) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                                    child: const Text('ปิดแล้ว', style: TextStyle(fontSize: 11, color: Colors.white)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            CurrentBalanceText(
                              accountId: account.id,
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
                              subtitleStyle: const TextStyle(fontSize: 13, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionPill(
                              icon: RemixIcon.editLine,
                              label: 'แก้ไขบัญชี',
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AccountFormPage(initial: account))),
                            ),
                          ),
                          if (account.isActive) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ActionPill(
                                icon: RemixIcon.deleteBinLine,
                                label: 'ปิดบัญชี',
                                color: AppColors.expense,
                                onTap: () => _confirmClose(context, ref, account),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.cardLarge), boxShadow: const [AppShadows.card]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoRow(label: 'ประเภท', value: account.accountType.label),
                            const Divider(height: 20, color: AppColors.divider),
                            _InfoRow(label: 'ยอดเปิดบัญชี', value: account.openingBalance.toStringAsFixed(2)),
                            const Divider(height: 20, color: AppColors.divider),
                            _InfoRow(
                              label: 'คำค้นหาที่ใช้จับคู่',
                              value: account.matchingKeywords.isEmpty ? '—' : account.matchingKeywords.join(', '),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.icon, required this.label, required this.onTap, this.color = AppColors.textPrimary});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.control),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.control), boxShadow: const [AppShadows.card]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

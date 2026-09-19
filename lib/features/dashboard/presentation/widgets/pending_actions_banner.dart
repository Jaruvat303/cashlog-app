import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../transactions/presentation/pages/pending_actions_page.dart';
import '../../../transactions/presentation/providers/pending_actions_providers.dart';

/// Ticket 08: reuses `pendingActionsProvider` and `PendingActionsPage`
/// verbatim — the same drift-backed retry-queue stream and screen
/// `TransactionsPage`'s own AppBar icon+badge already point at (spec:
/// "showing the count from the existing pending-actions query ... tapping it
/// opens the existing pending-actions page"). No second query, no new page.
///
/// Zero-count follows this page's sibling `_GalleryPermissionBanner`
/// precedent — collapse to nothing rather than show a dead "0" banner —
/// since a full-width banner left on screen with nothing actionable in it is
/// exactly the "dead space" the spec calls out, unlike the AppBar badge's
/// `isLabelVisible` toggle (there, the icon itself stays as a useful
/// permanent affordance even with no badge).
class PendingActionsBanner extends ConsumerWidget {
  const PendingActionsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingActionsProvider).value?.length ?? 0;
    if (pendingCount == 0) return const SizedBox.shrink();

    return InkWell(
      key: const Key('pendingActionsBanner'),
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PendingActionsPage())),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.warningIconBg,
          border: Border.all(color: AppColors.warningBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(RemixIcon.errorWarningLine, size: 18, color: AppColors.warningIcon),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                key: const Key('pendingActionsBannerText'),
                'มีรายการค้างอยู่ $pendingCount รายการ — แตะเพื่อดำเนินการ',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(RemixIcon.arrowRightSLine, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

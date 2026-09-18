import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/format/datetime.dart';
import '../../../slip_scan/presentation/providers/auto_scan_status_provider.dart';

/// Ticket 09: a plain, always-visible readout of when the *background*
/// auto-scan pipeline last actually uploaded a new slip — spec: "so that I
/// can tell at a glance whether the background scanning pipeline is still
/// working." Backed by [lastAutoScanUploadProvider], itself a thin reactive
/// read over `scanned_slips` (see
/// `SlipUploadRepository.watchLastSuccessfulAutoScanUpload`'s doc comment
/// for why T21's manual gallery/camera attach is excluded) — no new success
/// signal, this only surfaces the one the upload pipeline already records on
/// every real upload. If auto-scan keeps finding nothing new, no row is
/// written, so this text stays fixed at its last real success — a stale
/// value is the intended failure signal, not a bug.
class AutoScanStatusText extends ConsumerWidget {
  const AutoScanStatusText({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastUpload = ref.watch(lastAutoScanUploadProvider).value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        key: const Key('lastAutoScanUploadText'),
        lastUpload == null ? 'ยังไม่มีการอัปโหลดสลิปอัตโนมัติ' : 'สแกนสลิปอัตโนมัติล่าสุด: ${dateTimeLabel(lastUpload)}',
        style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
      ),
    );
  }
}

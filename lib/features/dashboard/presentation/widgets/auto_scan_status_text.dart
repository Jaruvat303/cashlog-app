import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/format/datetime.dart';
import '../../../slip_scan/presentation/providers/auto_scan_status_provider.dart';

/// A plain, always-visible readout of when the *background* auto-scan
/// pipeline last actually uploaded a new slip — spec: "so that I can tell at
/// a glance whether the background scanning pipeline is still working."
/// Backed by [lastAutoScanUploadProvider], itself a thin reactive read over
/// `scanned_slips` (see
/// `SlipUploadRepository.watchLastSuccessfulAutoScanUpload`'s doc comment for
/// why T21's manual gallery/camera attach is excluded) — no new success
/// signal, this only surfaces the one the upload pipeline already records on
/// every real upload. If auto-scan keeps finding nothing new, no row is
/// written, so this text stays fixed at its last real success — a stale
/// value is the intended failure signal, not a bug.
///
/// Post-launch UI polish ticket 02: lives inside [ExpenseTotalWidget]'s
/// gradient banner now (previously its own row directly beneath it on
/// `DashboardPage`) — same provider, same fallback, just relocated and
/// shortened to fit the banner (mockup: "สแกนสลิปล่าสุด" not "สแกนสลิปอัตโนมัติ
/// ล่าสุด"), with the color adjusted to read on the gradient instead of the
/// plain page background.
class AutoScanStatusText extends ConsumerWidget {
  const AutoScanStatusText({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastUpload = ref.watch(lastAutoScanUploadProvider).value;
    return Text(
      key: const Key('lastAutoScanUploadText'),
      lastUpload == null ? 'ยังไม่มีการสแกนสลิป' : 'สแกนสลิปล่าสุด: ${dateTimeLabel(lastUpload)}',
      style: const TextStyle(fontSize: 11.5, color: Color(0xD9FFFFFF)),
    );
  }
}

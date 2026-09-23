import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../slip_scan/presentation/providers/slip_scan_pipeline_provider.dart';

part 'auto_scan_processing_indicator.g.dart';

/// Ticket 10: "a few seconds" per spec — kept as an overridable provider
/// (not a bare constant) so tests can shrink it, same reasoning as
/// [kSlipUploadDelay]'s default-parameter override, just expressed as a
/// provider since this value is read from a widget's `State`, not passed
/// down a call chain.
@riverpod
Duration autoScanCompletionHoldDuration(Ref ref) => const Duration(seconds: 3);

/// Ticket 10: a pure reader of [SlipScanPipeline]'s existing
/// [SlipScanProgress] — no new progress-tracking mechanism, per the spec's
/// "reuse the existing slip-scan-progress state" instruction. Covers both
/// channels that state already serializes against each other (T21):
/// `isScanning` for a background auto-scan batch, and `isManualUploading`
/// for a ticket-05 FAB gallery/camera attach — the same indicator responds
/// to either, since both go through this one state object.
///
/// While busy, shows a live progress readout. The moment a batch/attach
/// finishes (busy → idle), it holds a brief "N done" state on screen for
/// [autoScanCompletionHoldDurationProvider] before clearing, so the user
/// gets confirmation the batch actually completed rather than the row just
/// vanishing — spec: "briefly show a completion state ... before
/// disappearing." An auto-scan cycle that finds zero new files never shows a
/// completion flash (nothing was actually processed); a manual attach
/// always does, since it's always exactly one deliberate user action.
class AutoScanProcessingIndicator extends ConsumerStatefulWidget {
  const AutoScanProcessingIndicator({super.key});

  @override
  ConsumerState<AutoScanProcessingIndicator> createState() => _AutoScanProcessingIndicatorState();
}

class _AutoScanProcessingIndicatorState extends ConsumerState<AutoScanProcessingIndicator> {
  Timer? _holdTimer;
  int? _completionCount;

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _onProgressChanged(SlipScanProgress? previous, SlipScanProgress next) {
    final wasBusy = (previous?.isScanning ?? false) || (previous?.isManualUploading ?? false);
    final stillBusy = next.isScanning || next.isManualUploading;

    if (stillBusy) {
      // A new batch/attach started while a completion flash from the
      // previous one was still on screen — the new activity takes over.
      if (_completionCount != null) {
        _holdTimer?.cancel();
        setState(() => _completionCount = null);
      }
      return;
    }

    if (!wasBusy) {
      return; // idle → idle, e.g. an unrelated `accessLevel` update.
    }

    final completedCount = previous!.isScanning && next.completed > 0
        ? next.completed
        : previous.isManualUploading
        ? 1
        : 0;
    if (completedCount == 0) {
      return; // an empty scan cycle found nothing to report.
    }

    _holdTimer?.cancel();
    setState(() => _completionCount = completedCount);
    _holdTimer = Timer(ref.read(autoScanCompletionHoldDurationProvider), () {
      if (mounted) setState(() => _completionCount = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SlipScanProgress>(slipScanPipelineProvider, _onProgressChanged);
    final progress = ref.watch(slipScanPipelineProvider);
    final isBusy = progress.isScanning || progress.isManualUploading;

    if (!isBusy && _completionCount == null) return const SizedBox.shrink();

    final String label;
    if (isBusy) {
      if (progress.isScanning) {
        label = progress.total > 0 ? 'กำลังประมวลผลสลิป ${progress.completed}/${progress.total}' : 'กำลังตรวจสอบสลิปใหม่...';
      } else {
        label = 'กำลังอัปโหลดสลิป...';
      }
    } else {
      label = 'เสร็จสิ้น $_completionCount รายการ';
    }

    return Container(
      key: const Key('autoScanProcessingIndicator'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        border: Border.all(color: AppColors.primarySurfaceBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          if (isBusy)
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
          else
            const Icon(RemixIcon.checkboxCircleFill, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              key: const Key('autoScanProcessingIndicatorText'),
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.primaryText),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

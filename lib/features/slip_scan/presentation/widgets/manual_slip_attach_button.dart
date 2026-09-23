import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../transactions/presentation/pages/add_transaction_page.dart';
import '../../domain/slip_upload_outcome.dart';
import '../providers/slip_scan_pipeline_provider.dart';

part 'manual_slip_attach_button.g.dart';

/// Ticket 05: the FAB's speed-dial now offers a third choice that isn't an
/// [ImageSource] at all, so it resolves this instead of `ImageSource?`
/// directly.
enum _AttachChoice { createManually, gallery, camera }

/// Thin wrapper around `image_picker`'s `ImagePicker` — same reasoning as
/// `SlipGalleryRepository` wrapping `photo_manager` (T9): an injection point
/// so tests can supply canned `XFile`s instead of touching `image_picker`'s
/// real platform channel, which doesn't exist under plain `flutter test`
/// (CLAUDE.md's testing rule).
abstract class ManualSlipImageSource {
  Future<XFile?> pickImage(ImageSource source);
}

class _RealManualSlipImageSource implements ManualSlipImageSource {
  final _picker = ImagePicker();

  @override
  Future<XFile?> pickImage(ImageSource source) =>
      _picker.pickImage(source: source);
}

@riverpod
ManualSlipImageSource manualSlipImageSource(Ref ref) =>
    _RealManualSlipImageSource();

/// Ticket 05's global create FAB — the mockup's speed-dial: tapping it raises
/// a translucent backdrop plus 3 stacked pill options (create manually /
/// gallery / scan slip) above the FAB, reachable from every tab. Manual entry
/// pushes [AddTransactionPage]; gallery/camera keep feeding the exact same
/// `SlipScanPipeline.uploadManual` → `SlipUploadRepository.uploadManual` →
/// `POST /upload-slip` pipeline T10 built, unchanged — the pipeline itself
/// (not this widget) serializes that against any in-progress auto-scan batch.
class ManualSlipAttachButton extends ConsumerWidget {
  const ManualSlipAttachButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBusy = ref.watch(
      slipScanPipelineProvider.select((s) => s.isManualUploading),
    );

    return FloatingActionButton(
      key: const Key('manualSlipAttachButton'),
      tooltip: 'เพิ่มรายการ',
      elevation: 0,
      shape: const CircleBorder(),
      backgroundColor: Colors.transparent,
      onPressed: isBusy ? null : () => _attach(context, ref),
      child: Container(
        width: 58,
        height: 58,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.accentGradient,
          boxShadow: [AppShadows.accent],
        ),
        child: isBusy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(RemixIcon.addLine, color: Colors.white, size: 26),
      ),
    );
  }

  Future<void> _attach(BuildContext context, WidgetRef ref) async {
    final choice = await _showSpeedDial(context);
    if (choice == null || !context.mounted) return;

    if (choice == _AttachChoice.createManually) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const AddTransactionPage()));
      return;
    }

    final source = choice == _AttachChoice.camera
        ? ImageSource.camera
        : ImageSource.gallery;
    final file = await ref
        .read(manualSlipImageSourceProvider)
        .pickImage(source);
    if (file == null || !context.mounted) return;

    final bytes = await file.readAsBytes();
    if (!context.mounted) return;

    final result = await ref
        .read(slipScanPipelineProvider.notifier)
        .uploadManual(bytes: bytes, filename: file.name);
    if (!context.mounted) return;

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message ?? 'อัปโหลดสลิปไม่สำเร็จ')),
      ),
      (outcome) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            outcome is SlipUploaded
                ? 'อัปโหลดสลิปแล้ว'
                : 'สลิปนี้ถูกประมวลผลไปแล้ว',
          ),
        ),
      ),
    );
  }

  Future<_AttachChoice?> _showSpeedDial(BuildContext context) {
    return showGeneralDialog<_AttachChoice>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      barrierLabel: 'ปิด',
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Stack(
          children: [
            FadeTransition(
              opacity: animation,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: Container(color: const Color(0x521A1D29)),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 96,
              child: FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: _SpeedDialOptions(
                    onPicked: (choice) => Navigator.of(context).pop(choice),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SpeedDialOptions extends StatelessWidget {
  const _SpeedDialOptions({required this.onPicked});

  final ValueChanged<_AttachChoice> onPicked;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _pill(
          key: 'manualSlipAttachCameraOption',
          icon: RemixIcon.cameraLine,
          label: 'ถ่ายภาพสลิป',
          gradient: true,
          onTap: () => onPicked(_AttachChoice.camera),
        ),
        const SizedBox(height: 10),
        _pill(
          key: 'manualSlipAttachGalleryOption',
          icon: RemixIcon.imageLine,
          label: 'เลือกจากคลังภาพ',
          onTap: () => onPicked(_AttachChoice.gallery),
        ),
        const SizedBox(height: 10),
        _pill(
          key: 'manualSlipAttachCreateManuallyOption',
          icon: RemixIcon.editLine,
          label: 'บันทึกเอง',
          onTap: () => onPicked(_AttachChoice.createManually),
        ),
      ],
    );
  }

  Widget _pill({
    required String key,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool gradient = false,
  }) {
    return Material(
      key: Key(key),
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: gradient ? null : AppColors.surface,
            gradient: gradient ? AppColors.accentGradient : null,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [AppShadows.card],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: gradient ? Colors.white : AppColors.textPrimary,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: gradient ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

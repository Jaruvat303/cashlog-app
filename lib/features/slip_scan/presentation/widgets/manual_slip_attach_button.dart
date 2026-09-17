import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../transactions/presentation/pages/transaction_form_page.dart';
import '../../domain/slip_upload_outcome.dart';
import '../providers/slip_scan_pipeline_provider.dart';

part 'manual_slip_attach_button.g.dart';

/// Ticket 05: the FAB's bottom sheet now offers a third choice that isn't an
/// [ImageSource] at all, so the sheet returns this instead of `ImageSource?`
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
  Future<XFile?> pickImage(ImageSource source) => _picker.pickImage(source: source);
}

@riverpod
ManualSlipImageSource manualSlipImageSource(Ref ref) => _RealManualSlipImageSource();

/// Ticket 05's global create FAB — the mockup's raised center button on the
/// bottom nav (see `app_shell.dart`), reachable from every tab rather than
/// only the Transactions feed. Opens a 3-way choice: manual entry pushes the
/// existing `TransactionFormPage` directly (untouched); gallery/camera keep
/// feeding the exact same `SlipScanPipeline.uploadManual` →
/// `SlipUploadRepository.uploadManual` → `POST /upload-slip` pipeline T10
/// built, unchanged — the pipeline itself (not this widget) serializes that
/// against any in-progress auto-scan batch.
class ManualSlipAttachButton extends ConsumerWidget {
  const ManualSlipAttachButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBusy = ref.watch(slipScanPipelineProvider.select((s) => s.isManualUploading));

    return FloatingActionButton(
      key: const Key('manualSlipAttachButton'),
      tooltip: 'เพิ่มรายการ',
      backgroundColor: AppColors.primary,
      elevation: 8,
      shape: const CircleBorder(),
      onPressed: isBusy ? null : () => _attach(context, ref),
      child: isBusy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(RemixIcon.addLine, color: Colors.white, size: 25),
    );
  }

  Future<void> _attach(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<_AttachChoice>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('manualSlipAttachCreateManuallyOption'),
              leading: const Icon(RemixIcon.editLine),
              title: const Text('สร้างรายการเอง'),
              onTap: () => Navigator.of(context).pop(_AttachChoice.createManually),
            ),
            ListTile(
              key: const Key('manualSlipAttachGalleryOption'),
              leading: const Icon(RemixIcon.imageLine),
              title: const Text('เลือกจากคลังภาพ'),
              onTap: () => Navigator.of(context).pop(_AttachChoice.gallery),
            ),
            ListTile(
              key: const Key('manualSlipAttachCameraOption'),
              leading: const Icon(RemixIcon.cameraLine),
              title: const Text('ถ่ายรูป'),
              onTap: () => Navigator.of(context).pop(_AttachChoice.camera),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;

    if (choice == _AttachChoice.createManually) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TransactionFormPage()));
      return;
    }

    final source = choice == _AttachChoice.camera ? ImageSource.camera : ImageSource.gallery;
    final file = await ref.read(manualSlipImageSourceProvider).pickImage(source);
    if (file == null || !context.mounted) return;

    final bytes = await file.readAsBytes();
    if (!context.mounted) return;

    final result = await ref.read(slipScanPipelineProvider.notifier).uploadManual(bytes: bytes, filename: file.name);
    if (!context.mounted) return;

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message ?? 'อัปโหลดสลิปไม่สำเร็จ'))),
      (outcome) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(outcome is SlipUploaded ? 'อัปโหลดสลิปแล้ว' : 'สลิปนี้ถูกประมวลผลไปแล้ว'))),
    );
  }
}

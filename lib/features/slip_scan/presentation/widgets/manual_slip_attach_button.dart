import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/slip_upload_outcome.dart';
import '../providers/slip_scan_pipeline_provider.dart';

part 'manual_slip_attach_button.g.dart';

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

/// T21/spec §7.1's manual-attach entry point — the mockup's raised center
/// camera button on the bottom nav (see `app_shell.dart`), reachable from
/// every tab rather than only the Transactions feed. Feeds into the exact
/// same `SlipScanPipeline.uploadManual` → `SlipUploadRepository.uploadManual`
/// → `POST /upload-slip` pipeline T10 built; the pipeline itself (not this
/// widget) serializes this against any in-progress auto-scan batch.
class ManualSlipAttachButton extends ConsumerWidget {
  const ManualSlipAttachButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBusy = ref.watch(slipScanPipelineProvider.select((s) => s.isManualUploading));

    return FloatingActionButton(
      key: const Key('manualSlipAttachButton'),
      tooltip: 'สแกนสลิป',
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
          : const Icon(RemixIcon.cameraLine, color: Colors.white, size: 25),
    );
  }

  Future<void> _attach(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('manualSlipAttachCameraOption'),
              leading: const Icon(RemixIcon.cameraLine),
              title: const Text('ถ่ายรูป'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              key: const Key('manualSlipAttachGalleryOption'),
              leading: const Icon(RemixIcon.imageLine),
              title: const Text('เลือกจากคลังภาพ'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;

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

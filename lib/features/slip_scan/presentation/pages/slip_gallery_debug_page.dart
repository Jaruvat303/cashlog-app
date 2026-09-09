import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/gallery_access_level.dart';
import '../../domain/slip_candidate.dart';
import '../../domain/slip_source_albums.dart';
import '../providers/slip_gallery_debug_providers.dart';
import '../providers/slip_scan_pipeline_provider.dart';

/// T9's read-only gallery view (request permission, query
/// `kSlipSourceAlbums`, show matched filenames) plus T10's manual
/// "Scan & Upload" trigger — T10 has no dedicated screen of its own
/// (excluded: lifecycle wiring is T11's job), so the pipeline is exercised
/// from this existing debug page rather than a new one.
///
/// Real-device-only in practice: both `photo_manager` and the upload
/// pipeline's compression step go through platform channels, so a plain
/// `flutter test` run can only exercise this page's rendering against faked
/// repositories, never a real gallery query or upload — the DoDs (matches
/// what's really in both albums; a real slip produces a real transaction)
/// are verified by hand on a real Android 14 device.
class SlipGalleryDebugPage extends ConsumerStatefulWidget {
  const SlipGalleryDebugPage({super.key});

  @override
  ConsumerState<SlipGalleryDebugPage> createState() => _SlipGalleryDebugPageState();
}

class _SlipGalleryDebugPageState extends ConsumerState<SlipGalleryDebugPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(slipGalleryDebugControllerProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(slipGalleryDebugControllerProvider);
    final notifier = ref.read(slipGalleryDebugControllerProvider.notifier);
    final scanProgress = ref.watch(slipScanPipelineProvider);
    final scanNotifier = ref.read(slipScanPipelineProvider.notifier);

    final byAlbum = <String, List<SlipCandidate>>{
      for (final album in kSlipSourceAlbums) album: [for (final c in state.candidates) if (c.sourceAlbum == album) c],
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Slip Gallery Debug')),
      body: !state.hasLoaded
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: notifier.refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _AccessBanner(accessLevel: state.accessLevel, notifier: notifier),
                  const SizedBox(height: 16),
                  _ScanSection(progress: scanProgress, onScan: scanNotifier.runScan),
                  const SizedBox(height: 16),
                  Text('${state.candidates.length} file(s) across ${kSlipSourceAlbums.length} configured album(s)'),
                  const SizedBox(height: 16),
                  for (final album in kSlipSourceAlbums) _AlbumSection(albumName: album, files: byAlbum[album] ?? const []),
                ],
              ),
            ),
    );
  }
}

class _ScanSection extends StatelessWidget {
  const _ScanSection({required this.progress, required this.onScan});

  final SlipScanProgress progress;
  final Future<void> Function() onScan;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Scan & Upload', style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                FilledButton(
                  onPressed: progress.isScanning ? null : onScan,
                  child: Text(progress.isScanning ? 'Scanning…' : 'Scan now'),
                ),
              ],
            ),
            if (progress.isScanning) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: progress.total == 0 ? null : progress.completed / progress.total),
              const SizedBox(height: 8),
              Text('Uploading ${progress.completed + 1}/${progress.total}: ${progress.currentFilename ?? ''}'),
            ],
            if (!progress.isScanning && progress.results.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final result in progress.results)
                Text(
                  '[${_statusLabel(result.status)}] ${result.filename}${result.failureMessage != null ? ' — ${result.failureMessage}' : ''}',
                ),
            ],
            if (!progress.isScanning && progress.accessLevel == GalleryAccessLevel.denied) ...[
              const SizedBox(height: 12),
              const Text('No gallery access — grant access above before scanning.'),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(SlipUploadStatus status) => switch (status) {
    SlipUploadStatus.uploaded => 'uploaded',
    SlipUploadStatus.duplicate => 'duplicate',
    SlipUploadStatus.failed => 'failed',
  };
}

class _AccessBanner extends StatelessWidget {
  const _AccessBanner({required this.accessLevel, required this.notifier});

  final GalleryAccessLevel accessLevel;
  final SlipGalleryDebugController notifier;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (accessLevel) {
      GalleryAccessLevel.full => ('Full access', const Color(0xFF16A34A)),
      GalleryAccessLevel.limited => ('Limited access — some photos may be missing', const Color(0xFFD97706)),
      GalleryAccessLevel.denied => ('No access', const Color(0xFFDC2626)),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (accessLevel != GalleryAccessLevel.full)
                  OutlinedButton(onPressed: notifier.requestAccess, child: const Text('Grant access')),
                if (accessLevel == GalleryAccessLevel.limited)
                  OutlinedButton(onPressed: notifier.presentLimitedSelection, child: const Text('Select more photos')),
                if (accessLevel == GalleryAccessLevel.denied)
                  OutlinedButton(onPressed: notifier.openSettings, child: const Text('Open settings')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumSection extends StatelessWidget {
  const _AlbumSection({required this.albumName, required this.files});

  final String albumName;
  final List<SlipCandidate> files;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$albumName (${files.length})', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          if (files.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No files found in this album'))
          else
            for (final file in files) Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(file.filename)),
        ],
      ),
    );
  }
}

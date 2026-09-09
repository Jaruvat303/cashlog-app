import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/slip_gallery_repository.dart';
import '../../domain/gallery_access_level.dart';
import '../../domain/slip_candidate.dart';

part 'slip_gallery_debug_providers.g.dart';

class SlipGalleryDebugState {
  const SlipGalleryDebugState({required this.accessLevel, required this.candidates, required this.hasLoaded});

  final GalleryAccessLevel accessLevel;
  final List<SlipCandidate> candidates;

  /// `false` until the first [SlipGalleryDebugController.refresh] call
  /// completes — distinct from a mid-refresh state so a pull-to-refresh
  /// after the first load doesn't blank the screen back to a spinner (the
  /// last known list stays on screen while `RefreshIndicator` shows its own
  /// in-flight spinner).
  final bool hasLoaded;

  SlipGalleryDebugState copyWith({GalleryAccessLevel? accessLevel, List<SlipCandidate>? candidates, bool? hasLoaded}) =>
      SlipGalleryDebugState(
        accessLevel: accessLevel ?? this.accessLevel,
        candidates: candidates ?? this.candidates,
        hasLoaded: hasLoaded ?? this.hasLoaded,
      );
}

/// Debug-only controller (T9 excludes upload/compression/drift persistence
/// entirely — this never writes anything, it only drives
/// [SlipGalleryRepository]'s read-only `photo_manager` calls for the debug
/// screen). Not `Either<Failure, T>`-shaped — see
/// `gallery_access_level.dart` for why.
@riverpod
class SlipGalleryDebugController extends _$SlipGalleryDebugController {
  @override
  SlipGalleryDebugState build() =>
      const SlipGalleryDebugState(accessLevel: GalleryAccessLevel.denied, candidates: [], hasLoaded: false);

  /// Re-reads the current permission state (no system prompt) and, if
  /// there's any access at all, re-queries the configured albums. Called on
  /// page open and pull-to-refresh.
  Future<void> refresh() async {
    final repo = ref.read(slipGalleryRepositoryProvider);
    final access = await repo.currentAccess();
    await _loadFor(repo, access);
  }

  /// Triggers the system permission dialog, then loads with whatever access
  /// level the user granted.
  Future<void> requestAccess() async {
    final repo = ref.read(slipGalleryRepositoryProvider);
    final access = await repo.requestAccess();
    await _loadFor(repo, access);
  }

  /// Android 14's "select more photos" picker for a `limited` access level.
  Future<void> presentLimitedSelection() async {
    await ref.read(slipGalleryRepositoryProvider).presentLimitedSelection();
    await refresh();
  }

  Future<void> openSettings() => ref.read(slipGalleryRepositoryProvider).openSettings();

  Future<void> _loadFor(SlipGalleryRepository repo, GalleryAccessLevel access) async {
    if (access == GalleryAccessLevel.denied) {
      // Querying photo_manager with zero access either throws or returns
      // nothing meaningful — skip straight to an empty, denied state rather
      // than attempting it.
      if (ref.mounted) state = state.copyWith(accessLevel: access, candidates: const [], hasLoaded: true);
      return;
    }
    final candidates = await repo.queryConfiguredAlbums();
    // autoDispose: nothing keeps this alive across the awaits above (e.g.
    // the debug page being closed mid-query) — writing state after it's
    // gone throws, so bail per riverpod's own guidance (same reasoning as
    // TransactionsFeedSync).
    if (ref.mounted) state = state.copyWith(accessLevel: access, candidates: candidates, hasLoaded: true);
  }
}

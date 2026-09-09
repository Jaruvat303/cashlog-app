import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/gallery_access_level.dart';
import '../domain/slip_candidate.dart';
import '../domain/slip_source_albums.dart';

part 'slip_gallery_repository.g.dart';

/// Wraps `photo_manager` only — no drift, no network, no upload (T10's
/// scope). Every method here talks to the real Android gallery via a
/// platform channel, so none of it is meaningfully exercisable outside a
/// real device (this ticket's own DoD says as much).
class SlipGalleryRepository {
  /// Requests permission scoped to images only (`RequestType.image`,
  /// `mediaLocation: false`) rather than the plugin's `RequestType.common`
  /// default (images + video) — slip screenshots are always images, and
  /// there's no reason to ask for broader access than the feature needs.
  Future<GalleryAccessLevel> requestAccess() async {
    final state = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(type: RequestType.image, mediaLocation: false),
      ),
    );
    return galleryAccessLevelFromPermissionState(state);
  }

  /// Re-reads the current permission state without prompting — used to
  /// paint the debug screen's initial state before the user taps anything.
  Future<GalleryAccessLevel> currentAccess() async {
    final state = await PhotoManager.getPermissionState(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(type: RequestType.image, mediaLocation: false),
      ),
    );
    return galleryAccessLevelFromPermissionState(state);
  }

  /// Android 14's limited-access picker — lets the user add more selected
  /// photos without leaving the app (vs [openSettings], which is the only
  /// recourse for a flat `denied` state).
  Future<void> presentLimitedSelection() => PhotoManager.presentLimited(type: RequestType.image);

  Future<void> openSettings() => PhotoManager.openSetting();

  /// Queries every album in [kSlipSourceAlbums] (spec §7.5) and returns
  /// every image in each, in album order. Matches purely on
  /// [AssetPathEntity.name] — no path/ID hardcoding, so a bank renaming its
  /// album just needs the config list updated, not this method.
  Future<List<SlipCandidate>> queryConfiguredAlbums() async {
    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    final matching = albums.where((album) => kSlipSourceAlbums.contains(album.name));

    final candidates = <SlipCandidate>[];
    for (final album in matching) {
      final count = await album.assetCountAsync;
      final assets = await album.getAssetListRange(start: 0, end: count);
      candidates.addAll(
        assets.map((asset) => SlipCandidate(id: asset.id, filename: asset.title ?? asset.id, sourceAlbum: album.name)),
      );
    }
    return candidates;
  }

  /// Raw image bytes for one [SlipCandidate.id], for T10's
  /// compress-then-upload step. `null` if the asset was deleted from the
  /// gallery between the query and this read (e.g. the user deleted the
  /// screenshot mid-scan) — callers treat that the same as a failed upload
  /// for this file, not a crash.
  Future<Uint8List?> readBytes(String assetId) async {
    final asset = await AssetEntity.fromId(assetId);
    return asset?.originBytes;
  }
}

@riverpod
SlipGalleryRepository slipGalleryRepository(Ref ref) => SlipGalleryRepository();

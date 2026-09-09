import 'package:photo_manager/photo_manager.dart';

/// Collapses `photo_manager`'s 5-value [PermissionState] down to the 3
/// outcomes this feature actually needs to branch on. Kept separate from
/// `core/network/failure.dart`'s `Failure` hierarchy on purpose — that type
/// is modeled around backend `error_code` values (spec §4's retry table);
/// gallery/permission access isn't a network call and doesn't map onto any
/// of those codes, so forcing it into `Either<Failure, T>` would misuse it.
enum GalleryAccessLevel {
  /// [PermissionState.authorized] — every asset in the library is visible.
  full,

  /// [PermissionState.limited] — Android 14's "Select photos" partial
  /// access, or iOS's limited library. Querying an album that exists but
  /// wasn't included in the user's selection legitimately returns zero
  /// results here — not a bug, per `photo_manager`'s own docs.
  limited,

  /// [PermissionState.denied], [PermissionState.restricted], or
  /// [PermissionState.notDetermined] — no access at all.
  denied,
}

/// [PermissionState.isAuth]/[PermissionState.isLimited] are `photo_manager`'s
/// own extension getters (see its `PermissionStateExt`) — used here rather
/// than a manual switch so this stays correct if the plugin adds another
/// "has some access" state later.
GalleryAccessLevel galleryAccessLevelFromPermissionState(PermissionState state) {
  if (state.isAuth) return GalleryAccessLevel.full;
  if (state.isLimited) return GalleryAccessLevel.limited;
  return GalleryAccessLevel.denied;
}

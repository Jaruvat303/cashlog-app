import 'package:cashlog/features/slip_scan/domain/gallery_access_level.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  test('authorized maps to full', () {
    expect(galleryAccessLevelFromPermissionState(PermissionState.authorized), GalleryAccessLevel.full);
  });

  test('limited maps to limited', () {
    expect(galleryAccessLevelFromPermissionState(PermissionState.limited), GalleryAccessLevel.limited);
  });

  test('denied, restricted, and notDetermined all map to denied', () {
    expect(galleryAccessLevelFromPermissionState(PermissionState.denied), GalleryAccessLevel.denied);
    expect(galleryAccessLevelFromPermissionState(PermissionState.restricted), GalleryAccessLevel.denied);
    expect(galleryAccessLevelFromPermissionState(PermissionState.notDetermined), GalleryAccessLevel.denied);
  });
}

/// One image found in a configured source album (`kSlipSourceAlbums`).
/// Display-only for T9's debug screen — [id] is `photo_manager`'s
/// `AssetEntity.id`, kept here (not just the filename) since T10's
/// upload/diff-against-`scanned_slips` step will need it, but T9 itself
/// never persists or uploads anything (explicitly excluded from this
/// ticket's scope).
class SlipCandidate {
  const SlipCandidate({required this.id, required this.filename, required this.sourceAlbum});

  final String id;
  final String filename;
  final String sourceAlbum;
}

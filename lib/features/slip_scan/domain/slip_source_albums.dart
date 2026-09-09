/// The Android gallery album names to scan for bank slip screenshots
/// (spec §7.5) — the single source of truth for which albums the app looks
/// at. Confirmed against real devices per spec §1; kept as a plain config
/// list rather than hardcoded inside query logic so a bank app renaming its
/// album (or a new bank being added) is a one-line change here, not a hunt
/// through `SlipGalleryRepository`.
const List<String> kSlipSourceAlbums = ['SCB EASY', 'Dime!'];

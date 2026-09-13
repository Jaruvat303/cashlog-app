import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens lifted directly from the Claude Design mockup
/// (`CashLog Mockups.dc.html`, screens 1a-1f) — every hex here is copied
/// verbatim from that file's inline styles, not approximated, so screens
/// built against these tokens match the mockup pixel-for-pixel on color.
class AppColors {
  const AppColors._();

  static const canvas = Color(0xFFE9EAEE);
  static const screenBackground = Color(0xFFF4F5F7);
  static const surface = Color(0xFFFFFFFF);

  static const border = Color(0xFFECEDF0);
  static const divider = Color(0xFFEEF0F3);
  static const inputBorder = Color(0xFFE5E7EB);

  static const textPrimary = Color(0xFF101828);
  static const textSecondary = Color(0xFF7A8394);
  static const textMuted = Color(0xFF9AA2B1);
  static const textFaint = Color(0xFFC3C8D2);

  static const primary = Color(0xFF6B5BD6);
  static const primaryPressed = Color(0xFF5546BD);
  static const primarySurface = Color(0xFFF2F0FD);
  static const primarySurfaceBorder = Color(0xFFE5E1FA);
  static const primaryText = Color(0xFF4C4180);
  static const primaryTextMuted = Color(0xFF8D86AB);

  static const income = Color(0xFF0F9D6F);
  static const incomeSurface = Color(0xFFE8F6F1);
  static const expense = Color(0xFFE14B4B);
  static const expenseSurface = Color(0xFFFDECEB);

  static const warningIcon = Color(0xFFD99012);
  static const warningBorder = Color(0xFFE0AE4C);
  static const warningSurface = Color(0xFFFDF4E3);
  static const warningBadgeBg = Color(0xFFFFF7E6);
  static const warningBadgeBorder = Color(0xFFF3DDA8);
  static const warningText = Color(0xFFA4700E);

  static const chipUnselectedBg = Color(0xFFFFFFFF);
  static const chipUnselectedBorder = Color(0xFFE5E7EB);
  static const chipUnselectedText = Color(0xFF4A5261);
  static const chipSelectedBg = Color(0xFF101828);

  static const neutralIcon = Color(0xFF5A6472);
  static const neutralSurface = Color(0xFFF1F3F7);
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, primary: AppColors.primary),
      scaffoldBackgroundColor: AppColors.screenBackground,
      fontFamily: GoogleFonts.ibmPlexSansThai().fontFamily,
    );

    final textTheme = GoogleFonts.ibmPlexSansThaiTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 19),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, space: 1, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.inputBorder)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      ),
      dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// A rounded pull handle, used at the top of every bottom sheet in the
/// mockup (screens 1c/1d/1f).
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 4,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: const Color(0xFFE2E5EA), borderRadius: BorderRadius.circular(2)),
    );
  }
}

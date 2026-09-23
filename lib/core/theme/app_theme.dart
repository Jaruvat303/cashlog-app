import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'finance_colors.dart';

/// Design tokens lifted from the Cashlog Home Redesign mockup (Artifact
/// canvas `EzQR2CFArVrtPonnrqiezH`) — every hex here is copied verbatim from
/// that canvas's screens, not approximated. One deliberate exception: the
/// mockup itself uses two different income/expense pairs (a brighter one on
/// Add/AccountDetail, a darker one on Home's list rows) — canonicalized here
/// on the brighter pair (`income`/`expense` below) so semantic color reads
/// consistently across the whole app.
class AppColors {
  const AppColors._();

  static const background = Color(0xFFF5F6FA);
  static const surface = Color(0xFFFFFFFF);

  static const border = Color(0xFFECEDF0);
  static const divider = Color(0xFFF0F0F5);
  static const inputBorder = Color(0xFFE5E7EB);

  static const textPrimary = Color(0xFF1A1D29);
  static const textSecondary = Color(0xFF8B90A0);
  static const textTertiary = Color(0xFF5B6172);
  static const textFaint = Color(0xFFC3C8D2);

  /// Flat brand accent, for anywhere the two-stop gradient below isn't
  /// applicable (icons, focus rings, single-color fills).
  static const accentA = Color(0xFF4F8EF7);
  static const accentB = Color(0xFF8B5CF6);
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentA, accentB],
  );
  static const primary = accentA;
  static const primarySurface = Color(0x1D8B5CF6);
  static const primarySurfaceBorder = Color(0x4D8B5CF6);
  static const primaryText = Color(0xFF5B4B9E);

  static const income = Color(0xFF22B573);
  static const incomeSurface = Color(0x1F22B573);
  static const expense = Color(0xFFF2784B);
  static const expenseSurface = Color(0x1FF2784B);
  static const transfer = Color(0xFF6C5CE7);
  static const transferSurface = Color(0x1F6C5CE7);

  static const warningIcon = Color(0xFFD9970E);
  static const warningIconBg = Color(0xFFFFFDF6);
  static const warningBorder = Color(0xFFF2B94B);
  static const warningBadgeBg = Color(0xFFFFF3D6);
  static const warningBadgeBorder = Color(0xFFF1DFA0);
  static const warningBadgeText = Color(0xFFB98900);

  static const chipUnselectedBg = Color(0xFFFFFFFF);
  static const chipUnselectedBorder = Color(0xFFE3E5EC);
  static const chipUnselectedText = Color(0xFF4A5261);
  static const chipSelectedBg = Color(0xFF1A1D29);

  static const tabTrackBg = Color(0xFFEDEEF3);
  static const pillChipBg = Color(0xFFF1F2F7);

  static const neutralIcon = Color(0xFF5A6472);
  static const neutralSurface = Color(0xFFF1F3F7);
}

/// Radius scale used across the redesigned screens — named so magic numbers
/// don't drift between files that should match.
class AppRadii {
  const AppRadii._();

  static const chip = 12.0;
  static const control = 14.0;
  static const card = 16.0;
  static const cardLarge = 18.0;
  static const hero = 22.0;
  static const sheet = 26.0;
}

class AppShadows {
  const AppShadows._();

  /// The one card shadow reused everywhere in the mockup (`.cl-card`).
  static const card = BoxShadow(
    color: Color(0x14141428),
    blurRadius: 20,
    offset: Offset(0, 6),
  );

  /// Softer, colored shadow under gradient-filled elements (FAB, primary
  /// buttons, hero banners).
  static const accent = BoxShadow(
    color: Color(0x527C5CFC),
    blurRadius: 22,
    offset: Offset(0, 8),
  );
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accentB,
        primary: AppColors.accentA,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.ibmPlexSansThai().fontFamily,
    );

    final textTheme = GoogleFonts.ibmPlexSansThaiTextTheme(base.textTheme)
        .apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        );

    return base.copyWith(
      textTheme: textTheme,
      extensions: const [FinanceColors.light],
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.cardLarge)),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        space: 1,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: const BorderSide(color: AppColors.accentA, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentA,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control + 1),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentB,
        foregroundColor: Colors.white,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.cardLarge),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// A rounded pull handle, used at the top of every bottom sheet.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 4,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E5EA),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

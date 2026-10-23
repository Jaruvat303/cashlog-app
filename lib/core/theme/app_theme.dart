import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared color tokens for the Cashlog light theme.
class AppColors {
  const AppColors._();

  static const background = Color(0xFFF5F6FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF1F2F7);
  static const border = Color(0xFFE5E7EB);
  static const divider = Color(0xFFF0F0F5);

  static const textPrimary = Color(0xFF1A1D29);
  static const textBody = Color(0xFF5B6172);
  static const textMuted = Color(0xFF8B90A0);
  static const textDisabled = Color(0xFFC3C8D2);

  static const primary = Color(0xFF7656F6);
  static const primaryLight = Color(0xFF8B5CF6);
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const income = Color(0xFF16A164);
  static const expense = Color(0xFFE8622C);
  static const transfer = Color(0xFF64748B);

  static Color tint(Color color, [double alpha = 0.12]) =>
      color.withValues(alpha: alpha);
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
  static final accent = BoxShadow(
    color: AppColors.tint(AppColors.primary, .32),
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
        seedColor: AppColors.primary,
        primary: AppColors.primary,
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
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control + 1),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
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
        backgroundColor: AppColors.primary,
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
        color: AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

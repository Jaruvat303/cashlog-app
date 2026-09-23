import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Income/expense colors shared across the app, registered on [ThemeData]
/// via [ThemeExtension] so any screen can read them instead of copying the
/// [AppColors] values directly.
@immutable
class FinanceColors extends ThemeExtension<FinanceColors> {
  const FinanceColors({required this.income, required this.expense});

  final Color income;
  final Color expense;

  /// Same values the create/edit transaction screen used before this
  /// extension existed — see `AppColors.income`/`AppColors.expense`.
  static const light = FinanceColors(
    income: AppColors.income,
    expense: AppColors.expense,
  );

  @override
  FinanceColors copyWith({Color? income, Color? expense}) {
    return FinanceColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
    );
  }

  @override
  FinanceColors lerp(ThemeExtension<FinanceColors>? other, double t) {
    if (other is! FinanceColors) return this;
    return FinanceColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FinanceColors &&
      other.income == income &&
      other.expense == expense;

  @override
  int get hashCode => Object.hash(income, expense);
}

extension FinanceColorsX on BuildContext {
  /// Falls back to [FinanceColors.light] when no extension is registered —
  /// existing widget tests pump screens with a plain `MaterialApp()` and no
  /// `theme:`, and this must not crash them.
  FinanceColors get financeColors =>
      Theme.of(this).extension<FinanceColors>() ?? FinanceColors.light;
}

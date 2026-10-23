import 'package:cashlog/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrastRatio(Color first, Color second) {
  final luminances = [first.computeLuminance(), second.computeLuminance()]
    ..sort((a, b) => b.compareTo(a));
  return (luminances[0] + 0.05) / (luminances[1] + 0.05);
}

void main() {
  group('AppColors contrast', () {
    test('body text is readable on standard and muted surfaces', () {
      expect(
        _contrastRatio(AppColors.textBody, AppColors.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(AppColors.textBody, AppColors.surfaceMuted),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('white text is readable on brand colors', () {
      expect(
        _contrastRatio(Colors.white, AppColors.primary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(Colors.white, AppColors.primaryLight),
        greaterThanOrEqualTo(4.0),
      );
    });

    test('semantic amounts meet their contrast thresholds', () {
      expect(
        _contrastRatio(AppColors.income, AppColors.surface),
        greaterThanOrEqualTo(3.0),
      );
      expect(
        _contrastRatio(AppColors.expense, AppColors.surface),
        greaterThanOrEqualTo(3.0),
      );
      expect(
        _contrastRatio(AppColors.transfer, AppColors.surface),
        greaterThanOrEqualTo(4.5),
      );
    });
  });
}

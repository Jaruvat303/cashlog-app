import 'package:cashlog/core/theme/app_theme.dart';
import 'package:cashlog/core/theme/finance_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FinanceColors', () {
    test(
      'light instance carries the existing AppColors income/expense values',
      () {
        expect(FinanceColors.light.income, AppColors.income);
        expect(FinanceColors.light.expense, AppColors.expense);
      },
    );

    test('copyWith overrides only the given fields', () {
      const original = FinanceColors(income: Colors.green, expense: Colors.red);
      final copy = original.copyWith(income: Colors.blue);
      expect(copy.income, Colors.blue);
      expect(copy.expense, Colors.red);
    });

    test('lerp at t=0 and t=1 returns the endpoints', () {
      const a = FinanceColors(
        income: Color(0xFF22B573),
        expense: Color(0xFFF2784B),
      );
      const b = FinanceColors(
        income: Color(0xFF0000FF),
        expense: Color(0xFFFFFF00),
      );
      expect(a.lerp(b, 0), a);
      expect(a.lerp(b, 1), b);
    });

    test('lerp with a non-FinanceColors other returns this unchanged', () {
      const a = FinanceColors(
        income: Color(0xFF22B573),
        expense: Color(0xFFF2784B),
      );
      expect(a.lerp(null, 0.5), a);
    });
  });

  group('BuildContext.financeColors', () {
    // AppTheme.light() builds a GoogleFonts text theme, which kicks off a
    // detached (fire-and-forget) network fetch internally — calling
    // AppTheme.light() bare in a plain test(), or even via tester.runAsync,
    // leaves that fetch dangling and it throws an unhandled exception onto
    // whatever test runs next. Actually mounting the theme via pumpWidget +
    // pumpAndSettle (as every real screen test already does) lets that
    // settle within this test's own boundary instead — same pattern as
    // test/widget_test.dart, which also builds AppTheme.light() and doesn't
    // hit this.
    testWidgets(
      'AppTheme.light() registers a FinanceColors extension equal to AppColors income/expense, reachable via context.financeColors',
      (tester) async {
        late ThemeData theme;
        late FinanceColors resolved;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Builder(
              builder: (context) {
                theme = Theme.of(context);
                resolved = context.financeColors;
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final extension = theme.extension<FinanceColors>();
        expect(extension, isNotNull);
        expect(extension!.income, AppColors.income);
        expect(extension.expense, AppColors.expense);

        expect(resolved.income, AppColors.income);
        expect(resolved.expense, AppColors.expense);
      },
    );

    testWidgets(
      'falls back to FinanceColors.light when no extension is registered',
      (tester) async {
        late FinanceColors resolved;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                resolved = context.financeColors;
                return const SizedBox();
              },
            ),
          ),
        );

        expect(resolved, FinanceColors.light);
      },
    );
  });
}

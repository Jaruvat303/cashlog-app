import 'package:cashlog/features/dashboard/data/dashboard_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboardSummaryFromJson parses totals and both breakdown lists', () {
    final summary = dashboardSummaryFromJson({
      'total_income': 5000,
      'total_expense': 3200.5,
      'total_transfer': 1000,
      'scope': 'monthly',
      'year': 2026,
      'month': 9,
      'income': [
        {'category_id': 1, 'category_name': 'Salary', 'icon_key': 'money-dollar-circle-fill', 'color_hex': '#22C55E', 'total_amount': 5000},
      ],
      'expense': [
        {'category_id': 2, 'category_name': 'Food', 'icon_key': 'restaurant-fill', 'color_hex': '#EF4444', 'total_amount': 2000},
        {'category_id': 3, 'category_name': 'Transport', 'icon_key': 'car-fill', 'color_hex': '#3B82F6', 'total_amount': 1200.5},
      ],
    });

    expect(summary.totalIncome, 5000);
    expect(summary.totalExpense, 3200.5);
    expect(summary.totalTransfer, 1000);
    expect(summary.year, 2026);
    expect(summary.month, 9);
    expect(summary.net, 5000 - 3200.5);

    expect(summary.income, hasLength(1));
    expect(summary.income.single.categoryName, 'Salary');

    expect(summary.expense, hasLength(2));
    expect(summary.expense[0].categoryName, 'Food');
    expect(summary.expense[0].iconKey, 'restaurant-fill');
    expect(summary.expense[1].totalAmount, 1200.5);
  });

  test('dashboardSummaryFromJson tolerates a missing icon_key/color_hex on a breakdown entry', () {
    final summary = dashboardSummaryFromJson({
      'total_income': 0,
      'total_expense': 100,
      'total_transfer': 0,
      'year': 2026,
      'month': 9,
      'income': [],
      'expense': [
        {'category_id': 1, 'category_name': 'Misc', 'total_amount': 100},
      ],
    });

    expect(summary.expense.single.iconKey, '');
    expect(summary.expense.single.colorHex, '');
  });

  test('dashboardSummaryFromJson tolerates a null income/expense list', () {
    final summary = dashboardSummaryFromJson({
      'total_income': 0,
      'total_expense': 0,
      'total_transfer': 0,
      'year': 2026,
      'month': 9,
      'income': null,
      'expense': null,
    });

    expect(summary.income, isEmpty);
    expect(summary.expense, isEmpty);
  });
}

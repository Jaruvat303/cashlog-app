import 'package:cashlog/features/dashboard/domain/dashboard_summary.dart';
import 'package:flutter_test/flutter_test.dart';

CategoryBreakdown _breakdown(int id, String name, double amount) =>
    CategoryBreakdown(
      categoryId: id,
      categoryName: name,
      iconKey: 'restaurant-fill',
      colorHex: '#EF4444',
      totalAmount: amount,
    );

void main() {
  group('topCategoriesWithOther', () {
    test('9 categories: returns the top 8 by amount descending, with the remainder folded into "อื่นๆ"', () {
      final breakdown = [
        _breakdown(1, 'A', 100),
        _breakdown(2, 'B', 900),
        _breakdown(3, 'C', 200),
        _breakdown(4, 'D', 800),
        _breakdown(5, 'E', 300),
        _breakdown(6, 'F', 700),
        _breakdown(7, 'G', 400),
        _breakdown(8, 'H', 600),
        _breakdown(9, 'I', 500),
      ];

      final result = topCategoriesWithOther(breakdown);

      expect(result.length, 9); // top 8 + "อื่นๆ"
      expect(result.map((b) => b.categoryName).take(8), [
        'B',
        'D',
        'F',
        'H',
        'I',
        'G',
        'E',
        'C',
      ]);
      expect(result.last.categoryId, kOtherCategoryId);
      expect(result.last.categoryName, 'อื่นๆ');
      expect(
        result.last.totalAmount,
        100,
      ); // the 9th-ranked category (A, 100) is the only one left over
    });

    test('more than 9 categories: "อื่นๆ" sums every category past the top 8, not just the 9th', () {
      final breakdown = [
        for (var i = 1; i <= 12; i++) _breakdown(i, 'Cat$i', i.toDouble()),
      ];

      final result = topCategoriesWithOther(breakdown);

      expect(result.length, 9);
      // Top 8 by amount descending: 12, 11, 10, 9, 8, 7, 6, 5 — leftover: 4+3+2+1 = 10.
      expect(result.sublist(0, 8).map((b) => b.totalAmount), [
        12,
        11,
        10,
        9,
        8,
        7,
        6,
        5,
      ]);
      expect(result.last.categoryId, kOtherCategoryId);
      expect(result.last.totalAmount, 10);
    });

    test('exactly 8 categories: no "อื่นๆ" bucket is added', () {
      final breakdown = [
        for (var i = 1; i <= 8; i++) _breakdown(i, 'Cat$i', i.toDouble()),
      ];

      final result = topCategoriesWithOther(breakdown);

      expect(result.length, 8);
      expect(result.any((b) => b.categoryId == kOtherCategoryId), isFalse);
    });

    test('fewer than 8 categories: no zero-amount "อื่นๆ" ever appears', () {
      final breakdown = [_breakdown(1, 'A', 500), _breakdown(2, 'B', 300)];

      final result = topCategoriesWithOther(breakdown);

      expect(result.length, 2);
      expect(result.any((b) => b.categoryId == kOtherCategoryId), isFalse);
    });

    test('empty breakdown: returns an empty list', () {
      expect(topCategoriesWithOther(const []), isEmpty);
    });

    test('a custom maxSegments is respected', () {
      final breakdown = [
        _breakdown(1, 'A', 300),
        _breakdown(2, 'B', 200),
        _breakdown(3, 'C', 100),
      ];

      final result = topCategoriesWithOther(breakdown, maxSegments: 2);

      expect(result.length, 3); // top 2 + "อื่นๆ"
      expect(result.sublist(0, 2).map((b) => b.categoryName), ['A', 'B']);
      expect(result.last.categoryId, kOtherCategoryId);
      expect(result.last.totalAmount, 100);
    });
  });
}

import 'package:cashlog/features/dashboard/domain/trend_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrendQuery equality', () {
    test('two month queries for the same year are equal', () {
      expect(const TrendQuery.month(2026), const TrendQuery.month(2026));
      expect(
        const TrendQuery.month(2026).hashCode,
        const TrendQuery.month(2026).hashCode,
      );
    });

    test(
      'a month query and a year query are never equal, regardless of year',
      () {
        expect(const TrendQuery.month(2026), isNot(const TrendQuery.year()));
        expect(const TrendQuery.year(), isNot(const TrendQuery.month(2026)));
      },
    );

    test(
      'two year queries are always equal — year is normalized to null on both',
      () {
        expect(const TrendQuery.year(), const TrendQuery.year());
        expect(
          const TrendQuery.year().hashCode,
          const TrendQuery.year().hashCode,
        );
        expect(const TrendQuery.year().year, isNull);
      },
    );

    test('month queries for different years are not equal', () {
      expect(const TrendQuery.month(2026), isNot(const TrendQuery.month(2025)));
    });
  });
}

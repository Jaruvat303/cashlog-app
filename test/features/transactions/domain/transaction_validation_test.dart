import 'package:cashlog/features/transactions/domain/transaction_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateTransferAccounts', () {
    test('returns null when the accounts differ', () {
      expect(validateTransferAccounts(1, 2), isNull);
    });

    test('returns an error when both sides are the same account', () {
      expect(validateTransferAccounts(1, 1), isNotNull);
    });

    test('returns null while either side is still unset (mid-form)', () {
      expect(validateTransferAccounts(null, 1), isNull);
      expect(validateTransferAccounts(1, null), isNull);
      expect(validateTransferAccounts(null, null), isNull);
    });
  });

  group('monthsAffectedByEdit', () {
    test('a create (no original date) invalidates only the new transaction\'s month', () {
      expect(monthsAffectedByEdit(null, DateTime.utc(2026, 9, 15)), {(2026, 9)});
    });

    test('an edit that stays within the same month invalidates only that month', () {
      expect(monthsAffectedByEdit(DateTime.utc(2026, 9, 1), DateTime.utc(2026, 9, 28)), {(2026, 9)});
    });

    test('an edit that crosses a month boundary invalidates both the old and new month', () {
      expect(monthsAffectedByEdit(DateTime.utc(2026, 9, 30), DateTime.utc(2026, 10, 1)), {(2026, 9), (2026, 10)});
    });

    test('an edit that crosses a year boundary invalidates both months', () {
      expect(monthsAffectedByEdit(DateTime.utc(2025, 12, 31), DateTime.utc(2026, 1, 1)), {(2025, 12), (2026, 1)});
    });
  });
}

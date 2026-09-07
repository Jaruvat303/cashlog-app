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
}

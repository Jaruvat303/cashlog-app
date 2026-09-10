// Direct truth-table coverage of the pure isJunk rule (spec §7.7), isolated
// from transactionFromJson's parsing — transaction_mapper_test.dart already
// covers the wire-level wiring (senderName-present and a stray `is_junk`
// key), but exercised the rule's three AND operands unevenly. This file
// closes that gap: every operand is flipped independently so the AND can't
// silently degrade to an OR or drop a clause without a test catching it.
import 'package:cashlog/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeIsJunk (spec §7.7: amount==0 && senderName.isEmpty && receiverName.isEmpty)', () {
    test('all three conditions true — junk', () {
      expect(computeIsJunk(amount: 0, senderName: '', receiverName: ''), isTrue);
    });

    test('amount nonzero alone is enough to clear it, even with both names empty', () {
      expect(computeIsJunk(amount: 100, senderName: '', receiverName: ''), isFalse);
    });

    test('a nonempty senderName alone is enough to clear it, even with amount==0', () {
      expect(computeIsJunk(amount: 0, senderName: 'Someone', receiverName: ''), isFalse);
    });

    test('a nonempty receiverName alone is enough to clear it, even with amount==0 (the symmetric case)', () {
      expect(computeIsJunk(amount: 0, senderName: '', receiverName: 'Someone'), isFalse);
    });

    test('all three conditions false — not junk', () {
      expect(computeIsJunk(amount: 500, senderName: 'A', receiverName: 'B'), isFalse);
    });
  });
}

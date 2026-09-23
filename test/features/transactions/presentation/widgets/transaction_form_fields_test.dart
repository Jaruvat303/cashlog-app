// Plain test() throughout — AmountInputFormatter.formatEditUpdate is pure
// (TextEditingValue in, TextEditingValue out), so there's no need to mount
// a widget/testWidgets to exercise it (and CLAUDE.md's testing notes are a
// standing reminder to prefer that when possible).
import 'package:cashlog/features/transactions/presentation/widgets/transaction_form_fields.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AmountInputFormatter caret handling', () {
    final formatter = AmountInputFormatter();

    test('typing into an empty field lands the caret at the end (Add\'s append-only case)', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1', selection: TextSelection.collapsed(offset: 1)),
      );
      expect(result.text, '1');
      expect(result.selection, const TextSelection.collapsed(offset: 1));
    });

    test('appending more digits keeps grouping and the caret at the end', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: '1,234', selection: TextSelection.collapsed(offset: 5)),
        const TextEditingValue(text: '1,2345', selection: TextSelection.collapsed(offset: 6)),
      );
      expect(result.text, '12,345');
      expect(result.selection, const TextSelection.collapsed(offset: 6));
    });

    // Bug fix regression: Edit pre-fills the amount field via
    // formatAmountForInput, so backspacing a leading digit is a normal
    // edit, not an append. Before the fix, the formatter always collapsed
    // the caret to the end of the (re-grouped) string, so the *next*
    // backspace deleted the wrong digit — see this class's doc comment.
    test('backspacing the leading digit of a pre-filled grouped amount keeps the caret where that digit was, not at the end', () {
      // "1,234.50", caret right after the leading "1" (offset 1), user
      // presses backspace: the native edit already removed the "1",
      // producing ",234.50" with the caret at offset 0.
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: '1,234.50', selection: TextSelection.collapsed(offset: 1)),
        const TextEditingValue(text: ',234.50', selection: TextSelection.collapsed(offset: 0)),
      );
      expect(result.text, '234.50');
      // Right before "2" — a follow-up backspace here does nothing (already
      // at the start), instead of the old bug where it deleted the
      // trailing "0".
      expect(result.selection, const TextSelection.collapsed(offset: 0));
    });

    test('backspacing a digit in the middle of a pre-filled amount keeps the caret at that position', () {
      // "1,234.50", caret between "2" and "3" (offset 3), backspace removes
      // the "2": native edit produces "1,34.50" with the caret at offset 2.
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: '1,234.50', selection: TextSelection.collapsed(offset: 3)),
        const TextEditingValue(text: '1,34.50', selection: TextSelection.collapsed(offset: 2)),
      );
      expect(result.text, '134.50');
      // Right after "1", before "3" — exactly where the removed "2" was.
      expect(result.selection, const TextSelection.collapsed(offset: 1));
    });
  });
}

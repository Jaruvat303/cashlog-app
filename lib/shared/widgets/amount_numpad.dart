import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A plain string-based amount buffer for [AmountNumpad] — digits only, at
/// most one decimal point, at most 2 digits after it (matches THB display
/// precision elsewhere in the app).
class AmountInputController extends ValueNotifier<String> {
  AmountInputController([super.initial = '0']);

  void appendDigit(String digit) {
    final current = value == '0' ? '' : value;
    final decimalIndex = current.indexOf('.');
    if (decimalIndex != -1 && current.length - decimalIndex > 2) return;
    value = '$current$digit';
  }

  void appendDecimal() {
    if (value.contains('.')) return;
    value = '$value.';
  }

  void backspace() {
    if (value.length <= 1) {
      value = '0';
      return;
    }
    value = value.substring(0, value.length - 1);
  }

  double get amount => double.tryParse(value) ?? 0;
}

/// The 3×4 numeric keypad used on the Add-transaction amount entry.
class AmountNumpad extends StatelessWidget {
  const AmountNumpad({super.key, required this.onDigit, required this.onDecimal, required this.onBackspace});

  final ValueChanged<String> onDigit;
  final VoidCallback onDecimal;
  final VoidCallback onBackspace;

  static const _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', 'backspace'];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.9,
      ),
      itemBuilder: (context, index) {
        final key = _keys[index];
        return _NumpadKey(
          isBackspace: key == 'backspace',
          label: key == 'backspace' ? '' : key,
          onTap: () {
            if (key == 'backspace') {
              onBackspace();
            } else if (key == '.') {
              onDecimal();
            } else {
              onDigit(key);
            }
          },
        );
      },
    );
  }
}

class _NumpadKey extends StatefulWidget {
  const _NumpadKey({required this.label, required this.onTap, this.isBackspace = false});

  final String label;
  final bool isBackspace;
  final VoidCallback onTap;

  @override
  State<_NumpadKey> createState() => _NumpadKeyState();
}

class _NumpadKeyState extends State<_NumpadKey> {
  bool _pressed = false;

  void _setPressed(bool value) => setState(() => _pressed = value);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          gradient: _pressed ? AppColors.accentGradient : null,
          color: _pressed ? null : AppColors.pillChipBg,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        alignment: Alignment.center,
        child: widget.isBackspace
            ? Icon(Icons.backspace_outlined, size: 20, color: _pressed ? Colors.white : AppColors.textPrimary)
            : Text(
                widget.label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _pressed ? Colors.white : AppColors.textPrimary,
                ),
              ),
      ),
    );
  }
}

/// Thousands-separated amount formatting used throughout the redesigned UI
/// (mockup: "฿180,500", "-฿4,000") — no decimals, since every screen in the
/// mockup shows whole-baht amounts. A tiny hand-rolled formatter rather than
/// pulling in `intl` just for comma grouping.
String formatAmount(num amount, {bool withSymbol = true, String sign = ''}) {
  final isNegative = amount < 0;
  final rounded = amount.abs().round();
  final digits = rounded.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  final signPrefix = isNegative ? '-' : sign;
  return '$signPrefix${withSymbol ? '฿' : ''}$buffer';
}

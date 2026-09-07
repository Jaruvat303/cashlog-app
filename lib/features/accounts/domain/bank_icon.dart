import 'package:flutter/material.dart';

/// Client-owned bank identity (spec §7.9): backend only ever sees/stores the
/// `code` string on `Account.bankIcon`. Name, logo, and color live here and
/// nowhere else — never persisted to `CachedAccounts` beyond the code.
class BankIcon {
  const BankIcon({required this.code, required this.label, required this.icon, required this.color});

  final String code;
  final String label;
  final IconData icon;
  final Color color;
}

/// The two banks actually in use per spec §1, plus a non-bank option so
/// `cash`/other accounts still satisfy the backend's required, non-empty
/// `bank_icon` field (CreateAccountInput/UpdateAccountInput).
const Map<String, BankIcon> kBankIcons = {
  'scb': BankIcon(code: 'scb', label: 'SCB EASY', icon: Icons.account_balance, color: Color(0xFF4E2A84)),
  'dime': BankIcon(code: 'dime', label: 'Dime!', icon: Icons.savings, color: Color(0xFF7C3AED)),
  'cash': BankIcon(code: 'cash', label: 'Cash / Other', icon: Icons.payments, color: Color(0xFF6B7280)),
};

const _fallbackIcon = Icons.account_balance_wallet_outlined;
const _fallbackColor = Color(0xFF9E9E9E);

/// A `bank_icon` code from an older client build (or an empty string, seen
/// on at least one live dev account) that isn't in [kBankIcons] falls back
/// to a generic icon with the raw code shown as the label, per spec §7.9 —
/// never throws, never silently shows nothing.
BankIcon resolveBankIcon(String code) {
  final known = kBankIcons[code];
  if (known != null) return known;
  return BankIcon(
    code: code,
    label: code.isEmpty ? 'Unknown bank' : code,
    icon: _fallbackIcon,
    color: _fallbackColor,
  );
}

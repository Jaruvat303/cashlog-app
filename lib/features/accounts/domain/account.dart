/// account_type per SRS §6.1 — `investment` is reserved for a future
/// feature, not yet surfaced anywhere beyond being a valid wire value.
enum AccountType { cash, bank, investment, ewallet }

extension AccountTypeLabel on AccountType {
  String get label => switch (this) {
    AccountType.cash => 'Cash',
    AccountType.bank => 'Bank',
    AccountType.investment => 'Investment',
    AccountType.ewallet => 'E-Wallet',
  };
}

/// Falls back to [AccountType.bank] for any wire value this build doesn't
/// recognize yet, so an unfamiliar/future enum value never crashes the app.
AccountType accountTypeFromWire(String value) => AccountType.values.firstWhere(
  (type) => type.name == value,
  orElse: () => AccountType.bank,
);

class Account {
  const Account({
    required this.id,
    required this.name,
    required this.accountType,
    required this.openingBalance,
    required this.matchingKeywords,
    required this.bankIcon,
    required this.isActive,
  });

  final int id;
  final String name;
  final AccountType accountType;
  final double openingBalance;
  final List<String> matchingKeywords;
  final String bankIcon;
  final bool isActive;
}

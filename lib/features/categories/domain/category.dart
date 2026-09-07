/// category type per SRS — only income/expense; a category is never itself
/// "transfer" (transfers don't take a category, per FR-2.2/§12.4 context).
enum CategoryType { income, expense }

extension CategoryTypeLabel on CategoryType {
  String get label => switch (this) {
    CategoryType.income => 'Income',
    CategoryType.expense => 'Expense',
  };
}

/// Falls back to [CategoryType.expense] for any wire value this build
/// doesn't recognize yet, so an unfamiliar/future enum value never crashes
/// the app — mirrors `accountTypeFromWire`.
CategoryType categoryTypeFromWire(String value) => CategoryType.values.firstWhere(
  (type) => type.name == value,
  orElse: () => CategoryType.expense,
);

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.iconKey,
    required this.colorHex,
  });

  final int id;
  final String name;
  final CategoryType type;
  final String iconKey;
  final String colorHex;
}

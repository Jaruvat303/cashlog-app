import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../core/db/app_database.dart';
import '../domain/account.dart';

/// `AccountResponse` per swagger (`GET`/`POST`/`PATCH` all return this same
/// shape) — confirmed against the live dev API, no `current_balance` field
/// despite the SRS prose ("...with balance"): the backend doesn't actually
/// return one, so nothing here persists or displays a balance.
Account accountFromJson(Map<String, dynamic> json) => Account(
  id: json['id'] as int,
  name: json['name'] as String,
  accountType: accountTypeFromWire(json['account_type'] as String),
  openingBalance: (json['opening_balance'] as num).toDouble(),
  matchingKeywords: (json['matching_keywords'] as List).cast<String>(),
  bankIcon: json['bank_icon'] as String? ?? '',
  isActive: json['is_active'] as bool,
);

/// `CreateAccountInput`: name, account_type, matching_keywords, bank_icon
/// required; opening_balance optional (defaults server-side).
Map<String, dynamic> createAccountBody({
  required String name,
  required AccountType accountType,
  required double openingBalance,
  required List<String> matchingKeywords,
  required String bankIcon,
}) => {
  'name': name,
  'account_type': accountType.name,
  'opening_balance': openingBalance,
  'matching_keywords': matchingKeywords,
  'bank_icon': bankIcon,
};

/// `UpdateAccountInput` has no `opening_balance` field at all — it can't be
/// edited after creation, so the edit form never sends it. `matching_keywords`
/// is the one field the backend marks required even on PATCH.
Map<String, dynamic> updateAccountBody({
  required String name,
  required AccountType accountType,
  required List<String> matchingKeywords,
  required String bankIcon,
}) => {
  'name': name,
  'account_type': accountType.name,
  'matching_keywords': matchingKeywords,
  'bank_icon': bankIcon,
};

CachedAccountsCompanion accountToCompanion(Account account) => CachedAccountsCompanion.insert(
  id: Value(account.id),
  name: account.name,
  accountType: account.accountType.name,
  openingBalance: account.openingBalance,
  matchingKeywordsJson: jsonEncode(account.matchingKeywords),
  bankIcon: account.bankIcon,
  isActive: account.isActive,
);

Account accountFromCached(CachedAccount row) => Account(
  id: row.id,
  name: row.name,
  accountType: accountTypeFromWire(row.accountType),
  openingBalance: row.openingBalance,
  matchingKeywords: (jsonDecode(row.matchingKeywordsJson) as List).cast<String>(),
  bankIcon: row.bankIcon,
  isActive: row.isActive,
);

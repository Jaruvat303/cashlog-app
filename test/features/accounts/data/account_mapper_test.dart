import 'package:cashlog/features/accounts/data/account_mapper.dart';
import 'package:cashlog/features/accounts/domain/account.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accountFromJson parses a live-shaped AccountResponse', () {
    final account = accountFromJson({
      'id': 26,
      'name': 'ลงทุน',
      'account_type': 'bank',
      'opening_balance': 5000,
      'matching_keywords': ['Dime', 'เกียรตินาคินภัทร'],
      'bank_icon': 'dime',
      'is_active': true,
    });

    expect(account.id, 26);
    expect(account.accountType, AccountType.bank);
    expect(account.openingBalance, 5000.0);
    expect(account.matchingKeywords, ['Dime', 'เกียรตินาคินภัทร']);
    expect(account.bankIcon, 'dime');
  });

  test('accountFromJson tolerates an empty bank_icon (seen on live dev data)', () {
    final account = accountFromJson({
      'id': 1,
      'name': 'SCB',
      'account_type': 'bank',
      'opening_balance': 5000,
      'matching_keywords': ['SCB'],
      'bank_icon': '',
      'is_active': true,
    });

    expect(account.bankIcon, '');
  });

  test('round-trips through a CachedAccountsCompanion', () {
    const account = Account(
      id: 1,
      name: 'Main SCB',
      accountType: AccountType.bank,
      openingBalance: 1000,
      matchingKeywords: ['SCB', 'ไทยพาณิชย์'],
      bankIcon: 'scb',
      isActive: true,
    );

    final companion = accountToCompanion(account);
    expect(companion.matchingKeywordsJson.value, '["SCB","ไทยพาณิชย์"]');
  });

  test('accountTypeFromWire falls back to bank for an unrecognized value', () {
    expect(accountTypeFromWire('crypto'), AccountType.bank);
    expect(accountTypeFromWire('cash'), AccountType.cash);
  });
}

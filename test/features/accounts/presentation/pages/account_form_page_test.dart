// Post-launch UI polish ticket 05: this form was restyled to reuse ticket
// 04's icon+label+chevron row / sticky-bottom-button component pattern
// (`PillFormRow`, `PrimaryGradientButton`, `showAnchoredDropdown`) — no
// field or submit-logic change was intended, so this file's job is to prove
// exactly that: the same fields, the same validation, the same
// create()/update() call shape as before the restyle. No test file existed
// for this page prior to the restyle.
import 'package:cashlog/core/network/failure.dart';
import 'package:cashlog/features/accounts/data/accounts_repository.dart';
import 'package:cashlog/features/accounts/domain/account.dart';
import 'package:cashlog/features/accounts/domain/bank_icon.dart';
import 'package:cashlog/features/accounts/presentation/pages/account_form_page.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _CreateArgs = ({
  String name,
  AccountType accountType,
  double openingBalance,
  List<String> matchingKeywords,
  String bankIcon,
});
typedef _UpdateArgs = ({
  int id,
  String name,
  AccountType accountType,
  List<String> matchingKeywords,
  String bankIcon,
});

class _FakeAccountsRepository implements AccountsRepository {
  int createCallCount = 0;
  int updateCallCount = 0;
  Either<Failure, Account>? nextResult;
  _CreateArgs? lastCreateArgs;
  _UpdateArgs? lastUpdateArgs;

  @override
  Stream<List<Account>> watchActiveAccounts() =>
      throw UnimplementedError('not exercised by this page test');

  @override
  Stream<Account?> watchCached(int id) =>
      throw UnimplementedError('not exercised by this page test');

  @override
  Stream<double> watchCurrentBalance(int accountId) =>
      throw UnimplementedError('not exercised by this page test');

  @override
  Future<Either<Failure, void>> refreshFromApi() =>
      throw UnimplementedError('not exercised by this page test');

  @override
  Future<Either<Failure, Account>> create({
    required String name,
    required AccountType accountType,
    required double openingBalance,
    required List<String> matchingKeywords,
    required String bankIcon,
  }) async {
    createCallCount++;
    lastCreateArgs = (
      name: name,
      accountType: accountType,
      openingBalance: openingBalance,
      matchingKeywords: matchingKeywords,
      bankIcon: bankIcon,
    );
    return nextResult ??
        Right(
          Account(
            id: 1,
            name: name,
            accountType: accountType,
            openingBalance: openingBalance,
            matchingKeywords: matchingKeywords,
            bankIcon: bankIcon,
            isActive: true,
          ),
        );
  }

  @override
  Future<Either<Failure, Account>> update(
    int id, {
    required String name,
    required AccountType accountType,
    required List<String> matchingKeywords,
    required String bankIcon,
  }) async {
    updateCallCount++;
    lastUpdateArgs = (
      id: id,
      name: name,
      accountType: accountType,
      matchingKeywords: matchingKeywords,
      bankIcon: bankIcon,
    );
    return nextResult ??
        Right(
          Account(
            id: id,
            name: name,
            accountType: accountType,
            openingBalance: 0,
            matchingKeywords: matchingKeywords,
            bankIcon: bankIcon,
            isActive: true,
          ),
        );
  }

  @override
  Future<Either<Failure, void>> close(int id) =>
      throw UnimplementedError('not exercised by this page test');
}

/// pumpAndSettle can't tell "still legitimately loading" from "stuck
/// forever" — a bounded pump loop fails fast instead (same reasoning as
/// test/widget_test.dart's `_pumpBounded`).
Future<void> _pumpBounded(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late _FakeAccountsRepository fakeAccounts;

  setUp(() {
    fakeAccounts = _FakeAccountsRepository();
  });

  // A real Navigator stack beneath the form — `MaterialApp(home:
  // AccountFormPage())` alone has nothing to pop back to, so a successful
  // submit's `Navigator.pop()` would be a no-op and the page would still be
  // "found" afterwards even though the real app pops it just fine.
  Widget buildApp({Account? initial}) => ProviderScope(
    overrides: [accountsRepositoryProvider.overrideWithValue(fakeAccounts)],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AccountFormPage(initial: initial),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  group('create mode', () {
    testWidgets('an empty name is rejected — no create call', (tester) async {
      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);
      await tester.tap(find.text('open'));
      await _pumpBounded(tester);

      await tester.tap(find.byKey(const Key('submitButton')));
      await _pumpBounded(tester);

      expect(find.text('กรุณากรอกชื่อบัญชี'), findsOneWidget);
      expect(fakeAccounts.createCallCount, 0);
    });

    testWidgets('a negative opening balance is rejected — no create call', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);
      await tester.tap(find.text('open'));
      await _pumpBounded(tester);

      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('nameField')),
          matching: find.byType(TextFormField),
        ),
        'My Wallet',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('openingBalanceField')),
          matching: find.byType(TextFormField),
        ),
        '-5',
      );
      await tester.tap(find.byKey(const Key('submitButton')));
      await _pumpBounded(tester);

      expect(find.text('ต้องมากกว่าหรือเท่ากับ 0'), findsOneWidget);
      expect(fakeAccounts.createCallCount, 0);
    });

    testWidgets('a non-numeric opening balance is rejected — no create call', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);
      await tester.tap(find.text('open'));
      await _pumpBounded(tester);

      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('nameField')),
          matching: find.byType(TextFormField),
        ),
        'My Wallet',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('openingBalanceField')),
          matching: find.byType(TextFormField),
        ),
        'abc',
      );
      await tester.tap(find.byKey(const Key('submitButton')));
      await _pumpBounded(tester);

      expect(find.text('กรอกตัวเลขให้ถูกต้อง'), findsOneWidget);
      expect(fakeAccounts.createCallCount, 0);
    });

    testWidgets(
      'submits the name/opening balance with the default account type and bank icon, then pops',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await _pumpBounded(tester);
        await tester.tap(find.text('open'));
        await _pumpBounded(tester);

        await tester.enterText(
          find.descendant(
            of: find.byKey(const Key('nameField')),
            matching: find.byType(TextFormField),
          ),
          'My Wallet',
        );
        await tester.enterText(
          find.descendant(
            of: find.byKey(const Key('openingBalanceField')),
            matching: find.byType(TextFormField),
          ),
          '1500',
        );
        await tester.tap(find.byKey(const Key('submitButton')));
        await _pumpBounded(tester);
        await tester.pumpAndSettle(
          const Duration(milliseconds: 50),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 5),
        );

        expect(fakeAccounts.createCallCount, 1);
        expect(fakeAccounts.lastCreateArgs?.name, 'My Wallet');
        expect(fakeAccounts.lastCreateArgs?.openingBalance, 1500);
        expect(fakeAccounts.lastCreateArgs?.accountType, AccountType.bank);
        expect(fakeAccounts.lastCreateArgs?.bankIcon, kBankIcons.keys.first);
        expect(find.byType(AccountFormPage), findsNothing);
      },
    );

    testWidgets(
      'picking a different account type and bank icon sends those in the create call',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await _pumpBounded(tester);
        await tester.tap(find.text('open'));
        await _pumpBounded(tester);

        await tester.enterText(
          find.descendant(
            of: find.byKey(const Key('nameField')),
            matching: find.byType(TextFormField),
          ),
          'My Wallet',
        );

        await tester.tap(find.byKey(const Key('accountTypePill')));
        await _pumpBounded(tester);
        await tester.tap(find.byKey(const Key('accountTypeOption_cash')));
        await _pumpBounded(tester);

        await tester.tap(find.byKey(const Key('bankIconPill')));
        await _pumpBounded(tester);
        await tester.tap(find.byKey(const Key('bankIconOption_dime')));
        await _pumpBounded(tester);

        await tester.tap(find.byKey(const Key('submitButton')));
        await _pumpBounded(tester);

        expect(fakeAccounts.lastCreateArgs?.accountType, AccountType.cash);
        expect(fakeAccounts.lastCreateArgs?.bankIcon, 'dime');
      },
    );

    testWidgets('matching keywords are split on commas/newlines and trimmed', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);
      await tester.tap(find.text('open'));
      await _pumpBounded(tester);

      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('nameField')),
          matching: find.byType(TextFormField),
        ),
        'My Wallet',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('matchingKeywordsField')),
          matching: find.byType(TextFormField),
        ),
        'SCB EASY, ไทยพาณิชย์ ,\nDime!',
      );
      await tester.tap(find.byKey(const Key('submitButton')));
      await _pumpBounded(tester);

      expect(fakeAccounts.lastCreateArgs?.matchingKeywords, [
        'SCB EASY',
        'ไทยพาณิชย์',
        'Dime!',
      ]);
    });

    testWidgets('a failed create shows the error and stays on the page', (
      tester,
    ) async {
      fakeAccounts.nextResult = const Left(
        UnknownFailure(message: 'Could not create account'),
      );
      await tester.pumpWidget(buildApp());
      await _pumpBounded(tester);
      await tester.tap(find.text('open'));
      await _pumpBounded(tester);

      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('nameField')),
          matching: find.byType(TextFormField),
        ),
        'My Wallet',
      );
      await tester.tap(find.byKey(const Key('submitButton')));
      await _pumpBounded(tester);

      expect(find.text('Could not create account'), findsOneWidget);
      expect(find.byType(AccountFormPage), findsOneWidget);
    });
  });

  group('edit mode', () {
    const existing = Account(
      id: 7,
      name: 'SCB Savings',
      accountType: AccountType.bank,
      openingBalance: 5000,
      matchingKeywords: ['SCB EASY'],
      bankIcon: 'scb',
      isActive: true,
    );

    testWidgets(
      'prefills the existing account\'s fields and hides the opening balance field entirely',
      (tester) async {
        await tester.pumpWidget(buildApp(initial: existing));
        await _pumpBounded(tester);
        await tester.tap(find.text('open'));
        await _pumpBounded(tester);

        expect(find.text('SCB Savings'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('accountTypePill')),
            matching: find.text('ธนาคาร'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('bankIconPill')),
            matching: find.text('SCB EASY'),
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key('openingBalanceField')), findsNothing);

        final keywordsField = tester.widget<TextFormField>(
          find.descendant(
            of: find.byKey(const Key('matchingKeywordsField')),
            matching: find.byType(TextFormField),
          ),
        );
        expect(keywordsField.controller?.text, 'SCB EASY');
      },
    );

    testWidgets('submits the updated fields via update(), never create()', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(initial: existing));
      await _pumpBounded(tester);
      await tester.tap(find.text('open'));
      await _pumpBounded(tester);

      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('nameField')),
          matching: find.byType(TextFormField),
        ),
        'SCB Savings 2',
      );
      await tester.tap(find.byKey(const Key('accountTypePill')));
      await _pumpBounded(tester);
      await tester.tap(find.byKey(const Key('accountTypeOption_ewallet')));
      await _pumpBounded(tester);

      await tester.tap(find.byKey(const Key('submitButton')));
      await _pumpBounded(tester);

      expect(fakeAccounts.createCallCount, 0);
      expect(fakeAccounts.updateCallCount, 1);
      expect(fakeAccounts.lastUpdateArgs?.id, 7);
      expect(fakeAccounts.lastUpdateArgs?.name, 'SCB Savings 2');
      expect(fakeAccounts.lastUpdateArgs?.accountType, AccountType.ewallet);
      // matching_keywords/bank_icon carried through unchanged since this
      // test never touched them.
      expect(fakeAccounts.lastUpdateArgs?.matchingKeywords, ['SCB EASY']);
      expect(fakeAccounts.lastUpdateArgs?.bankIcon, 'scb');
    });

    testWidgets('a failed update shows the error and stays on the page', (
      tester,
    ) async {
      fakeAccounts.nextResult = const Left(
        UnknownFailure(message: 'Could not update account'),
      );
      await tester.pumpWidget(buildApp(initial: existing));
      await _pumpBounded(tester);
      await tester.tap(find.text('open'));
      await _pumpBounded(tester);

      await tester.tap(find.byKey(const Key('submitButton')));
      await _pumpBounded(tester);

      expect(find.text('Could not update account'), findsOneWidget);
      expect(find.byType(AccountFormPage), findsOneWidget);
    });
  });
}

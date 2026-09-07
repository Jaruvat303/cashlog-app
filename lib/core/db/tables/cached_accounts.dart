import 'package:drift/drift.dart';

class CachedAccounts extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get accountType => text()();
  RealColumn get openingBalance => real()();
  TextColumn get matchingKeywordsJson => text()();
  TextColumn get bankIcon => text()();
  BoolColumn get isActive => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

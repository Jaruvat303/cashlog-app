import 'package:drift/drift.dart';

class CachedTransactions extends Table {
  IntColumn get id => integer()();
  RealColumn get amount => real()();
  TextColumn get transactionType => text()();
  TextColumn get senderName => text().withDefault(const Constant(''))();
  TextColumn get receiverName => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get accountId => integer().nullable()();
  IntColumn get fromAccountId => integer().nullable()();
  IntColumn get toAccountId => integer().nullable()();
  TextColumn get source => text()();
  TextColumn get localImageName => text().nullable()();
  DateTimeColumn get transactionDate => dateTime()();
  IntColumn get categoryId => integer().nullable()();
  BoolColumn get isJunk => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

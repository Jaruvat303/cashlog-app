import 'package:drift/drift.dart';

enum SlipStatus { uploaded, duplicate, failed, junk, quotaExceeded }

class ScannedSlips extends Table {
  TextColumn get localImageName => text()();
  TextColumn get sourceFolder => text()();
  TextColumn get status => textEnum<SlipStatus>()();
  IntColumn get serverTransactionId => integer().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastErrorCode => text().nullable()();
  DateTimeColumn get scannedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {localImageName};
}

import 'package:drift/drift.dart';

class PendingManualActions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get actionType => text()();
  TextColumn get payloadJson => text()();
  IntColumn get targetTransactionId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastErrorCode => text().nullable()();
}

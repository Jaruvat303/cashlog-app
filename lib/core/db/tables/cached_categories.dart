import 'package:drift/drift.dart';

class CachedCategories extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get iconKey => text()();
  TextColumn get colorHex => text()();

  @override
  Set<Column> get primaryKey => {id};
}

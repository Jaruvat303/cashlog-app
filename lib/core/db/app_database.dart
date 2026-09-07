import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'tables/cached_accounts.dart';
import 'tables/cached_categories.dart';
import 'tables/cached_transactions.dart';
import 'tables/pending_manual_actions.dart';
import 'tables/scanned_slips.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    ScannedSlips,
    CachedTransactions,
    CachedAccounts,
    CachedCategories,
    PendingManualActions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.withExecutor(super.executor);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app_database.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

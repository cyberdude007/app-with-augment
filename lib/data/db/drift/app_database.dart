import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'tables.dart';
import 'daos/expense_dao.dart';
import 'daos/group_dao.dart';
import 'daos/member_dao.dart';
import 'daos/settlement_dao.dart';
import 'daos/reminder_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/share_dao.dart';
import 'daos/category_dao.dart';

part 'app_database.g.dart';

/// Main database class for PaisaSplit app
@DriftDatabase(
  tables: [
    Members,
    Groups,
    GroupMembers,
    Expenses,
    SplitShares,
    Settlements,
    Reminders,
    AppSettings,
    BackupRecords,
    Categories,
    MemberInteractions,
  ],
  daos: [
    ExpenseDao,
    GroupDao,
    MemberDao,
    SettlementDao,
    ReminderDao,
    SettingsDao,
    ShareDao,
    CategoryDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _insertDefaultData();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Future migrations will be handled here
        if (from < 2) {
          // Example migration for v2
          // await m.addColumn(expenses, expenses.newColumn);
        }
      },
      beforeOpen: (details) async {
        // Enable foreign keys
        await customStatement('PRAGMA foreign_keys = ON');
        
        // Optimize SQLite settings
        await customStatement('PRAGMA journal_mode = WAL');
        await customStatement('PRAGMA synchronous = NORMAL');
        await customStatement('PRAGMA cache_size = 10000');
        await customStatement('PRAGMA temp_store = MEMORY');
      },
    );
  }

  /// Insert default data on first run
  Future<void> _insertDefaultData() async {
    // Insert default categories
    final defaultCategories = [
      ('Food', '🍽️', true),
      ('Transport', '🚕', true),
      ('Groceries', '🛒', true),
      ('Utilities', '💡', true),
      ('Shopping', '🛍️', true),
      ('Entertainment', '🎬', true),
      ('Health', '🏥', true),
      ('Education', '🎓', true),
      ('Bills', '🧾', true),
      ('Miscellaneous', '🏷️', true),
    ];

    for (final (name, emoji, isDefault) in defaultCategories) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          id: _generateId(),
          name: name,
          emoji: Value(emoji),
          isDefault: Value(isDefault),
          createdAt: DateTime.now(),
        ),
      );
    }

    // Insert default app settings
    await into(appSettings).insert(
      AppSettingsCompanion.insert(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Generate a unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
  }

  /// Get database file size in bytes
  Future<int> getDatabaseSize() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'paisa_split.db'));
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Vacuum the database to reclaim space
  Future<void> vacuum() async {
    await customStatement('VACUUM');
  }

  /// Get database statistics
  Future<DatabaseStats> getStats() async {
    final memberCount = await (select(members)..limit(1)).get().then((r) => r.length);
    final groupCount = await (select(groups)..where((g) => g.archived.equals(false))).get().then((r) => r.length);
    final expenseCount = await (select(expenses)..limit(1)).get().then((r) => r.length);
    final settlementCount = await (select(settlements)..limit(1)).get().then((r) => r.length);
    final categoryCount = await (select(categories)..limit(1)).get().then((r) => r.length);
    final dbSize = await getDatabaseSize();

    return DatabaseStats(
      memberCount: memberCount,
      groupCount: groupCount,
      expenseCount: expenseCount,
      settlementCount: settlementCount,
      categoryCount: categoryCount,
      databaseSizeBytes: dbSize,
    );
  }

  /// Clear all data (for testing or reset)
  Future<void> clearAllData() async {
    await transaction(() async {
      // Delete in reverse dependency order
      await delete(memberInteractions).go();
      await delete(backupRecords).go();
      await delete(splitShares).go();
      await delete(settlements).go();
      await delete(expenses).go();
      await delete(groupMembers).go();
      await delete(reminders).go();
      await delete(groups).go();
      await delete(members).go();
      await delete(categories).go();
      
      // Reset app settings to defaults
      await delete(appSettings).go();
      await _insertDefaultData();
    });
  }

  /// Export all data as JSON
  Future<Map<String, dynamic>> exportAsJson() async {
    return {
      'version': schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'members': await select(members).get().then((rows) => rows.map((r) => r.toJson()).toList()),
      'groups': await select(groups).get().then((rows) => rows.map((r) => r.toJson()).toList()),
      'groupMembers': await select(groupMembers).get().then((rows) => rows.map((r) => r.toJson()).toList()),
      'expenses': await select(expenses).get().then((rows) => rows.map((r) => r.toJson()).toList()),
      'splitShares': await select(splitShares).get().then((rows) => rows.map((r) => r.toJson()).toList()),
      'settlements': await select(settlements).get().then((rows) => rows.map((r) => r.toJson()).toList()),
      'reminders': await select(reminders).get().then((rows) => rows.map((r) => r.toJson()).toList()),
      'categories': await select(categories).get().then((rows) => rows.map((r) => r.toJson()).toList()),
      'appSettings': await select(appSettings).get().then((rows) => rows.map((r) => r.toJson()).toList()),
      'backupRecords': await select(backupRecords).get().then((rows) => rows.map((r) => r.toJson()).toList()),
      'memberInteractions': await select(memberInteractions).get().then((rows) => rows.map((r) => r.toJson()).toList()),
    };
  }

  /// Import data from JSON
  Future<void> importFromJson(Map<String, dynamic> data) async {
    await transaction(() async {
      // Clear existing data
      await clearAllData();

      // Import in dependency order
      if (data['members'] != null) {
        for (final memberJson in data['members']) {
          await into(members).insert(Member.fromJson(memberJson));
        }
      }

      if (data['groups'] != null) {
        for (final groupJson in data['groups']) {
          await into(groups).insert(Group.fromJson(groupJson));
        }
      }

      if (data['categories'] != null) {
        for (final categoryJson in data['categories']) {
          await into(categories).insert(Category.fromJson(categoryJson));
        }
      }

      if (data['groupMembers'] != null) {
        for (final gmJson in data['groupMembers']) {
          await into(groupMembers).insert(GroupMember.fromJson(gmJson));
        }
      }

      if (data['expenses'] != null) {
        for (final expenseJson in data['expenses']) {
          await into(expenses).insert(Expense.fromJson(expenseJson));
        }
      }

      if (data['splitShares'] != null) {
        for (final shareJson in data['splitShares']) {
          await into(splitShares).insert(SplitShare.fromJson(shareJson));
        }
      }

      if (data['settlements'] != null) {
        for (final settlementJson in data['settlements']) {
          await into(settlements).insert(Settlement.fromJson(settlementJson));
        }
      }

      if (data['reminders'] != null) {
        for (final reminderJson in data['reminders']) {
          await into(reminders).insert(Reminder.fromJson(reminderJson));
        }
      }

      if (data['appSettings'] != null && data['appSettings'].isNotEmpty) {
        await into(appSettings).insert(AppSetting.fromJson(data['appSettings'][0]));
      }

      if (data['backupRecords'] != null) {
        for (final backupJson in data['backupRecords']) {
          await into(backupRecords).insert(BackupRecord.fromJson(backupJson));
        }
      }

      if (data['memberInteractions'] != null) {
        for (final interactionJson in data['memberInteractions']) {
          await into(memberInteractions).insert(MemberInteraction.fromJson(interactionJson));
        }
      }
    });
  }
}

/// Database connection setup
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'paisa_split.db'));

    // Make sure sqlite3 is properly initialized
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}

/// Database statistics
class DatabaseStats {
  final int memberCount;
  final int groupCount;
  final int expenseCount;
  final int settlementCount;
  final int categoryCount;
  final int databaseSizeBytes;

  const DatabaseStats({
    required this.memberCount,
    required this.groupCount,
    required this.expenseCount,
    required this.settlementCount,
    required this.categoryCount,
    required this.databaseSizeBytes,
  });

  String get formattedSize {
    if (databaseSizeBytes < 1024) {
      return '$databaseSizeBytes B';
    } else if (databaseSizeBytes < 1024 * 1024) {
      return '${(databaseSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(databaseSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  String toString() => 'DatabaseStats('
      'members: $memberCount, '
      'groups: $groupCount, '
      'expenses: $expenseCount, '
      'settlements: $settlementCount, '
      'categories: $categoryCount, '
      'size: $formattedSize)';
}

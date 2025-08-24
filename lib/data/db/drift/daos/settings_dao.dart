import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';
import 'dart:convert';

part 'settings_dao.g.dart';

/// Data Access Object for app settings
@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(AppDatabase db) : super(db);

  /// Get app settings (creates default if not exists)
  Future<AppSetting> getSettings() async {
    var settings = await (select(appSettings)..where((s) => s.id.equals('singleton'))).getSingleOrNull();
    
    if (settings == null) {
      // Create default settings
      await into(appSettings).insert(
        AppSettingsCompanion.insert(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      settings = await (select(appSettings)..where((s) => s.id.equals('singleton'))).getSingle();
    }
    
    return settings;
  }

  /// Update theme setting
  Future<bool> updateTheme(String theme) async {
    final rowsAffected = await (update(appSettings)..where((s) => s.id.equals('singleton')))
        .write(AppSettingsCompanion(
          theme: Value(theme),
          updatedAt: Value(DateTime.now()),
        ));
    return rowsAffected > 0;
  }

  /// Update last default tab
  Future<bool> updateLastDefaultTab(String tab) async {
    final rowsAffected = await (update(appSettings)..where((s) => s.id.equals('singleton')))
        .write(AppSettingsCompanion(
          lastDefaultTab: Value(tab),
          updatedAt: Value(DateTime.now()),
        ));
    return rowsAffected > 0;
  }

  /// Update PIN enabled setting
  Future<bool> updatePinEnabled(bool enabled) async {
    final rowsAffected = await (update(appSettings)..where((s) => s.id.equals('singleton')))
        .write(AppSettingsCompanion(
          pinEnabled: Value(enabled),
          updatedAt: Value(DateTime.now()),
        ));
    return rowsAffected > 0;
  }

  /// Update biometric enabled setting
  Future<bool> updateBiometricEnabled(bool enabled) async {
    final rowsAffected = await (update(appSettings)..where((s) => s.id.equals('singleton')))
        .write(AppSettingsCompanion(
          biometricEnabled: Value(enabled),
          updatedAt: Value(DateTime.now()),
        ));
    return rowsAffected > 0;
  }

  /// Update notifications enabled setting
  Future<bool> updateNotificationsEnabled(bool enabled) async {
    final rowsAffected = await (update(appSettings)..where((s) => s.id.equals('singleton')))
        .write(AppSettingsCompanion(
          notificationsEnabled: Value(enabled),
          updatedAt: Value(DateTime.now()),
        ));
    return rowsAffected > 0;
  }

  /// Update last backup timestamp
  Future<bool> updateLastBackupAt(DateTime timestamp) async {
    final rowsAffected = await (update(appSettings)..where((s) => s.id.equals('singleton')))
        .write(AppSettingsCompanion(
          lastBackupAt: Value(timestamp),
          updatedAt: Value(DateTime.now()),
        ));
    return rowsAffected > 0;
  }

  /// Get last used expense type for a group
  Future<String?> getLastUsedExpenseTypeForGroup(String groupId) async {
    final settings = await getSettings();
    final map = jsonDecode(settings.lastUsedExpenseTypePerGroup) as Map<String, dynamic>;
    return map[groupId] as String?;
  }

  /// Set last used expense type for a group
  Future<bool> setLastUsedExpenseTypeForGroup(String groupId, String expenseType) async {
    final settings = await getSettings();
    final map = jsonDecode(settings.lastUsedExpenseTypePerGroup) as Map<String, dynamic>;
    map[groupId] = expenseType;
    
    final rowsAffected = await (update(appSettings)..where((s) => s.id.equals('singleton')))
        .write(AppSettingsCompanion(
          lastUsedExpenseTypePerGroup: Value(jsonEncode(map)),
          updatedAt: Value(DateTime.now()),
        ));
    return rowsAffected > 0;
  }

  /// Get theme mode
  Future<ThemeMode> getThemeMode() async {
    final settings = await getSettings();
    return ThemeMode.fromString(settings.theme);
  }

  /// Check if PIN is enabled
  Future<bool> isPinEnabled() async {
    final settings = await getSettings();
    return settings.pinEnabled;
  }

  /// Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    final settings = await getSettings();
    return settings.biometricEnabled;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await getSettings();
    return settings.notificationsEnabled;
  }

  /// Get last backup timestamp
  Future<DateTime?> getLastBackupAt() async {
    final settings = await getSettings();
    return settings.lastBackupAt;
  }

  /// Get last default tab
  Future<String> getLastDefaultTab() async {
    final settings = await getSettings();
    return settings.lastDefaultTab;
  }

  /// Reset all settings to defaults
  Future<bool> resetToDefaults() async {
    final rowsAffected = await (update(appSettings)..where((s) => s.id.equals('singleton')))
        .write(AppSettingsCompanion(
          theme: const Value('system'),
          lastDefaultTab: const Value('home'),
          lastUsedExpenseTypePerGroup: const Value('{}'),
          pinEnabled: const Value(false),
          biometricEnabled: const Value(true),
          defaultCurrency: const Value('INR'),
          notificationsEnabled: const Value(true),
          lastBackupAt: const Value.absent(),
          updatedAt: Value(DateTime.now()),
        ));
    return rowsAffected > 0;
  }

  /// Update multiple settings at once
  Future<bool> updateSettings({
    String? theme,
    String? lastDefaultTab,
    bool? pinEnabled,
    bool? biometricEnabled,
    bool? notificationsEnabled,
    DateTime? lastBackupAt,
  }) async {
    final companion = AppSettingsCompanion(
      theme: theme != null ? Value(theme) : const Value.absent(),
      lastDefaultTab: lastDefaultTab != null ? Value(lastDefaultTab) : const Value.absent(),
      pinEnabled: pinEnabled != null ? Value(pinEnabled) : const Value.absent(),
      biometricEnabled: biometricEnabled != null ? Value(biometricEnabled) : const Value.absent(),
      notificationsEnabled: notificationsEnabled != null ? Value(notificationsEnabled) : const Value.absent(),
      lastBackupAt: lastBackupAt != null ? Value(lastBackupAt) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );

    final rowsAffected = await (update(appSettings)..where((s) => s.id.equals('singleton')))
        .write(companion);
    return rowsAffected > 0;
  }

  /// Get settings as a map for export
  Future<Map<String, dynamic>> exportSettings() async {
    final settings = await getSettings();
    return {
      'theme': settings.theme,
      'lastDefaultTab': settings.lastDefaultTab,
      'lastUsedExpenseTypePerGroup': settings.lastUsedExpenseTypePerGroup,
      'pinEnabled': settings.pinEnabled,
      'biometricEnabled': settings.biometricEnabled,
      'defaultCurrency': settings.defaultCurrency,
      'notificationsEnabled': settings.notificationsEnabled,
      'lastBackupAt': settings.lastBackupAt?.toIso8601String(),
      'createdAt': settings.createdAt.toIso8601String(),
      'updatedAt': settings.updatedAt.toIso8601String(),
    };
  }

  /// Import settings from a map
  Future<bool> importSettings(Map<String, dynamic> settingsMap) async {
    final companion = AppSettingsCompanion(
      theme: settingsMap['theme'] != null ? Value(settingsMap['theme'] as String) : const Value.absent(),
      lastDefaultTab: settingsMap['lastDefaultTab'] != null ? Value(settingsMap['lastDefaultTab'] as String) : const Value.absent(),
      lastUsedExpenseTypePerGroup: settingsMap['lastUsedExpenseTypePerGroup'] != null ? 
          Value(settingsMap['lastUsedExpenseTypePerGroup'] as String) : const Value.absent(),
      pinEnabled: settingsMap['pinEnabled'] != null ? Value(settingsMap['pinEnabled'] as bool) : const Value.absent(),
      biometricEnabled: settingsMap['biometricEnabled'] != null ? Value(settingsMap['biometricEnabled'] as bool) : const Value.absent(),
      defaultCurrency: settingsMap['defaultCurrency'] != null ? Value(settingsMap['defaultCurrency'] as String) : const Value.absent(),
      notificationsEnabled: settingsMap['notificationsEnabled'] != null ? 
          Value(settingsMap['notificationsEnabled'] as bool) : const Value.absent(),
      lastBackupAt: settingsMap['lastBackupAt'] != null ? 
          Value(DateTime.parse(settingsMap['lastBackupAt'] as String)) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );

    final rowsAffected = await (update(appSettings)..where((s) => s.id.equals('singleton')))
        .write(companion);
    return rowsAffected > 0;
  }

  /// Get app usage statistics
  Future<AppUsageStats> getUsageStats() async {
    // Count total members
    final memberCount = await (selectOnly(db.members)
      ..addColumns([db.members.id.count()])
    ).getSingle().then((r) => r.read(db.members.id.count()) ?? 0);

    // Count total groups
    final groupCount = await (selectOnly(db.groups)
      ..addColumns([db.groups.id.count()])
      ..where(db.groups.archived.equals(false))
    ).getSingle().then((r) => r.read(db.groups.id.count()) ?? 0);

    // Count total expenses
    final expenseCount = await (selectOnly(db.expenses)
      ..addColumns([db.expenses.id.count()])
    ).getSingle().then((r) => r.read(db.expenses.id.count()) ?? 0);

    // Count total settlements
    final settlementCount = await (selectOnly(db.settlements)
      ..addColumns([db.settlements.id.count()])
    ).getSingle().then((r) => r.read(db.settlements.id.count()) ?? 0);

    // Get first expense date
    final firstExpense = await (select(db.expenses)
      ..orderBy([(e) => OrderingTerm.asc(e.createdAt)])
      ..limit(1)
    ).getSingleOrNull();

    // Get last expense date
    final lastExpense = await (select(db.expenses)
      ..orderBy([(e) => OrderingTerm.desc(e.createdAt)])
      ..limit(1)
    ).getSingleOrNull();

    final settings = await getSettings();

    return AppUsageStats(
      memberCount: memberCount,
      groupCount: groupCount,
      expenseCount: expenseCount,
      settlementCount: settlementCount,
      firstExpenseDate: firstExpense?.createdAt,
      lastExpenseDate: lastExpense?.createdAt,
      appCreatedAt: settings.createdAt,
      lastUpdatedAt: settings.updatedAt,
    );
  }
}

/// App usage statistics
class AppUsageStats {
  final int memberCount;
  final int groupCount;
  final int expenseCount;
  final int settlementCount;
  final DateTime? firstExpenseDate;
  final DateTime? lastExpenseDate;
  final DateTime appCreatedAt;
  final DateTime lastUpdatedAt;

  const AppUsageStats({
    required this.memberCount,
    required this.groupCount,
    required this.expenseCount,
    required this.settlementCount,
    required this.firstExpenseDate,
    required this.lastExpenseDate,
    required this.appCreatedAt,
    required this.lastUpdatedAt,
  });

  /// Get days since first expense
  int? get daysSinceFirstExpense {
    if (firstExpenseDate == null) return null;
    return DateTime.now().difference(firstExpenseDate!).inDays;
  }

  /// Get days since last expense
  int? get daysSinceLastExpense {
    if (lastExpenseDate == null) return null;
    return DateTime.now().difference(lastExpenseDate!).inDays;
  }

  /// Check if user is active (has expenses in last 30 days)
  bool get isActiveUser {
    final daysSince = daysSinceLastExpense;
    return daysSince != null && daysSince <= 30;
  }

  @override
  String toString() => 'AppUsageStats('
      'members: $memberCount, '
      'groups: $groupCount, '
      'expenses: $expenseCount, '
      'settlements: $settlementCount, '
      'active: $isActiveUser)';
}

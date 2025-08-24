import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/drift/app_database.dart';
import '../db/drift/daos/settings_dao.dart';
import '../../core/utils/result.dart';

/// Repository for app settings
class SettingsRepo {
  final SettingsDao _settingsDao;

  SettingsRepo(this._settingsDao);

  /// Get current theme setting
  Future<String> getTheme() async {
    try {
      final settings = await _settingsDao.getSettings();
      return settings.theme;
    } catch (e) {
      return 'system'; // Default theme
    }
  }

  /// Update theme setting
  Future<Result<void>> updateTheme(String theme) async {
    try {
      final success = await _settingsDao.updateTheme(theme);
      return success 
          ? const Result.success(null)
          : const Result.error('Failed to update theme');
    } catch (e) {
      return Result.error('Error updating theme', e);
    }
  }

  /// Get last default tab
  Future<String> getLastDefaultTab() async {
    try {
      return await _settingsDao.getLastDefaultTab();
    } catch (e) {
      return 'home'; // Default tab
    }
  }

  /// Update last default tab
  Future<Result<void>> updateLastDefaultTab(String tab) async {
    try {
      final success = await _settingsDao.updateLastDefaultTab(tab);
      return success 
          ? const Result.success(null)
          : const Result.error('Failed to update default tab');
    } catch (e) {
      return Result.error('Error updating default tab', e);
    }
  }

  /// Check if PIN is enabled
  Future<bool> isPinEnabled() async {
    try {
      return await _settingsDao.isPinEnabled();
    } catch (e) {
      return false;
    }
  }

  /// Update PIN enabled setting
  Future<Result<void>> updatePinEnabled(bool enabled) async {
    try {
      final success = await _settingsDao.updatePinEnabled(enabled);
      return success 
          ? const Result.success(null)
          : const Result.error('Failed to update PIN setting');
    } catch (e) {
      return Result.error('Error updating PIN setting', e);
    }
  }

  /// Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    try {
      return await _settingsDao.isBiometricEnabled();
    } catch (e) {
      return true; // Default to enabled
    }
  }

  /// Update biometric enabled setting
  Future<Result<void>> updateBiometricEnabled(bool enabled) async {
    try {
      final success = await _settingsDao.updateBiometricEnabled(enabled);
      return success 
          ? const Result.success(null)
          : const Result.error('Failed to update biometric setting');
    } catch (e) {
      return Result.error('Error updating biometric setting', e);
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      return await _settingsDao.areNotificationsEnabled();
    } catch (e) {
      return true; // Default to enabled
    }
  }

  /// Update notifications enabled setting
  Future<Result<void>> updateNotificationsEnabled(bool enabled) async {
    try {
      final success = await _settingsDao.updateNotificationsEnabled(enabled);
      return success 
          ? const Result.success(null)
          : const Result.error('Failed to update notifications setting');
    } catch (e) {
      return Result.error('Error updating notifications setting', e);
    }
  }

  /// Get last backup timestamp
  Future<DateTime?> getLastBackupAt() async {
    try {
      return await _settingsDao.getLastBackupAt();
    } catch (e) {
      return null;
    }
  }

  /// Update last backup timestamp
  Future<Result<void>> updateLastBackupAt(DateTime timestamp) async {
    try {
      final success = await _settingsDao.updateLastBackupAt(timestamp);
      return success 
          ? const Result.success(null)
          : const Result.error('Failed to update backup timestamp');
    } catch (e) {
      return Result.error('Error updating backup timestamp', e);
    }
  }

  /// Get last used expense type for a group
  Future<String?> getLastUsedExpenseTypeForGroup(String groupId) async {
    try {
      return await _settingsDao.getLastUsedExpenseTypeForGroup(groupId);
    } catch (e) {
      return null;
    }
  }

  /// Set last used expense type for a group
  Future<Result<void>> setLastUsedExpenseTypeForGroup(String groupId, String expenseType) async {
    try {
      final success = await _settingsDao.setLastUsedExpenseTypeForGroup(groupId, expenseType);
      return success 
          ? const Result.success(null)
          : const Result.error('Failed to update expense type preference');
    } catch (e) {
      return Result.error('Error updating expense type preference', e);
    }
  }

  /// Get all settings
  Future<AppSetting> getSettings() async {
    return await _settingsDao.getSettings();
  }

  /// Update multiple settings at once
  Future<Result<void>> updateSettings({
    String? theme,
    String? lastDefaultTab,
    bool? pinEnabled,
    bool? biometricEnabled,
    bool? notificationsEnabled,
    DateTime? lastBackupAt,
  }) async {
    try {
      final success = await _settingsDao.updateSettings(
        theme: theme,
        lastDefaultTab: lastDefaultTab,
        pinEnabled: pinEnabled,
        biometricEnabled: biometricEnabled,
        notificationsEnabled: notificationsEnabled,
        lastBackupAt: lastBackupAt,
      );
      return success 
          ? const Result.success(null)
          : const Result.error('Failed to update settings');
    } catch (e) {
      return Result.error('Error updating settings', e);
    }
  }

  /// Reset all settings to defaults
  Future<Result<void>> resetToDefaults() async {
    try {
      final success = await _settingsDao.resetToDefaults();
      return success 
          ? const Result.success(null)
          : const Result.error('Failed to reset settings');
    } catch (e) {
      return Result.error('Error resetting settings', e);
    }
  }

  /// Export settings as JSON
  Future<Result<Map<String, dynamic>>> exportSettings() async {
    try {
      final settings = await _settingsDao.exportSettings();
      return Result.success(settings);
    } catch (e) {
      return Result.error('Error exporting settings', e);
    }
  }

  /// Import settings from JSON
  Future<Result<void>> importSettings(Map<String, dynamic> settingsMap) async {
    try {
      final success = await _settingsDao.importSettings(settingsMap);
      return success 
          ? const Result.success(null)
          : const Result.error('Failed to import settings');
    } catch (e) {
      return Result.error('Error importing settings', e);
    }
  }

  /// Get app usage statistics
  Future<Result<AppUsageStats>> getUsageStats() async {
    try {
      final stats = await _settingsDao.getUsageStats();
      return Result.success(stats);
    } catch (e) {
      return Result.error('Error getting usage stats', e);
    }
  }
}

/// Settings repository provider
final settingsRepoProvider = Provider<SettingsRepo>((ref) {
  final database = ref.watch(databaseProvider);
  return SettingsRepo(database.settingsDao);
});

/// Current settings provider
final currentSettingsProvider = FutureProvider<AppSetting>((ref) async {
  final settingsRepo = ref.watch(settingsRepoProvider);
  return await settingsRepo.getSettings();
});

/// Theme setting provider
final themeSettingProvider = FutureProvider<String>((ref) async {
  final settingsRepo = ref.watch(settingsRepoProvider);
  return await settingsRepo.getTheme();
});

/// PIN enabled provider
final pinEnabledProvider = FutureProvider<bool>((ref) async {
  final settingsRepo = ref.watch(settingsRepoProvider);
  return await settingsRepo.isPinEnabled();
});

/// Biometric enabled provider
final biometricEnabledProvider = FutureProvider<bool>((ref) async {
  final settingsRepo = ref.watch(settingsRepoProvider);
  return await settingsRepo.isBiometricEnabled();
});

/// Notifications enabled provider
final notificationsEnabledProvider = FutureProvider<bool>((ref) async {
  final settingsRepo = ref.watch(settingsRepoProvider);
  return await settingsRepo.areNotificationsEnabled();
});

/// Last backup provider
final lastBackupProvider = FutureProvider<DateTime?>((ref) async {
  final settingsRepo = ref.watch(settingsRepoProvider);
  return await settingsRepo.getLastBackupAt();
});

/// Usage stats provider
final usageStatsProvider = FutureProvider<AppUsageStats>((ref) async {
  final settingsRepo = ref.watch(settingsRepoProvider);
  final result = await settingsRepo.getUsageStats();
  return result.fold(
    (stats) => stats,
    (error, _) => throw Exception(error),
  );
});

/// Settings notifier for reactive updates
class SettingsNotifier extends StateNotifier<AsyncValue<AppSetting>> {
  final SettingsRepo _settingsRepo;

  SettingsNotifier(this._settingsRepo) : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsRepo.getSettings();
      state = AsyncValue.data(settings);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateTheme(String theme) async {
    final result = await _settingsRepo.updateTheme(theme);
    if (result.isSuccess) {
      await _loadSettings();
    }
  }

  Future<void> updatePinEnabled(bool enabled) async {
    final result = await _settingsRepo.updatePinEnabled(enabled);
    if (result.isSuccess) {
      await _loadSettings();
    }
  }

  Future<void> updateBiometricEnabled(bool enabled) async {
    final result = await _settingsRepo.updateBiometricEnabled(enabled);
    if (result.isSuccess) {
      await _loadSettings();
    }
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    final result = await _settingsRepo.updateNotificationsEnabled(enabled);
    if (result.isSuccess) {
      await _loadSettings();
    }
  }

  Future<void> resetToDefaults() async {
    final result = await _settingsRepo.resetToDefaults();
    if (result.isSuccess) {
      await _loadSettings();
    }
  }

  void refresh() {
    _loadSettings();
  }
}

/// Settings notifier provider
final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<AppSetting>>((ref) {
  final settingsRepo = ref.watch(settingsRepoProvider);
  return SettingsNotifier(settingsRepo);
});

/// Database provider (to be overridden in main.dart)
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Database provider should be overridden in main.dart');
});

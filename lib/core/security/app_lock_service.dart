import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';

import '../utils/result.dart';

/// App lock service for handling authentication
class AppLockService {
  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;

  static const String _pinHashKey = 'pin_hash';
  static const String _pinSaltKey = 'pin_salt';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lockTimeoutKey = 'lock_timeout';
  static const String _lastUnlockTimeKey = 'last_unlock_time';

  AppLockService({
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuth,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _localAuth = localAuth ?? LocalAuthentication();

  /// Check if PIN is set up
  Future<bool> isPinSetup() async {
    try {
      final pinHash = await _secureStorage.read(key: _pinHashKey);
      return pinHash != null;
    } catch (e) {
      debugPrint('Error checking PIN setup: $e');
      return false;
    }
  }

  /// Set up a new PIN
  Future<Result<void>> setupPin(String pin) async {
    try {
      if (pin.length < 4) {
        return const Result.error('PIN must be at least 4 digits');
      }

      if (!RegExp(r'^\d+$').hasMatch(pin)) {
        return const Result.error('PIN must contain only digits');
      }

      final salt = _generateSalt();
      final hash = _hashPin(pin, salt);

      await _secureStorage.write(key: _pinHashKey, value: hash);
      await _secureStorage.write(key: _pinSaltKey, value: salt);

      return const Result.success(null);
    } catch (e) {
      return Result.error('Failed to setup PIN', e);
    }
  }

  /// Verify PIN
  Future<bool> verifyPin(String pin) async {
    try {
      final storedHash = await _secureStorage.read(key: _pinHashKey);
      final salt = await _secureStorage.read(key: _pinSaltKey);

      if (storedHash == null || salt == null) {
        return false;
      }

      final hash = _hashPin(pin, salt);
      final isValid = hash == storedHash;

      if (isValid) {
        await _updateLastUnlockTime();
      }

      return isValid;
    } catch (e) {
      debugPrint('Error verifying PIN: $e');
      return false;
    }
  }

  /// Change PIN
  Future<Result<void>> changePin(String oldPin, String newPin) async {
    try {
      final isOldPinValid = await verifyPin(oldPin);
      if (!isOldPinValid) {
        return const Result.error('Current PIN is incorrect');
      }

      return await setupPin(newPin);
    } catch (e) {
      return Result.error('Failed to change PIN', e);
    }
  }

  /// Remove PIN
  Future<Result<void>> removePin(String currentPin) async {
    try {
      final isValid = await verifyPin(currentPin);
      if (!isValid) {
        return const Result.error('Current PIN is incorrect');
      }

      await _secureStorage.delete(key: _pinHashKey);
      await _secureStorage.delete(key: _pinSaltKey);

      return const Result.success(null);
    } catch (e) {
      return Result.error('Failed to remove PIN', e);
    }
  }

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: _biometricEnabledKey);
      return enabled == 'true';
    } catch (e) {
      debugPrint('Error checking biometric enabled: $e');
      return false;
    }
  }

  /// Enable/disable biometric authentication
  Future<Result<void>> setBiometricEnabled(bool enabled) async {
    try {
      if (enabled) {
        final isAvailable = await isBiometricAvailable();
        if (!isAvailable) {
          return const Result.error('Biometric authentication is not available');
        }

        // Test biometric authentication
        final success = await authenticateWithBiometrics();
        if (!success) {
          return const Result.error('Biometric authentication failed');
        }
      }

      await _secureStorage.write(
        key: _biometricEnabledKey,
        value: enabled.toString(),
      );

      return const Result.success(null);
    } catch (e) {
      return Result.error('Failed to update biometric setting', e);
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return false;
      }

      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access PaisaSplit',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        await _updateLastUnlockTime();
      }

      return isAuthenticated;
    } catch (e) {
      debugPrint('Error authenticating with biometrics: $e');
      return false;
    }
  }

  /// Set lock timeout in minutes
  Future<void> setLockTimeout(int minutes) async {
    try {
      await _secureStorage.write(
        key: _lockTimeoutKey,
        value: minutes.toString(),
      );
    } catch (e) {
      debugPrint('Error setting lock timeout: $e');
    }
  }

  /// Get lock timeout in minutes
  Future<int> getLockTimeout() async {
    try {
      final timeout = await _secureStorage.read(key: _lockTimeoutKey);
      return int.tryParse(timeout ?? '5') ?? 5; // Default 5 minutes
    } catch (e) {
      debugPrint('Error getting lock timeout: $e');
      return 5;
    }
  }

  /// Check if app should be locked based on timeout
  Future<bool> shouldLock() async {
    try {
      final isPinSetup = await this.isPinSetup();
      if (!isPinSetup) {
        return false; // No PIN setup, don't lock
      }

      final lastUnlockTimeStr = await _secureStorage.read(key: _lastUnlockTimeKey);
      if (lastUnlockTimeStr == null) {
        return true; // No last unlock time, should lock
      }

      final lastUnlockTime = DateTime.fromMillisecondsSinceEpoch(
        int.parse(lastUnlockTimeStr),
      );
      final timeout = await getLockTimeout();
      final lockTime = lastUnlockTime.add(Duration(minutes: timeout));

      return DateTime.now().isAfter(lockTime);
    } catch (e) {
      debugPrint('Error checking if should lock: $e');
      return true; // Default to locked on error
    }
  }

  /// Update last unlock time
  Future<void> _updateLastUnlockTime() async {
    try {
      await _secureStorage.write(
        key: _lastUnlockTimeKey,
        value: DateTime.now().millisecondsSinceEpoch.toString(),
      );
    } catch (e) {
      debugPrint('Error updating last unlock time: $e');
    }
  }

  /// Generate a random salt
  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// Hash PIN with salt
  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Clear all stored authentication data
  Future<void> clearAll() async {
    try {
      await _secureStorage.delete(key: _pinHashKey);
      await _secureStorage.delete(key: _pinSaltKey);
      await _secureStorage.delete(key: _biometricEnabledKey);
      await _secureStorage.delete(key: _lockTimeoutKey);
      await _secureStorage.delete(key: _lastUnlockTimeKey);
    } catch (e) {
      debugPrint('Error clearing authentication data: $e');
    }
  }
}

/// App lock state
class AppLockState {
  final bool isLocked;
  final bool isPinSetup;
  final bool isBiometricEnabled;
  final bool isBiometricAvailable;
  final int lockTimeoutMinutes;

  const AppLockState({
    required this.isLocked,
    required this.isPinSetup,
    required this.isBiometricEnabled,
    required this.isBiometricAvailable,
    required this.lockTimeoutMinutes,
  });

  AppLockState copyWith({
    bool? isLocked,
    bool? isPinSetup,
    bool? isBiometricEnabled,
    bool? isBiometricAvailable,
    int? lockTimeoutMinutes,
  }) {
    return AppLockState(
      isLocked: isLocked ?? this.isLocked,
      isPinSetup: isPinSetup ?? this.isPinSetup,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      lockTimeoutMinutes: lockTimeoutMinutes ?? this.lockTimeoutMinutes,
    );
  }

  @override
  String toString() => 'AppLockState('
      'isLocked: $isLocked, '
      'isPinSetup: $isPinSetup, '
      'isBiometricEnabled: $isBiometricEnabled, '
      'isBiometricAvailable: $isBiometricAvailable, '
      'lockTimeoutMinutes: $lockTimeoutMinutes)';
}

/// App lock state notifier
class AppLockStateNotifier extends StateNotifier<AppLockState> {
  final AppLockService _appLockService;

  AppLockStateNotifier(this._appLockService)
      : super(const AppLockState(
          isLocked: false,
          isPinSetup: false,
          isBiometricEnabled: false,
          isBiometricAvailable: false,
          lockTimeoutMinutes: 5,
        )) {
    _initialize();
  }

  Future<void> _initialize() async {
    final isPinSetup = await _appLockService.isPinSetup();
    final isBiometricEnabled = await _appLockService.isBiometricEnabled();
    final isBiometricAvailable = await _appLockService.isBiometricAvailable();
    final lockTimeoutMinutes = await _appLockService.getLockTimeout();
    final shouldLock = await _appLockService.shouldLock();

    state = AppLockState(
      isLocked: shouldLock,
      isPinSetup: isPinSetup,
      isBiometricEnabled: isBiometricEnabled,
      isBiometricAvailable: isBiometricAvailable,
      lockTimeoutMinutes: lockTimeoutMinutes,
    );
  }

  /// Lock the app
  void lock() {
    state = state.copyWith(isLocked: true);
  }

  /// Unlock the app
  void unlock() {
    state = state.copyWith(isLocked: false);
  }

  /// Update PIN setup status
  void updatePinSetup(bool isPinSetup) {
    state = state.copyWith(isPinSetup: isPinSetup);
  }

  /// Update biometric enabled status
  void updateBiometricEnabled(bool isBiometricEnabled) {
    state = state.copyWith(isBiometricEnabled: isBiometricEnabled);
  }

  /// Update lock timeout
  void updateLockTimeout(int minutes) {
    state = state.copyWith(lockTimeoutMinutes: minutes);
  }

  /// Refresh state
  Future<void> refresh() async {
    await _initialize();
  }
}

/// Providers
final appLockServiceProvider = Provider<AppLockService>((ref) {
  return AppLockService();
});

final appLockStateProvider = StateNotifierProvider<AppLockStateNotifier, AppLockState>((ref) {
  return AppLockStateNotifier(ref.watch(appLockServiceProvider));
});

/// App lifecycle listener for auto-lock
class AppLockLifecycleListener extends WidgetsBindingObserver {
  final WidgetRef ref;
  DateTime? _pausedAt;

  AppLockLifecycleListener(this.ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        _pausedAt = DateTime.now();
        break;
      case AppLifecycleState.resumed:
        _checkAutoLock();
        break;
      default:
        break;
    }
  }

  Future<void> _checkAutoLock() async {
    if (_pausedAt == null) return;

    final appLockService = ref.read(appLockServiceProvider);
    final lockTimeout = await appLockService.getLockTimeout();
    final shouldLock = DateTime.now().difference(_pausedAt!).inMinutes >= lockTimeout;

    if (shouldLock) {
      ref.read(appLockStateProvider.notifier).lock();
    }

    _pausedAt = null;
  }
}

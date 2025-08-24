import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'theme/theme.dart';
import '../core/security/app_lock_service.dart';
import '../data/repos/settings_repo.dart';

/// Main app widget
class PaisaSplitApp extends ConsumerStatefulWidget {
  const PaisaSplitApp({super.key});

  @override
  ConsumerState<PaisaSplitApp> createState() => _PaisaSplitAppState();
}

class _PaisaSplitAppState extends ConsumerState<PaisaSplitApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(ref);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final appLockState = ref.watch(appLockStateProvider);

    return MaterialApp.router(
      title: 'PaisaSplit',
      debugShowCheckedModeBanner: false,
      
      // Theme configuration
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _mapThemeMode(themeMode),
      
      // Router configuration
      routerConfig: _router,
      
      // Localization
      supportedLocales: const [
        Locale('en', 'IN'), // English (India)
        Locale('en', 'US'), // English (US)
      ],
      locale: const Locale('en', 'IN'),
      
      // Builder to handle app lock overlay
      builder: (context, child) {
        return AppLockOverlay(
          isLocked: appLockState.isLocked,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  /// Map custom theme mode to Flutter's ThemeMode
  ThemeMode _mapThemeMode(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };
  }
}

/// App lock overlay widget
class AppLockOverlay extends ConsumerWidget {
  final bool isLocked;
  final Widget child;

  const AppLockOverlay({
    super.key,
    required this.isLocked,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isLocked) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Container(
            color: Colors.black87,
            child: const AppLockScreen(),
          ),
        ),
      ],
    );
  }
}

/// App lock screen widget
class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // Automatically try biometric authentication when screen appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App icon/logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  size: 64,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // App name
              Text(
                'PaisaSplit',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Lock message
              Text(
                'App is locked for your security',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Authentication buttons
              if (_isAuthenticating)
                const CircularProgressIndicator()
              else ...[
                // Biometric auth button
                ElevatedButton.icon(
                  onPressed: _tryBiometricAuth,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Use Biometric'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 48),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // PIN auth button
                OutlinedButton.icon(
                  onPressed: _showPinDialog,
                  icon: const Icon(Icons.pin),
                  label: const Text('Enter PIN'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(200, 48),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Try biometric authentication
  Future<void> _tryBiometricAuth() async {
    if (_isAuthenticating) return;
    
    setState(() {
      _isAuthenticating = true;
    });

    try {
      final appLockService = ref.read(appLockServiceProvider);
      final success = await appLockService.authenticateWithBiometrics();
      
      if (success) {
        ref.read(appLockStateProvider.notifier).unlock();
      } else {
        _showAuthError('Biometric authentication failed');
      }
    } catch (e) {
      _showAuthError('Biometric authentication error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  /// Show PIN entry dialog
  Future<void> _showPinDialog() async {
    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PinEntryDialog(),
    );

    if (pin != null) {
      await _verifyPin(pin);
    }
  }

  /// Verify entered PIN
  Future<void> _verifyPin(String pin) async {
    setState(() {
      _isAuthenticating = true;
    });

    try {
      final appLockService = ref.read(appLockServiceProvider);
      final success = await appLockService.verifyPin(pin);
      
      if (success) {
        ref.read(appLockStateProvider.notifier).unlock();
      } else {
        _showAuthError('Incorrect PIN');
      }
    } catch (e) {
      _showAuthError('PIN verification error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  /// Show authentication error
  void _showAuthError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

/// PIN entry dialog
class PinEntryDialog extends StatefulWidget {
  const PinEntryDialog({super.key});

  @override
  State<PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<PinEntryDialog> {
  final _pinController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('Enter PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            obscureText: _obscureText,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'PIN',
              suffixIcon: IconButton(
                icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                Navigator.of(context).pop(value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final pin = _pinController.text.trim();
            if (pin.isNotEmpty) {
              Navigator.of(context).pop(pin);
            }
          },
          child: const Text('Verify'),
        ),
      ],
    );
  }
}

/// Theme mode enumeration
enum AppThemeMode {
  light,
  dark,
  system;

  static AppThemeMode fromString(String value) {
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppThemeMode.system,
    );
  }
}

/// Theme mode provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(settingsRepoProvider));
});

/// Theme mode notifier
class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  final SettingsRepo _settingsRepo;

  ThemeModeNotifier(this._settingsRepo) : super(AppThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final themeString = await _settingsRepo.getTheme();
      state = AppThemeMode.fromString(themeString);
    } catch (e) {
      // Use default theme mode on error
      state = AppThemeMode.system;
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    try {
      await _settingsRepo.updateTheme(mode.name);
      state = mode;
    } catch (e) {
      // Handle error - maybe show a snackbar
      debugPrint('Failed to update theme mode: $e');
    }
  }
}

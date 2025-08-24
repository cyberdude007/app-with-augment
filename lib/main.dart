import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

import 'app/app.dart';
import 'core/notifications/reminder_scheduler.dart';
import 'data/db/drift/app_database.dart';

/// Global database instance
late final AppDatabase database;

/// Global notification plugin instance
late final FlutterLocalNotificationsPlugin notificationsPlugin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  database = AppDatabase();

  // Initialize notifications
  notificationsPlugin = FlutterLocalNotificationsPlugin();
  await _initializeNotifications();

  // Initialize background work manager
  await _initializeWorkManager();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(
    ProviderScope(
      child: PaisaSplitApp(),
    ),
  );
}

/// Initialize local notifications
Future<void> _initializeNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await notificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: _onNotificationTapped,
  );

  // Request permissions for Android 13+
  await notificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}

/// Handle notification tap
void _onNotificationTapped(NotificationResponse response) {
  // Handle notification tap - navigate to relevant screen
  // This will be implemented when we have the router set up
  debugPrint('Notification tapped: ${response.payload}');
}

/// Initialize work manager for background tasks
Future<void> _initializeWorkManager() async {
  await Workmanager().initialize(
    _callbackDispatcher,
    isInDebugMode: false, // Set to true for debugging
  );

  // Register periodic reminder check task
  await Workmanager().registerPeriodicTask(
    'reminder-check',
    'checkReminders',
    frequency: const Duration(hours: 1),
    constraints: Constraints(
      networkType: NetworkType.not_required,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
    ),
  );
}

/// Background task callback dispatcher
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case 'checkReminders':
          await _checkAndSendReminders();
          break;
        default:
          debugPrint('Unknown background task: $task');
      }
      return Future.value(true);
    } catch (e) {
      debugPrint('Background task error: $e');
      return Future.value(false);
    }
  });
}

/// Check for due reminders and send notifications
Future<void> _checkAndSendReminders() async {
  try {
    // Initialize database for background task
    final bgDatabase = AppDatabase();
    final reminderScheduler = ReminderScheduler(
      database: bgDatabase,
      notificationsPlugin: FlutterLocalNotificationsPlugin(),
    );

    await reminderScheduler.checkAndSendDueReminders();
    await bgDatabase.close();
  } catch (e) {
    debugPrint('Error checking reminders: $e');
  }
}

/// Global providers for dependency injection
final databaseProvider = Provider<AppDatabase>((ref) => database);

final notificationsProvider = Provider<FlutterLocalNotificationsPlugin>(
  (ref) => notificationsPlugin,
);

/// Error handler for uncaught exceptions
void _handleError(Object error, StackTrace stackTrace) {
  debugPrint('Uncaught error: $error');
  debugPrint('Stack trace: $stackTrace');
  
  // In production, you might want to send this to a crash reporting service
  // like Firebase Crashlytics or Sentry
}

/// Custom error widget for release builds
class CustomErrorWidget extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const CustomErrorWidget({
    super.key,
    required this.errorDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please restart the app',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Force restart the app
                SystemNavigator.pop();
              },
              child: const Text('Restart App'),
            ),
          ],
        ),
      ),
    );
  }
}

/// App lifecycle observer
class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('App resumed');
        break;
      case AppLifecycleState.paused:
        debugPrint('App paused');
        break;
      case AppLifecycleState.detached:
        debugPrint('App detached');
        // Close database connection
        database.close();
        break;
      case AppLifecycleState.inactive:
        debugPrint('App inactive');
        break;
      case AppLifecycleState.hidden:
        debugPrint('App hidden');
        break;
    }
  }
}

/// Memory pressure observer
class MemoryPressureObserver {
  static void handleMemoryPressure() {
    debugPrint('Memory pressure detected - cleaning up');
    
    // Clear image cache
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    
    // Run garbage collection
    // Note: This is generally not recommended in production
    // but can be useful during development
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/drift/app_database.dart';
import '../../data/db/drift/daos/reminder_dao.dart';
import '../utils/date_fmt.dart';

/// Service for scheduling and managing reminders
class ReminderScheduler {
  final AppDatabase _database;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  ReminderScheduler({
    required AppDatabase database,
    required FlutterLocalNotificationsPlugin notificationsPlugin,
  })  : _database = database,
        _notificationsPlugin = notificationsPlugin;

  /// Schedule a reminder notification
  Future<void> scheduleReminder({
    required String reminderId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'reminders',
        'Reminders',
        channelDescription: 'Expense and settlement reminders',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        reminderId.hashCode, // Use reminder ID hash as notification ID
        title,
        body,
        _convertToTZDateTime(scheduledTime),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      debugPrint('Scheduled reminder: $title at $scheduledTime');
    } catch (e) {
      debugPrint('Error scheduling reminder: $e');
    }
  }

  /// Cancel a scheduled reminder
  Future<void> cancelReminder(String reminderId) async {
    try {
      await _notificationsPlugin.cancel(reminderId.hashCode);
      debugPrint('Cancelled reminder: $reminderId');
    } catch (e) {
      debugPrint('Error cancelling reminder: $e');
    }
  }

  /// Cancel all scheduled reminders
  Future<void> cancelAllReminders() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('Cancelled all reminders');
    } catch (e) {
      debugPrint('Error cancelling all reminders: $e');
    }
  }

  /// Check for due reminders and send notifications
  Future<void> checkAndSendDueReminders() async {
    try {
      final dueReminders = await _database.reminderDao.getDueReminders();
      
      for (final reminderDetail in dueReminders) {
        await _sendReminderNotification(reminderDetail);
        await _updateNextRunTime(reminderDetail);
      }
    } catch (e) {
      debugPrint('Error checking due reminders: $e');
    }
  }

  /// Send immediate notification for a reminder
  Future<void> sendImmediateReminder({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'reminders',
        'Reminders',
        channelDescription: 'Expense and settlement reminders',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      debugPrint('Sent immediate reminder: $title');
    } catch (e) {
      debugPrint('Error sending immediate reminder: $e');
    }
  }

  /// Schedule group expense reminder
  Future<void> scheduleGroupExpenseReminder({
    required String groupId,
    required String groupName,
    required DateTime scheduledTime,
    String? customMessage,
  }) async {
    final title = 'Expense Reminder';
    final body = customMessage ?? 'Don\'t forget to add expenses for $groupName';
    final payload = jsonEncode({
      'type': 'group_expense',
      'groupId': groupId,
    });

    await scheduleReminder(
      reminderId: 'group_expense_$groupId',
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      payload: payload,
    );
  }

  /// Schedule settlement reminder
  Future<void> scheduleSettlementReminder({
    required String groupId,
    required String groupName,
    required String memberName,
    required String amount,
    required DateTime scheduledTime,
  }) async {
    final title = 'Settlement Reminder';
    final body = 'Reminder: $memberName owes $amount in $groupName';
    final payload = jsonEncode({
      'type': 'settlement',
      'groupId': groupId,
    });

    await scheduleReminder(
      reminderId: 'settlement_${groupId}_${memberName.hashCode}',
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      payload: payload,
    );
  }

  /// Schedule backup reminder
  Future<void> scheduleBackupReminder({
    required DateTime scheduledTime,
  }) async {
    const title = 'Backup Reminder';
    const body = 'Time to backup your PaisaSplit data';
    const payload = '{"type": "backup"}';

    await scheduleReminder(
      reminderId: 'backup_reminder',
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      payload: payload,
    );
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('Error getting pending notifications: $e');
      return [];
    }
  }

  /// Send notification for a due reminder
  Future<void> _sendReminderNotification(ReminderWithDetails reminderDetail) async {
    final reminder = reminderDetail.reminder;
    final title = _getReminderTitle(reminderDetail);
    final body = _getReminderBody(reminderDetail);
    final payload = _getReminderPayload(reminderDetail);

    await sendImmediateReminder(
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Update next run time for a reminder based on its RRULE
  Future<void> _updateNextRunTime(ReminderWithDetails reminderDetail) async {
    try {
      final nextRunTime = _calculateNextRunTime(
        reminderDetail.reminder.rrule,
        reminderDetail.reminder.nextRunAt,
      );

      if (nextRunTime != null) {
        await _database.reminderDao.updateNextRunTime(
          reminderDetail.reminder.id,
          nextRunTime,
        );
      } else {
        // No more occurrences, disable the reminder
        await _database.reminderDao.disableReminder(reminderDetail.reminder.id);
      }
    } catch (e) {
      debugPrint('Error updating next run time: $e');
    }
  }

  /// Get reminder title based on type
  String _getReminderTitle(ReminderWithDetails reminderDetail) {
    final scope = reminderDetail.scope;
    return switch (scope) {
      ReminderScope.group => 'Group Reminder',
      ReminderScope.member => 'Member Reminder',
    };
  }

  /// Get reminder body based on type
  String _getReminderBody(ReminderWithDetails reminderDetail) {
    final scope = reminderDetail.scope;
    final targetName = reminderDetail.targetName;
    
    return switch (scope) {
      ReminderScope.group => 'Don\'t forget to add expenses for $targetName',
      ReminderScope.member => 'Reminder for $targetName',
    };
  }

  /// Get reminder payload for navigation
  String _getReminderPayload(ReminderWithDetails reminderDetail) {
    final scope = reminderDetail.scope;
    final scopeId = reminderDetail.reminder.scopeId;
    
    return jsonEncode({
      'type': scope.value.toLowerCase(),
      'id': scopeId,
    });
  }

  /// Calculate next run time based on RRULE
  DateTime? _calculateNextRunTime(String rrule, DateTime currentTime) {
    try {
      // Simple RRULE parsing - extend this for more complex rules
      final parts = rrule.split(';');
      String? freq;
      int? interval;
      int? count;
      DateTime? until;

      for (final part in parts) {
        final keyValue = part.split('=');
        if (keyValue.length != 2) continue;

        final key = keyValue[0].trim();
        final value = keyValue[1].trim();

        switch (key) {
          case 'FREQ':
            freq = value;
            break;
          case 'INTERVAL':
            interval = int.tryParse(value);
            break;
          case 'COUNT':
            count = int.tryParse(value);
            break;
          case 'UNTIL':
            until = DateTime.tryParse(value);
            break;
        }
      }

      if (freq == null) return null;

      final intervalValue = interval ?? 1;
      DateTime nextTime;

      switch (freq) {
        case 'DAILY':
          nextTime = currentTime.add(Duration(days: intervalValue));
          break;
        case 'WEEKLY':
          nextTime = currentTime.add(Duration(days: 7 * intervalValue));
          break;
        case 'MONTHLY':
          nextTime = DateTime(
            currentTime.year,
            currentTime.month + intervalValue,
            currentTime.day,
            currentTime.hour,
            currentTime.minute,
          );
          break;
        case 'YEARLY':
          nextTime = DateTime(
            currentTime.year + intervalValue,
            currentTime.month,
            currentTime.day,
            currentTime.hour,
            currentTime.minute,
          );
          break;
        default:
          return null;
      }

      // Check if we've exceeded the until date
      if (until != null && nextTime.isAfter(until)) {
        return null;
      }

      return nextTime;
    } catch (e) {
      debugPrint('Error calculating next run time: $e');
      return null;
    }
  }

  /// Convert DateTime to TZDateTime (simplified - assumes local timezone)
  /// In a real app, you'd want to use the timezone package
  dynamic _convertToTZDateTime(DateTime dateTime) {
    // For now, just return the DateTime
    // In production, convert to proper TZDateTime
    return dateTime;
  }
}

/// Reminder notification types
enum ReminderNotificationType {
  groupExpense,
  settlement,
  backup,
  custom;

  String get displayName => switch (this) {
    ReminderNotificationType.groupExpense => 'Group Expense',
    ReminderNotificationType.settlement => 'Settlement',
    ReminderNotificationType.backup => 'Backup',
    ReminderNotificationType.custom => 'Custom',
  };
}

/// Reminder frequency options
enum ReminderFrequency {
  once,
  daily,
  weekly,
  monthly,
  yearly;

  String get displayName => switch (this) {
    ReminderFrequency.once => 'Once',
    ReminderFrequency.daily => 'Daily',
    ReminderFrequency.weekly => 'Weekly',
    ReminderFrequency.monthly => 'Monthly',
    ReminderFrequency.yearly => 'Yearly',
  };

  String get rruleFreq => switch (this) {
    ReminderFrequency.once => '',
    ReminderFrequency.daily => 'DAILY',
    ReminderFrequency.weekly => 'WEEKLY',
    ReminderFrequency.monthly => 'MONTHLY',
    ReminderFrequency.yearly => 'YEARLY',
  };
}

/// RRULE builder for creating reminder schedules
class RRuleBuilder {
  String? _freq;
  int? _interval;
  int? _count;
  DateTime? _until;

  RRuleBuilder frequency(ReminderFrequency freq) {
    _freq = freq.rruleFreq;
    return this;
  }

  RRuleBuilder interval(int interval) {
    _interval = interval;
    return this;
  }

  RRuleBuilder count(int count) {
    _count = count;
    return this;
  }

  RRuleBuilder until(DateTime until) {
    _until = until;
    return this;
  }

  String build() {
    if (_freq == null || _freq!.isEmpty) {
      return ''; // One-time reminder
    }

    final parts = <String>['FREQ=$_freq'];

    if (_interval != null && _interval! > 1) {
      parts.add('INTERVAL=$_interval');
    }

    if (_count != null) {
      parts.add('COUNT=$_count');
    }

    if (_until != null) {
      parts.add('UNTIL=${_until!.toIso8601String()}');
    }

    return parts.join(';');
  }
}

/// Provider for reminder scheduler
final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  final database = ref.watch(databaseProvider);
  final notificationsPlugin = ref.watch(notificationsProvider);
  
  return ReminderScheduler(
    database: database,
    notificationsPlugin: notificationsPlugin,
  );
});

/// Provider for database (to be defined in main.dart)
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Database provider should be overridden in main.dart');
});

/// Provider for notifications plugin (to be defined in main.dart)
final notificationsProvider = Provider<FlutterLocalNotificationsPlugin>((ref) {
  throw UnimplementedError('Notifications provider should be overridden in main.dart');
});

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'reminder_dao.g.dart';

/// Data Access Object for reminders
@DriftAccessor(tables: [Reminders, Groups, Members])
class ReminderDao extends DatabaseAccessor<AppDatabase> with _$ReminderDaoMixin {
  ReminderDao(AppDatabase db) : super(db);

  /// Get all active reminders
  Future<List<ReminderWithDetails>> getAllActiveReminders() {
    return _getRemindersWithDetails(enabledOnly: true);
  }

  /// Get all reminders (including disabled)
  Future<List<ReminderWithDetails>> getAllReminders() {
    return _getRemindersWithDetails(enabledOnly: false);
  }

  /// Get reminders for a specific group
  Future<List<ReminderWithDetails>> getRemindersForGroup(String groupId) {
    return _getRemindersWithDetails(
      enabledOnly: false,
      scope: ReminderScope.group,
      scopeId: groupId,
    );
  }

  /// Get reminders for a specific member
  Future<List<ReminderWithDetails>> getRemindersForMember(String memberId) {
    return _getRemindersWithDetails(
      enabledOnly: false,
      scope: ReminderScope.member,
      scopeId: memberId,
    );
  }

  /// Get reminders that are due to run
  Future<List<ReminderWithDetails>> getDueReminders() {
    final now = DateTime.now();
    
    final query = select(reminders)
      ..where((r) => r.enabled.equals(true) & r.nextRunAt.isSmallerOrEqualValue(now))
      ..orderBy([(r) => OrderingTerm.asc(r.nextRunAt)]);

    return query.get().then((reminderList) async {
      final result = <ReminderWithDetails>[];
      for (final reminder in reminderList) {
        final details = await _getReminderDetails(reminder);
        result.add(details);
      }
      return result;
    });
  }

  /// Create a new reminder
  Future<String> createReminder({
    required ReminderScope scope,
    required String scopeId,
    required String rrule,
    required DateTime nextRunAt,
    bool enabled = true,
  }) async {
    final reminderId = _generateId();
    
    await into(reminders).insert(
      RemindersCompanion.insert(
        id: reminderId,
        scope: scope.value,
        scopeId: scopeId,
        rrule: rrule,
        nextRunAt: nextRunAt,
        enabled: Value(enabled),
        createdAt: DateTime.now(),
      ),
    );

    return reminderId;
  }

  /// Update a reminder
  Future<bool> updateReminder({
    required String reminderId,
    String? rrule,
    DateTime? nextRunAt,
    bool? enabled,
  }) async {
    final updates = RemindersCompanion(
      rrule: rrule != null ? Value(rrule) : const Value.absent(),
      nextRunAt: nextRunAt != null ? Value(nextRunAt) : const Value.absent(),
      enabled: enabled != null ? Value(enabled) : const Value.absent(),
    );

    final rowsAffected = await (update(reminders)..where((r) => r.id.equals(reminderId))).write(updates);
    return rowsAffected > 0;
  }

  /// Enable a reminder
  Future<bool> enableReminder(String reminderId) {
    return updateReminder(reminderId: reminderId, enabled: true);
  }

  /// Disable a reminder
  Future<bool> disableReminder(String reminderId) {
    return updateReminder(reminderId: reminderId, enabled: false);
  }

  /// Delete a reminder
  Future<bool> deleteReminder(String reminderId) async {
    final rowsAffected = await (delete(reminders)..where((r) => r.id.equals(reminderId))).go();
    return rowsAffected > 0;
  }

  /// Update next run time for a reminder (after it has been executed)
  Future<bool> updateNextRunTime(String reminderId, DateTime nextRunAt) {
    return updateReminder(reminderId: reminderId, nextRunAt: nextRunAt);
  }

  /// Get reminder by ID
  Future<ReminderWithDetails?> getReminderById(String reminderId) async {
    final reminder = await (select(reminders)..where((r) => r.id.equals(reminderId))).getSingleOrNull();
    if (reminder == null) return null;

    return await _getReminderDetails(reminder);
  }

  /// Delete all reminders for a group
  Future<void> deleteRemindersForGroup(String groupId) async {
    await (delete(reminders)
      ..where((r) => r.scope.equals(ReminderScope.group.value) & r.scopeId.equals(groupId))
    ).go();
  }

  /// Delete all reminders for a member
  Future<void> deleteRemindersForMember(String memberId) async {
    await (delete(reminders)
      ..where((r) => r.scope.equals(ReminderScope.member.value) & r.scopeId.equals(memberId))
    ).go();
  }

  /// Get reminder statistics
  Future<ReminderStats> getReminderStats() async {
    // Count total reminders
    final totalCount = await (selectOnly(reminders)
      ..addColumns([reminders.id.count()])
    ).getSingle().then((r) => r.read(reminders.id.count()) ?? 0);

    // Count enabled reminders
    final enabledCount = await (selectOnly(reminders)
      ..addColumns([reminders.id.count()])
      ..where(reminders.enabled.equals(true))
    ).getSingle().then((r) => r.read(reminders.id.count()) ?? 0);

    // Count group reminders
    final groupCount = await (selectOnly(reminders)
      ..addColumns([reminders.id.count()])
      ..where(reminders.scope.equals(ReminderScope.group.value))
    ).getSingle().then((r) => r.read(reminders.id.count()) ?? 0);

    // Count member reminders
    final memberCount = await (selectOnly(reminders)
      ..addColumns([reminders.id.count()])
      ..where(reminders.scope.equals(ReminderScope.member.value))
    ).getSingle().then((r) => r.read(reminders.id.count()) ?? 0);

    // Count due reminders
    final now = DateTime.now();
    final dueCount = await (selectOnly(reminders)
      ..addColumns([reminders.id.count()])
      ..where(reminders.enabled.equals(true) & reminders.nextRunAt.isSmallerOrEqualValue(now))
    ).getSingle().then((r) => r.read(reminders.id.count()) ?? 0);

    return ReminderStats(
      totalCount: totalCount,
      enabledCount: enabledCount,
      groupCount: groupCount,
      memberCount: memberCount,
      dueCount: dueCount,
    );
  }

  /// Clean up old disabled reminders
  Future<int> cleanupOldReminders({
    Duration retentionPeriod = const Duration(days: 90),
  }) async {
    final cutoffDate = DateTime.now().subtract(retentionPeriod);
    return await (delete(reminders)
      ..where((r) => r.enabled.equals(false) & r.createdAt.isSmallerThanValue(cutoffDate))
    ).go();
  }

  /// Get reminders with details
  Future<List<ReminderWithDetails>> _getRemindersWithDetails({
    required bool enabledOnly,
    ReminderScope? scope,
    String? scopeId,
  }) async {
    final query = select(reminders);

    if (enabledOnly) {
      query.where((r) => r.enabled.equals(true));
    }

    if (scope != null) {
      query.where((r) => r.scope.equals(scope.value));
    }

    if (scopeId != null) {
      query.where((r) => r.scopeId.equals(scopeId));
    }

    query.orderBy([(r) => OrderingTerm.asc(r.nextRunAt)]);

    final reminderList = await query.get();
    final result = <ReminderWithDetails>[];

    for (final reminder in reminderList) {
      final details = await _getReminderDetails(reminder);
      result.add(details);
    }

    return result;
  }

  /// Get reminder details (group or member info)
  Future<ReminderWithDetails> _getReminderDetails(Reminder reminder) async {
    final scope = ReminderScope.fromString(reminder.scope);
    
    Group? group;
    Member? member;

    if (scope == ReminderScope.group) {
      group = await (select(groups)..where((g) => g.id.equals(reminder.scopeId))).getSingleOrNull();
    } else if (scope == ReminderScope.member) {
      member = await (select(members)..where((m) => m.id.equals(reminder.scopeId))).getSingleOrNull();
    }

    return ReminderWithDetails(
      reminder: reminder,
      group: group,
      member: member,
    );
  }

  /// Generate a unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
  }
}

/// Reminder with related details
class ReminderWithDetails {
  final Reminder reminder;
  final Group? group;
  final Member? member;

  const ReminderWithDetails({
    required this.reminder,
    required this.group,
    required this.member,
  });

  /// Get reminder scope
  ReminderScope get scope => ReminderScope.fromString(reminder.scope);

  /// Get display name for the reminder target
  String get targetName {
    if (group != null) return group!.name;
    if (member != null) return member!.displayName;
    return 'Unknown';
  }

  /// Get display description
  String get description {
    final target = scope == ReminderScope.group ? 'Group: $targetName' : 'Member: $targetName';
    return 'Reminder for $target';
  }

  /// Check if reminder is due
  bool get isDue => DateTime.now().isAfter(reminder.nextRunAt);

  /// Check if reminder is overdue (more than 1 hour past due time)
  bool get isOverdue => DateTime.now().isAfter(reminder.nextRunAt.add(const Duration(hours: 1)));

  @override
  String toString() => 'ReminderWithDetails($description, next: ${reminder.nextRunAt})';
}

/// Reminder statistics
class ReminderStats {
  final int totalCount;
  final int enabledCount;
  final int groupCount;
  final int memberCount;
  final int dueCount;

  const ReminderStats({
    required this.totalCount,
    required this.enabledCount,
    required this.groupCount,
    required this.memberCount,
    required this.dueCount,
  });

  /// Get disabled count
  int get disabledCount => totalCount - enabledCount;

  /// Check if there are any due reminders
  bool get hasDueReminders => dueCount > 0;

  @override
  String toString() => 'ReminderStats('
      'total: $totalCount, '
      'enabled: $enabledCount, '
      'due: $dueCount, '
      'groups: $groupCount, '
      'members: $memberCount)';
}

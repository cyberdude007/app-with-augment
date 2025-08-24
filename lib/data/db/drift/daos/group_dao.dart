import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';
import '../../../../core/money/money.dart';

part 'group_dao.g.dart';

/// Data Access Object for groups
@DriftAccessor(tables: [Groups, GroupMembers, Members, Expenses, SplitShares, Settlements])
class GroupDao extends DatabaseAccessor<AppDatabase> with _$GroupDaoMixin {
  GroupDao(AppDatabase db) : super(db);

  /// Get all active groups (not archived)
  Future<List<GroupWithStats>> getAllActiveGroups() {
    return _getGroupsWithStats(includeArchived: false);
  }

  /// Get all groups including archived ones
  Future<List<GroupWithStats>> getAllGroups() {
    return _getGroupsWithStats(includeArchived: true);
  }

  /// Get group by ID
  Future<Group?> getGroupById(String groupId) {
    return (select(groups)..where((g) => g.id.equals(groupId))).getSingleOrNull();
  }

  /// Get group with stats by ID
  Future<GroupWithStats?> getGroupWithStatsById(String groupId) async {
    final group = await getGroupById(groupId);
    if (group == null) return null;

    final stats = await _getGroupStats(groupId);
    return GroupWithStats(group: group, stats: stats);
  }

  /// Search groups by name
  Future<List<GroupWithStats>> searchGroups(String query) async {
    final groupsQuery = select(groups)
      ..where((g) => g.name.contains(query) & g.archived.equals(false))
      ..orderBy([(g) => OrderingTerm.asc(g.name)]);

    final groupList = await groupsQuery.get();
    final groupsWithStats = <GroupWithStats>[];

    for (final group in groupList) {
      final stats = await _getGroupStats(group.id);
      groupsWithStats.add(GroupWithStats(group: group, stats: stats));
    }

    return groupsWithStats;
  }

  /// Create a new group
  Future<String> createGroup({
    required String name,
    List<String> initialMemberIds = const [],
  }) async {
    return await transaction(() async {
      final groupId = _generateId();
      
      // Create the group
      await into(groups).insert(
        GroupsCompanion.insert(
          id: groupId,
          name: name,
          createdAt: DateTime.now(),
        ),
      );

      // Add initial members
      for (final memberId in initialMemberIds) {
        await into(groupMembers).insert(
          GroupMembersCompanion.insert(
            id: _generateId(),
            groupId: groupId,
            memberId: memberId,
            joinDate: DateTime.now(),
          ),
        );
      }

      return groupId;
    });
  }

  /// Update a group
  Future<bool> updateGroup({
    required String groupId,
    String? name,
    bool? archived,
  }) async {
    final updates = GroupsCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      archived: archived != null ? Value(archived) : const Value.absent(),
    );

    final rowsAffected = await (update(groups)..where((g) => g.id.equals(groupId))).write(updates);
    return rowsAffected > 0;
  }

  /// Archive a group
  Future<bool> archiveGroup(String groupId) {
    return updateGroup(groupId: groupId, archived: true);
  }

  /// Unarchive a group
  Future<bool> unarchiveGroup(String groupId) {
    return updateGroup(groupId: groupId, archived: false);
  }

  /// Delete a group (only if no expenses exist)
  Future<bool> deleteGroup(String groupId) async {
    return await transaction(() async {
      // Check if group has any expenses
      final expenseCount = await (selectOnly(expenses)
        ..addColumns([expenses.id.count()])
        ..where(expenses.groupId.equals(groupId))
      ).getSingle().then((r) => r.read(expenses.id.count()) ?? 0);

      if (expenseCount > 0) {
        return false; // Cannot delete group with expenses
      }

      // Delete group members
      await (delete(groupMembers)..where((gm) => gm.groupId.equals(groupId))).go();
      
      // Delete settlements
      await (delete(settlements)..where((s) => s.groupId.equals(groupId))).go();
      
      // Delete reminders
      await (delete(db.reminders)..where((r) => r.scopeId.equals(groupId))).go();
      
      // Delete the group
      final rowsAffected = await (delete(groups)..where((g) => g.id.equals(groupId))).go();
      return rowsAffected > 0;
    });
  }

  /// Get group balance summary
  Future<GroupBalanceSummary> getGroupBalanceSummary(String groupId) async {
    // Get all expenses in the group
    final groupExpenses = await (select(expenses)
      ..where((e) => e.groupId.equals(groupId))
    ).get();

    // Get all split shares for group expenses
    final expenseIds = groupExpenses.map((e) => e.id).toList();
    if (expenseIds.isEmpty) {
      return GroupBalanceSummary(
        totalSpent: Money.zero,
        memberBalances: {},
        creditors: {},
        debtors: {},
      );
    }

    final shares = await (select(splitShares)
      ..where((s) => s.expenseId.isIn(expenseIds))
    ).get();

    // Get all settlements in the group
    final groupSettlements = await (select(settlements)
      ..where((s) => s.groupId.equals(groupId))
    ).get();

    // Calculate net balances
    final balances = <String, Money>{};
    Money totalSpent = Money.zero;

    // Add expense amounts (what each member paid)
    for (final expense in groupExpenses) {
      final payerId = expense.payerMemberId;
      final amount = Money.fromPaise(expense.amountMinor);
      balances[payerId] = (balances[payerId] ?? Money.zero) + amount;
      totalSpent = totalSpent + amount;
    }

    // Subtract share amounts (what each member owes)
    for (final share in shares) {
      final memberId = share.memberId;
      final amount = Money.fromPaise(share.shareMinor);
      balances[memberId] = (balances[memberId] ?? Money.zero) - amount;
    }

    // Apply settlements
    for (final settlement in groupSettlements) {
      final fromId = settlement.fromMemberId;
      final toId = settlement.toMemberId;
      final amount = Money.fromPaise(settlement.amountMinor);
      
      balances[fromId] = (balances[fromId] ?? Money.zero) + amount;
      balances[toId] = (balances[toId] ?? Money.zero) - amount;
    }

    // Separate creditors and debtors
    final creditors = <String, Money>{};
    final debtors = <String, Money>{};

    for (final entry in balances.entries) {
      final memberId = entry.key;
      final balance = entry.value;

      if (balance.isPositive) {
        creditors[memberId] = balance;
      } else if (balance.isNegative) {
        debtors[memberId] = balance.abs;
      }
    }

    return GroupBalanceSummary(
      totalSpent: totalSpent,
      memberBalances: balances,
      creditors: creditors,
      debtors: debtors,
    );
  }

  /// Get recent activity for a group
  Future<List<GroupActivity>> getGroupActivity({
    required String groupId,
    int limit = 20,
  }) async {
    final activities = <GroupActivity>[];

    // Get recent expenses
    final recentExpenses = await (select(expenses).join([
      leftOuterJoin(members, members.id.equalsExp(expenses.payerMemberId)),
    ])
      ..where(expenses.groupId.equals(groupId))
      ..orderBy([OrderingTerm.desc(expenses.createdAt)])
      ..limit(limit)
    ).get();

    for (final row in recentExpenses) {
      final expense = row.readTable(expenses);
      final payer = row.readTableOrNull(members);
      
      activities.add(GroupActivity(
        type: GroupActivityType.expense,
        timestamp: expense.createdAt,
        description: expense.description,
        amount: Money.fromPaise(expense.amountMinor),
        memberName: payer?.displayName ?? 'Unknown',
      ));
    }

    // Get recent settlements
    final recentSettlements = await (select(settlements).join([
      leftOuterJoin(members, members.id.equalsExp(settlements.fromMemberId)),
    ])
      ..where(settlements.groupId.equals(groupId))
      ..orderBy([OrderingTerm.desc(settlements.createdAt)])
      ..limit(limit)
    ).get();

    for (final row in recentSettlements) {
      final settlement = row.readTable(settlements);
      final fromMember = row.readTableOrNull(members);
      
      activities.add(GroupActivity(
        type: GroupActivityType.settlement,
        timestamp: settlement.createdAt,
        description: 'Settlement payment',
        amount: Money.fromPaise(settlement.amountMinor),
        memberName: fromMember?.displayName ?? 'Unknown',
      ));
    }

    // Sort by timestamp (newest first) and limit
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activities.take(limit).toList();
  }

  /// Get groups with stats
  Future<List<GroupWithStats>> _getGroupsWithStats({required bool includeArchived}) async {
    final query = select(groups);
    if (!includeArchived) {
      query.where((g) => g.archived.equals(false));
    }
    query.orderBy([(g) => OrderingTerm.asc(g.name)]);

    final groupList = await query.get();
    final groupsWithStats = <GroupWithStats>[];

    for (final group in groupList) {
      final stats = await _getGroupStats(group.id);
      groupsWithStats.add(GroupWithStats(group: group, stats: stats));
    }

    return groupsWithStats;
  }

  /// Get statistics for a group
  Future<GroupStats> _getGroupStats(String groupId) async {
    // Count members
    final memberCount = await (selectOnly(groupMembers)
      ..addColumns([groupMembers.id.count()])
      ..where(groupMembers.groupId.equals(groupId))
    ).getSingle().then((r) => r.read(groupMembers.id.count()) ?? 0);

    // Count expenses
    final expenseCount = await (selectOnly(expenses)
      ..addColumns([expenses.id.count()])
      ..where(expenses.groupId.equals(groupId))
    ).getSingle().then((r) => r.read(expenses.id.count()) ?? 0);

    // Sum total spent
    final totalSpentPaise = await (selectOnly(expenses)
      ..addColumns([expenses.amountMinor.sum()])
      ..where(expenses.groupId.equals(groupId))
    ).getSingle().then((r) => r.read(expenses.amountMinor.sum()) ?? 0);

    // Get last activity
    final lastExpense = await (select(expenses)
      ..where((e) => e.groupId.equals(groupId))
      ..orderBy([(e) => OrderingTerm.desc(e.createdAt)])
      ..limit(1)
    ).getSingleOrNull();

    return GroupStats(
      memberCount: memberCount,
      expenseCount: expenseCount,
      totalSpent: Money.fromPaise(totalSpentPaise),
      lastActivity: lastExpense?.createdAt,
    );
  }

  /// Generate a unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
  }
}

/// Group with statistics
class GroupWithStats {
  final Group group;
  final GroupStats stats;

  const GroupWithStats({
    required this.group,
    required this.stats,
  });

  @override
  String toString() => 'GroupWithStats(${group.name}, ${stats.memberCount} members)';
}

/// Group statistics
class GroupStats {
  final int memberCount;
  final int expenseCount;
  final Money totalSpent;
  final DateTime? lastActivity;

  const GroupStats({
    required this.memberCount,
    required this.expenseCount,
    required this.totalSpent,
    required this.lastActivity,
  });

  @override
  String toString() => 'GroupStats(members: $memberCount, expenses: $expenseCount, spent: ${totalSpent.format()})';
}

/// Group balance summary
class GroupBalanceSummary {
  final Money totalSpent;
  final Map<String, Money> memberBalances;
  final Map<String, Money> creditors;
  final Map<String, Money> debtors;

  const GroupBalanceSummary({
    required this.totalSpent,
    required this.memberBalances,
    required this.creditors,
    required this.debtors,
  });

  /// Check if group is settled (no outstanding debts)
  bool get isSettled => creditors.isEmpty && debtors.isEmpty;

  /// Get net balance for a member
  Money getNetBalance(String memberId) => memberBalances[memberId] ?? Money.zero;

  @override
  String toString() => 'GroupBalanceSummary(spent: ${totalSpent.format()}, settled: $isSettled)';
}

/// Group activity item
class GroupActivity {
  final GroupActivityType type;
  final DateTime timestamp;
  final String description;
  final Money amount;
  final String memberName;

  const GroupActivity({
    required this.type,
    required this.timestamp,
    required this.description,
    required this.amount,
    required this.memberName,
  });

  @override
  String toString() => 'GroupActivity(${type.name}: $description by $memberName)';
}

/// Group activity type
enum GroupActivityType {
  expense,
  settlement,
  memberJoined,
  memberLeft;

  String get displayName => switch (this) {
    GroupActivityType.expense => 'Expense',
    GroupActivityType.settlement => 'Settlement',
    GroupActivityType.memberJoined => 'Member Joined',
    GroupActivityType.memberLeft => 'Member Left',
  };
}

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'member_dao.g.dart';

/// Data Access Object for members
@DriftAccessor(tables: [Members, GroupMembers, Groups, MemberInteractions])
class MemberDao extends DatabaseAccessor<AppDatabase> with _$MemberDaoMixin {
  MemberDao(AppDatabase db) : super(db);

  /// Get all members
  Future<List<Member>> getAllMembers() {
    return (select(members)..orderBy([(m) => OrderingTerm.asc(m.displayName)])).get();
  }

  /// Get member by ID
  Future<Member?> getMemberById(String memberId) {
    return (select(members)..where((m) => m.id.equals(memberId))).getSingleOrNull();
  }

  /// Get members by IDs
  Future<List<Member>> getMembersByIds(List<String> memberIds) {
    if (memberIds.isEmpty) return Future.value([]);
    
    return (select(members)
      ..where((m) => m.id.isIn(memberIds))
      ..orderBy([(m) => OrderingTerm.asc(m.displayName)])
    ).get();
  }

  /// Search members by name
  Future<List<Member>> searchMembers(String query) {
    if (query.isEmpty) return getAllMembers();
    
    return (select(members)
      ..where((m) => m.displayName.contains(query))
      ..orderBy([(m) => OrderingTerm.asc(m.displayName)])
    ).get();
  }

  /// Get members in a specific group
  Future<List<MemberWithJoinDate>> getMembersInGroup(String groupId) {
    final query = select(members).join([
      innerJoin(groupMembers, groupMembers.memberId.equalsExp(members.id)),
    ])
      ..where(groupMembers.groupId.equals(groupId))
      ..orderBy([OrderingTerm.asc(members.displayName)]);

    return query.map((row) {
      final member = row.readTable(members);
      final groupMember = row.readTable(groupMembers);
      
      return MemberWithJoinDate(
        member: member,
        joinDate: groupMember.joinDate,
      );
    }).get();
  }

  /// Get groups that a member belongs to
  Future<List<GroupWithJoinDate>> getGroupsForMember(String memberId) {
    final query = select(groups).join([
      innerJoin(groupMembers, groupMembers.groupId.equalsExp(groups.id)),
    ])
      ..where(groupMembers.memberId.equals(memberId) & 
               groups.archived.equals(false))
      ..orderBy([OrderingTerm.asc(groups.name)]);

    return query.map((row) {
      final group = row.readTable(groups);
      final groupMember = row.readTable(groupMembers);
      
      return GroupWithJoinDate(
        group: group,
        joinDate: groupMember.joinDate,
      );
    }).get();
  }

  /// Create a new member
  Future<String> createMember({
    required String displayName,
    String? avatarEmoji,
  }) async {
    final memberId = _generateId();
    
    await into(members).insert(
      MembersCompanion.insert(
        id: memberId,
        displayName: displayName,
        avatarEmoji: Value(avatarEmoji),
        createdAt: DateTime.now(),
      ),
    );

    return memberId;
  }

  /// Update a member
  Future<bool> updateMember({
    required String memberId,
    String? displayName,
    String? avatarEmoji,
  }) async {
    final updates = MembersCompanion(
      displayName: displayName != null ? Value(displayName) : const Value.absent(),
      avatarEmoji: avatarEmoji != null ? Value(avatarEmoji) : const Value.absent(),
    );

    final rowsAffected = await (update(members)..where((m) => m.id.equals(memberId))).write(updates);
    return rowsAffected > 0;
  }

  /// Delete a member (only if not referenced in any expenses or groups)
  Future<bool> deleteMember(String memberId) async {
    return await transaction(() async {
      // Check if member is referenced in any expenses
      final expenseCount = await (selectOnly(db.expenses)
        ..addColumns([db.expenses.id.count()])
        ..where(db.expenses.payerMemberId.equals(memberId))
      ).getSingle().then((r) => r.read(db.expenses.id.count()) ?? 0);

      if (expenseCount > 0) {
        return false; // Cannot delete member with expenses
      }

      // Check if member is in any split shares
      final shareCount = await (selectOnly(db.splitShares)
        ..addColumns([db.splitShares.id.count()])
        ..where(db.splitShares.memberId.equals(memberId))
      ).getSingle().then((r) => r.read(db.splitShares.id.count()) ?? 0);

      if (shareCount > 0) {
        return false; // Cannot delete member with shares
      }

      // Remove from all groups first
      await (delete(groupMembers)..where((gm) => gm.memberId.equals(memberId))).go();
      
      // Delete member interactions
      await (delete(memberInteractions)..where((mi) => mi.memberId.equals(memberId))).go();
      
      // Delete the member
      final rowsAffected = await (delete(members)..where((m) => m.id.equals(memberId))).go();
      return rowsAffected > 0;
    });
  }

  /// Add member to group
  Future<bool> addMemberToGroup({
    required String memberId,
    required String groupId,
  }) async {
    try {
      await into(groupMembers).insert(
        GroupMembersCompanion.insert(
          id: _generateId(),
          groupId: groupId,
          memberId: memberId,
          joinDate: DateTime.now(),
        ),
      );
      return true;
    } catch (e) {
      // Member might already be in the group
      return false;
    }
  }

  /// Remove member from group
  Future<bool> removeMemberFromGroup({
    required String memberId,
    required String groupId,
  }) async {
    final rowsAffected = await (delete(groupMembers)
      ..where((gm) => gm.memberId.equals(memberId) & 
                      gm.groupId.equals(groupId))
    ).go();
    return rowsAffected > 0;
  }

  /// Check if member is in group
  Future<bool> isMemberInGroup({
    required String memberId,
    required String groupId,
  }) async {
    final result = await (select(groupMembers)
      ..where((gm) => gm.memberId.equals(memberId) & 
                      gm.groupId.equals(groupId))
    ).getSingleOrNull();
    return result != null;
  }

  /// Get member count in group
  Future<int> getMemberCountInGroup(String groupId) async {
    final result = await (selectOnly(groupMembers)
      ..addColumns([groupMembers.id.count()])
      ..where(groupMembers.groupId.equals(groupId))
    ).getSingle();
    return result.read(groupMembers.id.count()) ?? 0;
  }

  /// Record member interaction for fuzzy search
  Future<void> recordMemberInteraction({
    required String memberId,
    required MemberInteractionType interactionType,
  }) async {
    await into(memberInteractions).insert(
      MemberInteractionsCompanion.insert(
        id: _generateId(),
        memberId: memberId,
        interactionType: interactionType.value,
        interactionAt: DateTime.now(),
      ),
    );
  }

  /// Get recent member interactions for fuzzy search scoring
  Future<Map<String, double>> getRecentMemberInteractions({
    Duration lookbackPeriod = const Duration(days: 30),
  }) async {
    final cutoffDate = DateTime.now().subtract(lookbackPeriod);
    
    final query = selectOnly(memberInteractions)
      ..addColumns([memberInteractions.memberId, memberInteractions.interactionAt.max()])
      ..where(memberInteractions.interactionAt.isBiggerThanValue(cutoffDate))
      ..groupBy([memberInteractions.memberId]);

    final results = await query.get();
    final scores = <String, double>{};

    final now = DateTime.now();
    for (final row in results) {
      final memberId = row.read(memberInteractions.memberId)!;
      final lastInteraction = row.read(memberInteractions.interactionAt.max())!;
      
      final daysSince = now.difference(lastInteraction).inDays;
      final score = 1.0 - (daysSince / lookbackPeriod.inDays);
      scores[memberId] = score.clamp(0.0, 1.0);
    }

    return scores;
  }

  /// Clean up old member interactions
  Future<void> cleanupOldInteractions({
    Duration retentionPeriod = const Duration(days: 90),
  }) async {
    final cutoffDate = DateTime.now().subtract(retentionPeriod);
    await (delete(memberInteractions)
      ..where((mi) => mi.interactionAt.isSmallerThanValue(cutoffDate))
    ).go();
  }

  /// Get member statistics
  Future<MemberStats> getMemberStats(String memberId) async {
    // Count groups
    final groupCount = await (selectOnly(groupMembers)
      ..addColumns([groupMembers.id.count()])
      ..where(groupMembers.memberId.equals(memberId))
    ).getSingle().then((r) => r.read(groupMembers.id.count()) ?? 0);

    // Count expenses as payer
    final expenseCount = await (selectOnly(db.expenses)
      ..addColumns([db.expenses.id.count()])
      ..where(db.expenses.payerMemberId.equals(memberId))
    ).getSingle().then((r) => r.read(db.expenses.id.count()) ?? 0);

    // Count split shares
    final shareCount = await (selectOnly(db.splitShares)
      ..addColumns([db.splitShares.id.count()])
      ..where(db.splitShares.memberId.equals(memberId))
    ).getSingle().then((r) => r.read(db.splitShares.id.count()) ?? 0);

    return MemberStats(
      groupCount: groupCount,
      expenseCount: expenseCount,
      shareCount: shareCount,
    );
  }

  /// Generate a unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
  }
}

/// Member with join date information
class MemberWithJoinDate {
  final Member member;
  final DateTime joinDate;

  const MemberWithJoinDate({
    required this.member,
    required this.joinDate,
  });

  @override
  String toString() => 'MemberWithJoinDate(${member.displayName}, joined: $joinDate)';
}

/// Group with join date information
class GroupWithJoinDate {
  final Group group;
  final DateTime joinDate;

  const GroupWithJoinDate({
    required this.group,
    required this.joinDate,
  });

  @override
  String toString() => 'GroupWithJoinDate(${group.name}, joined: $joinDate)';
}

/// Member statistics
class MemberStats {
  final int groupCount;
  final int expenseCount;
  final int shareCount;

  const MemberStats({
    required this.groupCount,
    required this.expenseCount,
    required this.shareCount,
  });

  @override
  String toString() => 'MemberStats(groups: $groupCount, expenses: $expenseCount, shares: $shareCount)';
}

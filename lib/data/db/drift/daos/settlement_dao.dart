import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';
import '../../../../core/money/money.dart';

part 'settlement_dao.g.dart';

/// Data Access Object for settlements
@DriftAccessor(tables: [Settlements, Members, Groups])
class SettlementDao extends DatabaseAccessor<AppDatabase> with _$SettlementDaoMixin {
  SettlementDao(AppDatabase db) : super(db);

  /// Get all settlements for a group
  Future<List<SettlementWithDetails>> getSettlementsForGroup(String groupId) {
    final query = select(settlements).join([
      leftOuterJoin(members, members.id.equalsExp(settlements.fromMemberId), useColumns: false),
      leftOuterJoin(members, members.id.equalsExp(settlements.toMemberId), useColumns: false),
    ])
      ..where(settlements.groupId.equals(groupId))
      ..orderBy([OrderingTerm.desc(settlements.createdAt)]);

    return query.map((row) {
      final settlement = row.readTable(settlements);
      // Note: We need to get from/to members separately due to self-join
      return SettlementWithDetails(
        settlement: settlement,
        fromMember: null, // Will be populated separately
        toMember: null,   // Will be populated separately
      );
    }).get().then((settlements) async {
      // Populate member details separately
      final result = <SettlementWithDetails>[];
      for (final settlementDetail in settlements) {
        final fromMember = await (select(members)
          ..where((m) => m.id.equals(settlementDetail.settlement.fromMemberId))
        ).getSingleOrNull();
        
        final toMember = await (select(members)
          ..where((m) => m.id.equals(settlementDetail.settlement.toMemberId))
        ).getSingleOrNull();

        result.add(SettlementWithDetails(
          settlement: settlementDetail.settlement,
          fromMember: fromMember,
          toMember: toMember,
        ));
      }
      return result;
    });
  }

  /// Get settlements involving a specific member
  Future<List<SettlementWithDetails>> getSettlementsForMember(String memberId) {
    final query = select(settlements)
      ..where((s) => s.fromMemberId.equals(memberId) | s.toMemberId.equals(memberId))
      ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]);

    return query.get().then((settlements) async {
      final result = <SettlementWithDetails>[];
      for (final settlement in settlements) {
        final fromMember = await (select(members)
          ..where((m) => m.id.equals(settlement.fromMemberId))
        ).getSingleOrNull();
        
        final toMember = await (select(members)
          ..where((m) => m.id.equals(settlement.toMemberId))
        ).getSingleOrNull();

        result.add(SettlementWithDetails(
          settlement: settlement,
          fromMember: fromMember,
          toMember: toMember,
        ));
      }
      return result;
    });
  }

  /// Get settlements by date range
  Future<List<SettlementWithDetails>> getSettlementsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? groupId,
    String? memberId,
  }) {
    final query = select(settlements);

    Expression<bool> whereClause = settlements.createdAt.isBetweenValues(startDate, endDate);

    if (groupId != null) {
      whereClause = whereClause & settlements.groupId.equals(groupId);
    }

    if (memberId != null) {
      whereClause = whereClause & 
          (settlements.fromMemberId.equals(memberId) | settlements.toMemberId.equals(memberId));
    }

    query
      ..where(whereClause)
      ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]);

    return query.get().then((settlements) async {
      final result = <SettlementWithDetails>[];
      for (final settlement in settlements) {
        final fromMember = await (select(members)
          ..where((m) => m.id.equals(settlement.fromMemberId))
        ).getSingleOrNull();
        
        final toMember = await (select(members)
          ..where((m) => m.id.equals(settlement.toMemberId))
        ).getSingleOrNull();

        result.add(SettlementWithDetails(
          settlement: settlement,
          fromMember: fromMember,
          toMember: toMember,
        ));
      }
      return result;
    });
  }

  /// Create a new settlement
  Future<String> createSettlement({
    required String groupId,
    required String fromMemberId,
    required String toMemberId,
    required Money amount,
  }) async {
    if (fromMemberId == toMemberId) {
      throw ArgumentError('Cannot create settlement from member to themselves');
    }

    if (amount.isZero || amount.isNegative) {
      throw ArgumentError('Settlement amount must be positive');
    }

    final settlementId = _generateId();
    
    await into(settlements).insert(
      SettlementsCompanion.insert(
        id: settlementId,
        groupId: groupId,
        fromMemberId: fromMemberId,
        toMemberId: toMemberId,
        amountMinor: amount.paise,
        createdAt: DateTime.now(),
      ),
    );

    return settlementId;
  }

  /// Update a settlement
  Future<bool> updateSettlement({
    required String settlementId,
    Money? amount,
  }) async {
    if (amount != null && (amount.isZero || amount.isNegative)) {
      throw ArgumentError('Settlement amount must be positive');
    }

    final updates = SettlementsCompanion(
      amountMinor: amount != null ? Value(amount.paise) : const Value.absent(),
    );

    final rowsAffected = await (update(settlements)..where((s) => s.id.equals(settlementId))).write(updates);
    return rowsAffected > 0;
  }

  /// Delete a settlement
  Future<bool> deleteSettlement(String settlementId) async {
    final rowsAffected = await (delete(settlements)..where((s) => s.id.equals(settlementId))).go();
    return rowsAffected > 0;
  }

  /// Get settlement by ID
  Future<SettlementWithDetails?> getSettlementById(String settlementId) async {
    final settlement = await (select(settlements)..where((s) => s.id.equals(settlementId))).getSingleOrNull();
    if (settlement == null) return null;

    final fromMember = await (select(members)
      ..where((m) => m.id.equals(settlement.fromMemberId))
    ).getSingleOrNull();
    
    final toMember = await (select(members)
      ..where((m) => m.id.equals(settlement.toMemberId))
    ).getSingleOrNull();

    return SettlementWithDetails(
      settlement: settlement,
      fromMember: fromMember,
      toMember: toMember,
    );
  }

  /// Get total settlements for a group
  Future<Money> getTotalSettlementsForGroup(String groupId) async {
    final result = await (selectOnly(settlements)
      ..addColumns([settlements.amountMinor.sum()])
      ..where(settlements.groupId.equals(groupId))
    ).getSingle();

    final totalPaise = result.read(settlements.amountMinor.sum()) ?? 0;
    return Money.fromPaise(totalPaise);
  }

  /// Get net settlement amount for a member (positive = received, negative = paid)
  Future<Money> getNetSettlementsForMember(String memberId) async {
    // Amount received (as toMember)
    final receivedResult = await (selectOnly(settlements)
      ..addColumns([settlements.amountMinor.sum()])
      ..where(settlements.toMemberId.equals(memberId))
    ).getSingle();
    final receivedPaise = receivedResult.read(settlements.amountMinor.sum()) ?? 0;

    // Amount paid (as fromMember)
    final paidResult = await (selectOnly(settlements)
      ..addColumns([settlements.amountMinor.sum()])
      ..where(settlements.fromMemberId.equals(memberId))
    ).getSingle();
    final paidPaise = paidResult.read(settlements.amountMinor.sum()) ?? 0;

    return Money.fromPaise(receivedPaise - paidPaise);
  }

  /// Get net settlement amount for a member in a specific group
  Future<Money> getNetSettlementsForMemberInGroup({
    required String memberId,
    required String groupId,
  }) async {
    // Amount received (as toMember)
    final receivedResult = await (selectOnly(settlements)
      ..addColumns([settlements.amountMinor.sum()])
      ..where(settlements.toMemberId.equals(memberId) & settlements.groupId.equals(groupId))
    ).getSingle();
    final receivedPaise = receivedResult.read(settlements.amountMinor.sum()) ?? 0;

    // Amount paid (as fromMember)
    final paidResult = await (selectOnly(settlements)
      ..addColumns([settlements.amountMinor.sum()])
      ..where(settlements.fromMemberId.equals(memberId) & settlements.groupId.equals(groupId))
    ).getSingle();
    final paidPaise = paidResult.read(settlements.amountMinor.sum()) ?? 0;

    return Money.fromPaise(receivedPaise - paidPaise);
  }

  /// Get settlement statistics for a member
  Future<SettlementStats> getSettlementStatsForMember(String memberId) async {
    // Count settlements paid
    final paidCount = await (selectOnly(settlements)
      ..addColumns([settlements.id.count()])
      ..where(settlements.fromMemberId.equals(memberId))
    ).getSingle().then((r) => r.read(settlements.id.count()) ?? 0);

    // Count settlements received
    final receivedCount = await (selectOnly(settlements)
      ..addColumns([settlements.id.count()])
      ..where(settlements.toMemberId.equals(memberId))
    ).getSingle().then((r) => r.read(settlements.id.count()) ?? 0);

    // Total amount paid
    final totalPaidPaise = await (selectOnly(settlements)
      ..addColumns([settlements.amountMinor.sum()])
      ..where(settlements.fromMemberId.equals(memberId))
    ).getSingle().then((r) => r.read(settlements.amountMinor.sum()) ?? 0);

    // Total amount received
    final totalReceivedPaise = await (selectOnly(settlements)
      ..addColumns([settlements.amountMinor.sum()])
      ..where(settlements.toMemberId.equals(memberId))
    ).getSingle().then((r) => r.read(settlements.amountMinor.sum()) ?? 0);

    return SettlementStats(
      settlementsPaid: paidCount,
      settlementsReceived: receivedCount,
      totalPaid: Money.fromPaise(totalPaidPaise),
      totalReceived: Money.fromPaise(totalReceivedPaise),
    );
  }

  /// Check if there are any settlements between two members
  Future<bool> hasSettlementsBetweenMembers({
    required String member1Id,
    required String member2Id,
  }) async {
    final result = await (select(settlements)
      ..where((s) => 
          (s.fromMemberId.equals(member1Id) & s.toMemberId.equals(member2Id)) |
          (s.fromMemberId.equals(member2Id) & s.toMemberId.equals(member1Id)))
      ..limit(1)
    ).getSingleOrNull();
    
    return result != null;
  }

  /// Get recent settlements for activity feed
  Future<List<SettlementWithDetails>> getRecentSettlements({
    int limit = 10,
    String? groupId,
  }) {
    final query = select(settlements);
    
    if (groupId != null) {
      query.where((s) => s.groupId.equals(groupId));
    }
    
    query
      ..orderBy([(s) => OrderingTerm.desc(s.createdAt)])
      ..limit(limit);

    return query.get().then((settlements) async {
      final result = <SettlementWithDetails>[];
      for (final settlement in settlements) {
        final fromMember = await (select(members)
          ..where((m) => m.id.equals(settlement.fromMemberId))
        ).getSingleOrNull();
        
        final toMember = await (select(members)
          ..where((m) => m.id.equals(settlement.toMemberId))
        ).getSingleOrNull();

        result.add(SettlementWithDetails(
          settlement: settlement,
          fromMember: fromMember,
          toMember: toMember,
        ));
      }
      return result;
    });
  }

  /// Generate a unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
  }
}

/// Settlement with member details
class SettlementWithDetails {
  final Settlement settlement;
  final Member? fromMember;
  final Member? toMember;

  const SettlementWithDetails({
    required this.settlement,
    required this.fromMember,
    required this.toMember,
  });

  /// Get settlement amount as Money
  Money get amount => Money.fromPaise(settlement.amountMinor);

  /// Get formatted description
  String get description {
    final fromName = fromMember?.displayName ?? 'Unknown';
    final toName = toMember?.displayName ?? 'Unknown';
    return '$fromName paid $toName ${amount.format()}';
  }

  @override
  String toString() => 'SettlementWithDetails($description)';
}

/// Settlement statistics
class SettlementStats {
  final int settlementsPaid;
  final int settlementsReceived;
  final Money totalPaid;
  final Money totalReceived;

  const SettlementStats({
    required this.settlementsPaid,
    required this.settlementsReceived,
    required this.totalPaid,
    required this.totalReceived,
  });

  /// Get net settlement amount (positive = net receiver, negative = net payer)
  Money get netAmount => totalReceived - totalPaid;

  /// Get total number of settlements
  int get totalSettlements => settlementsPaid + settlementsReceived;

  @override
  String toString() => 'SettlementStats(paid: $settlementsPaid, received: $settlementsReceived, net: ${netAmount.format()})';
}

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';
import '../../../../core/money/money.dart';

part 'share_dao.g.dart';

/// Data Access Object for split shares
@DriftAccessor(tables: [SplitShares, Expenses, Members])
class ShareDao extends DatabaseAccessor<AppDatabase> with _$ShareDaoMixin {
  ShareDao(AppDatabase db) : super(db);

  /// Get all shares for an expense
  Future<List<ShareWithMember>> getSharesForExpense(String expenseId) {
    final query = select(splitShares).join([
      leftOuterJoin(members, members.id.equalsExp(splitShares.memberId)),
    ])
      ..where(splitShares.expenseId.equals(expenseId))
      ..orderBy([OrderingTerm.asc(members.displayName)]);

    return query.map((row) {
      final share = row.readTable(splitShares);
      final member = row.readTableOrNull(members);
      
      return ShareWithMember(
        share: share,
        member: member,
      );
    }).get();
  }

  /// Get all shares for a member across all expenses
  Future<List<ShareWithExpense>> getSharesForMember(String memberId) {
    final query = select(splitShares).join([
      leftOuterJoin(expenses, expenses.id.equalsExp(splitShares.expenseId)),
    ])
      ..where(splitShares.memberId.equals(memberId))
      ..orderBy([OrderingTerm.desc(expenses.createdAt)]);

    return query.map((row) {
      final share = row.readTable(splitShares);
      final expense = row.readTableOrNull(expenses);
      
      return ShareWithExpense(
        share: share,
        expense: expense,
      );
    }).get();
  }

  /// Get shares for a member in a specific group
  Future<List<ShareWithExpense>> getSharesForMemberInGroup({
    required String memberId,
    required String groupId,
  }) {
    final query = select(splitShares).join([
      leftOuterJoin(expenses, expenses.id.equalsExp(splitShares.expenseId)),
    ])
      ..where(splitShares.memberId.equals(memberId) & 
               expenses.groupId.equals(groupId))
      ..orderBy([OrderingTerm.desc(expenses.createdAt)]);

    return query.map((row) {
      final share = row.readTable(splitShares);
      final expense = row.readTableOrNull(expenses);
      
      return ShareWithExpense(
        share: share,
        expense: expense,
      );
    }).get();
  }

  /// Create shares for an expense
  Future<void> createShares({
    required String expenseId,
    required Map<String, Money> memberShares,
  }) async {
    await transaction(() async {
      // Delete existing shares for this expense
      await (delete(splitShares)..where((s) => s.expenseId.equals(expenseId))).go();

      // Insert new shares
      for (final entry in memberShares.entries) {
        final memberId = entry.key;
        final shareAmount = entry.value;

        await into(splitShares).insert(
          SplitSharesCompanion.insert(
            id: _generateId(),
            expenseId: expenseId,
            memberId: memberId,
            shareMinor: shareAmount.paise,
          ),
        );
      }
    });
  }

  /// Update a specific share
  Future<bool> updateShare({
    required String shareId,
    required Money newAmount,
  }) async {
    final rowsAffected = await (update(splitShares)..where((s) => s.id.equals(shareId)))
        .write(SplitSharesCompanion(shareMinor: Value(newAmount.paise)));
    return rowsAffected > 0;
  }

  /// Delete all shares for an expense
  Future<void> deleteSharesForExpense(String expenseId) async {
    await (delete(splitShares)..where((s) => s.expenseId.equals(expenseId))).go();
  }

  /// Get total share amount for a member across all expenses
  Future<Money> getTotalSharesForMember(String memberId) async {
    final result = await (selectOnly(splitShares)
      ..addColumns([splitShares.shareMinor.sum()])
      ..where(splitShares.memberId.equals(memberId))
    ).getSingle();

    final totalPaise = result.read(splitShares.shareMinor.sum()) ?? 0;
    return Money.fromPaise(totalPaise);
  }

  /// Get total share amount for a member in a specific group
  Future<Money> getTotalSharesForMemberInGroup({
    required String memberId,
    required String groupId,
  }) async {
    final result = await (selectOnly(splitShares)
      ..addColumns([splitShares.shareMinor.sum()])
      ..where(splitShares.memberId.equals(memberId))
      ..join([
        leftOuterJoin(expenses, expenses.id.equalsExp(splitShares.expenseId)),
      ])
      ..where(expenses.groupId.equals(groupId))
    ).getSingle();

    final totalPaise = result.read(splitShares.shareMinor.sum()) ?? 0;
    return Money.fromPaise(totalPaise);
  }

  /// Get shares by date range
  Future<List<ShareWithExpense>> getSharesByDateRange({
    required String memberId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final startEpochDays = _dateToEpochDays(startDate);
    final endEpochDays = _dateToEpochDays(endDate);

    final query = select(splitShares).join([
      leftOuterJoin(expenses, expenses.id.equalsExp(splitShares.expenseId)),
    ])
      ..where(splitShares.memberId.equals(memberId) &
               expenses.dateEpochDays.isBetweenValues(startEpochDays, endEpochDays))
      ..orderBy([OrderingTerm.desc(expenses.createdAt)]);

    return query.map((row) {
      final share = row.readTable(splitShares);
      final expense = row.readTableOrNull(expenses);
      
      return ShareWithExpense(
        share: share,
        expense: expense,
      );
    }).get();
  }

  /// Get shares grouped by category for analytics
  Future<Map<String, Money>> getSharesByCategory({
    required String memberId,
    DateTime? startDate,
    DateTime? endDate,
    String? groupId,
  }) async {
    final query = selectOnly(splitShares)
      ..addColumns([expenses.category, splitShares.shareMinor.sum()])
      ..join([
        leftOuterJoin(expenses, expenses.id.equalsExp(splitShares.expenseId)),
      ]);

    Expression<bool> whereClause = splitShares.memberId.equals(memberId);

    if (startDate != null && endDate != null) {
      final startEpochDays = _dateToEpochDays(startDate);
      final endEpochDays = _dateToEpochDays(endDate);
      whereClause = whereClause & 
          expenses.dateEpochDays.isBetweenValues(startEpochDays, endEpochDays);
    }

    if (groupId != null) {
      whereClause = whereClause & expenses.groupId.equals(groupId);
    }

    query
      ..where(whereClause)
      ..groupBy([expenses.category])
      ..orderBy([OrderingTerm.desc(splitShares.shareMinor.sum())]);

    final results = await query.get();
    final categoryTotals = <String, Money>{};

    for (final row in results) {
      final category = row.read(expenses.category);
      final totalPaise = row.read(splitShares.shareMinor.sum()) ?? 0;
      if (category != null) {
        categoryTotals[category] = Money.fromPaise(totalPaise);
      }
    }

    return categoryTotals;
  }

  /// Validate that shares sum to expense amount
  Future<bool> validateSharesForExpense(String expenseId) async {
    final expenseQuery = select(expenses)..where((e) => e.id.equals(expenseId));
    final expense = await expenseQuery.getSingleOrNull();
    if (expense == null) return false;

    final sharesQuery = selectOnly(splitShares)
      ..addColumns([splitShares.shareMinor.sum()])
      ..where(splitShares.expenseId.equals(expenseId));
    
    final result = await sharesQuery.getSingle();
    final totalSharesPaise = result.read(splitShares.shareMinor.sum()) ?? 0;

    return totalSharesPaise == expense.amountMinor;
  }

  /// Get share for a specific member in a specific expense
  Future<ShareWithMember?> getShareForMemberInExpense({
    required String memberId,
    required String expenseId,
  }) async {
    final query = select(splitShares).join([
      leftOuterJoin(members, members.id.equalsExp(splitShares.memberId)),
    ])
      ..where(splitShares.memberId.equals(memberId) & 
               splitShares.expenseId.equals(expenseId));

    final result = await query.getSingleOrNull();
    if (result == null) return null;

    final share = result.readTable(splitShares);
    final member = result.readTableOrNull(members);
    
    return ShareWithMember(
      share: share,
      member: member,
    );
  }

  /// Convert DateTime to epoch days
  int _dateToEpochDays(DateTime date) {
    final epoch = DateTime(1970, 1, 1);
    return date.difference(epoch).inDays;
  }

  /// Generate a unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
  }
}

/// Split share with member details
class ShareWithMember {
  final SplitShare share;
  final Member? member;

  const ShareWithMember({
    required this.share,
    required this.member,
  });

  /// Get share amount as Money
  Money get amount => Money.fromPaise(share.shareMinor);

  @override
  String toString() => 'ShareWithMember(${member?.displayName}, ${amount.format()})';
}

/// Split share with expense details
class ShareWithExpense {
  final SplitShare share;
  final Expense? expense;

  const ShareWithExpense({
    required this.share,
    required this.expense,
  });

  /// Get share amount as Money
  Money get amount => Money.fromPaise(share.shareMinor);

  /// Get expense date as DateTime
  DateTime? get expenseDate => expense != null 
      ? DateTime(1970, 1, 1).add(Duration(days: expense!.dateEpochDays))
      : null;

  @override
  String toString() => 'ShareWithExpense(${expense?.description}, ${amount.format()})';
}

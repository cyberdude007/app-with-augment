import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';
import '../../../../core/money/money.dart';

part 'expense_dao.g.dart';

/// Data Access Object for expenses
@DriftAccessor(tables: [Expenses, SplitShares, Members, Groups])
class ExpenseDao extends DatabaseAccessor<AppDatabase> with _$ExpenseDaoMixin {
  ExpenseDao(AppDatabase db) : super(db);

  /// Get all expenses for a group, ordered by date (newest first)
  Future<List<ExpenseWithDetails>> getExpensesForGroup(String groupId) {
    final query = select(expenses).join([
      leftOuterJoin(members, members.id.equalsExp(expenses.payerMemberId)),
      leftOuterJoin(groups, groups.id.equalsExp(expenses.groupId)),
    ])
      ..where(expenses.groupId.equals(groupId))
      ..orderBy([OrderingTerm.desc(expenses.createdAt)]);

    return query.map((row) {
      final expense = row.readTable(expenses);
      final payer = row.readTableOrNull(members);
      final group = row.readTableOrNull(groups);
      
      return ExpenseWithDetails(
        expense: expense,
        payer: payer,
        group: group,
      );
    }).get();
  }

  /// Get all individual expenses for a member
  Future<List<ExpenseWithDetails>> getIndividualExpensesForMember(String memberId) {
    final query = select(expenses).join([
      leftOuterJoin(members, members.id.equalsExp(expenses.payerMemberId)),
    ])
      ..where(expenses.type.equals(ExpenseType.individual.value) & 
               expenses.payerMemberId.equals(memberId))
      ..orderBy([OrderingTerm.desc(expenses.createdAt)]);

    return query.map((row) {
      final expense = row.readTable(expenses);
      final payer = row.readTableOrNull(members);
      
      return ExpenseWithDetails(
        expense: expense,
        payer: payer,
        group: null,
      );
    }).get();
  }

  /// Get expenses by date range
  Future<List<ExpenseWithDetails>> getExpensesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? groupId,
    String? memberId,
  }) {
    final startEpochDays = _dateToEpochDays(startDate);
    final endEpochDays = _dateToEpochDays(endDate);

    final query = select(expenses).join([
      leftOuterJoin(members, members.id.equalsExp(expenses.payerMemberId)),
      leftOuterJoin(groups, groups.id.equalsExp(expenses.groupId)),
    ]);

    Expression<bool> whereClause = expenses.dateEpochDays.isBetweenValues(startEpochDays, endEpochDays);

    if (groupId != null) {
      whereClause = whereClause & expenses.groupId.equals(groupId);
    }

    if (memberId != null) {
      whereClause = whereClause & expenses.payerMemberId.equals(memberId);
    }

    query
      ..where(whereClause)
      ..orderBy([OrderingTerm.desc(expenses.createdAt)]);

    return query.map((row) {
      final expense = row.readTable(expenses);
      final payer = row.readTableOrNull(members);
      final group = row.readTableOrNull(groups);
      
      return ExpenseWithDetails(
        expense: expense,
        payer: payer,
        group: group,
      );
    }).get();
  }

  /// Get expenses by category
  Future<List<ExpenseWithDetails>> getExpensesByCategory(String category) {
    final query = select(expenses).join([
      leftOuterJoin(members, members.id.equalsExp(expenses.payerMemberId)),
      leftOuterJoin(groups, groups.id.equalsExp(expenses.groupId)),
    ])
      ..where(expenses.category.equals(category))
      ..orderBy([OrderingTerm.desc(expenses.createdAt)]);

    return query.map((row) {
      final expense = row.readTable(expenses);
      final payer = row.readTableOrNull(members);
      final group = row.readTableOrNull(groups);
      
      return ExpenseWithDetails(
        expense: expense,
        payer: payer,
        group: group,
      );
    }).get();
  }

  /// Search expenses by description
  Future<List<ExpenseWithDetails>> searchExpenses(String query) {
    final searchQuery = select(expenses).join([
      leftOuterJoin(members, members.id.equalsExp(expenses.payerMemberId)),
      leftOuterJoin(groups, groups.id.equalsExp(expenses.groupId)),
    ])
      ..where(expenses.description.contains(query) | 
               expenses.notes.contains(query))
      ..orderBy([OrderingTerm.desc(expenses.createdAt)]);

    return searchQuery.map((row) {
      final expense = row.readTable(expenses);
      final payer = row.readTableOrNull(members);
      final group = row.readTableOrNull(groups);
      
      return ExpenseWithDetails(
        expense: expense,
        payer: payer,
        group: group,
      );
    }).get();
  }

  /// Create a new expense
  Future<String> createExpense({
    required String description,
    required Money amount,
    required String payerMemberId,
    required DateTime date,
    required String category,
    required ExpenseType type,
    String? groupId,
    String? notes,
  }) async {
    final expenseId = _generateId();
    
    await into(expenses).insert(
      ExpensesCompanion.insert(
        id: expenseId,
        groupId: Value(groupId),
        type: type.value,
        description: description,
        amountMinor: amount.paise,
        payerMemberId: payerMemberId,
        dateEpochDays: _dateToEpochDays(date),
        notes: Value(notes),
        category: category,
        createdAt: DateTime.now(),
      ),
    );

    return expenseId;
  }

  /// Update an expense
  Future<bool> updateExpense({
    required String expenseId,
    String? description,
    Money? amount,
    String? payerMemberId,
    DateTime? date,
    String? category,
    String? notes,
  }) async {
    final updates = ExpensesCompanion(
      description: description != null ? Value(description) : const Value.absent(),
      amountMinor: amount != null ? Value(amount.paise) : const Value.absent(),
      payerMemberId: payerMemberId != null ? Value(payerMemberId) : const Value.absent(),
      dateEpochDays: date != null ? Value(_dateToEpochDays(date)) : const Value.absent(),
      category: category != null ? Value(category) : const Value.absent(),
      notes: notes != null ? Value(notes) : const Value.absent(),
    );

    final rowsAffected = await (update(expenses)..where((e) => e.id.equals(expenseId))).write(updates);
    return rowsAffected > 0;
  }

  /// Delete an expense and its shares
  Future<bool> deleteExpense(String expenseId) async {
    return await transaction(() async {
      // Delete split shares first (foreign key constraint)
      await (delete(splitShares)..where((s) => s.expenseId.equals(expenseId))).go();
      
      // Delete the expense
      final rowsAffected = await (delete(expenses)..where((e) => e.id.equals(expenseId))).go();
      return rowsAffected > 0;
    });
  }

  /// Get expense by ID with details
  Future<ExpenseWithDetails?> getExpenseById(String expenseId) async {
    final query = select(expenses).join([
      leftOuterJoin(members, members.id.equalsExp(expenses.payerMemberId)),
      leftOuterJoin(groups, groups.id.equalsExp(expenses.groupId)),
    ])..where(expenses.id.equals(expenseId));

    final result = await query.getSingleOrNull();
    if (result == null) return null;

    final expense = result.readTable(expenses);
    final payer = result.readTableOrNull(members);
    final group = result.readTableOrNull(groups);
    
    return ExpenseWithDetails(
      expense: expense,
      payer: payer,
      group: group,
    );
  }

  /// Get total expenses for a group
  Future<Money> getTotalExpensesForGroup(String groupId) async {
    final result = await (selectOnly(expenses)
      ..addColumns([expenses.amountMinor.sum()])
      ..where(expenses.groupId.equals(groupId))
    ).getSingle();

    final totalPaise = result.read(expenses.amountMinor.sum()) ?? 0;
    return Money.fromPaise(totalPaise);
  }

  /// Get expenses grouped by category for analytics
  Future<Map<String, Money>> getExpensesByCategory({
    DateTime? startDate,
    DateTime? endDate,
    String? groupId,
  }) async {
    final query = selectOnly(expenses)
      ..addColumns([expenses.category, expenses.amountMinor.sum()]);

    Expression<bool>? whereClause;

    if (startDate != null && endDate != null) {
      final startEpochDays = _dateToEpochDays(startDate);
      final endEpochDays = _dateToEpochDays(endDate);
      whereClause = expenses.dateEpochDays.isBetweenValues(startEpochDays, endEpochDays);
    }

    if (groupId != null) {
      final groupFilter = expenses.groupId.equals(groupId);
      whereClause = whereClause != null ? whereClause & groupFilter : groupFilter;
    }

    if (whereClause != null) {
      query.where(whereClause);
    }

    query
      ..groupBy([expenses.category])
      ..orderBy([OrderingTerm.desc(expenses.amountMinor.sum())]);

    final results = await query.get();
    final categoryTotals = <String, Money>{};

    for (final row in results) {
      final category = row.read(expenses.category)!;
      final totalPaise = row.read(expenses.amountMinor.sum()) ?? 0;
      categoryTotals[category] = Money.fromPaise(totalPaise);
    }

    return categoryTotals;
  }

  /// Convert DateTime to epoch days for efficient date queries
  int _dateToEpochDays(DateTime date) {
    final epoch = DateTime(1970, 1, 1);
    return date.difference(epoch).inDays;
  }

  /// Convert epoch days back to DateTime
  DateTime _epochDaysToDate(int epochDays) {
    final epoch = DateTime(1970, 1, 1);
    return epoch.add(Duration(days: epochDays));
  }

  /// Generate a unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
  }
}

/// Expense with related details
class ExpenseWithDetails {
  final Expense expense;
  final Member? payer;
  final Group? group;

  const ExpenseWithDetails({
    required this.expense,
    required this.payer,
    required this.group,
  });

  /// Get expense amount as Money
  Money get amount => Money.fromPaise(expense.amountMinor);

  /// Get expense date as DateTime
  DateTime get date => DateTime(1970, 1, 1).add(Duration(days: expense.dateEpochDays));

  /// Get expense type
  ExpenseType get type => ExpenseType.fromString(expense.type);

  /// Check if this is a split expense
  bool get isSplit => type == ExpenseType.split;

  /// Check if this is an individual expense
  bool get isIndividual => type == ExpenseType.individual;

  @override
  String toString() => 'ExpenseWithDetails(${expense.description}, ${amount.format()})';
}

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';
import '../../models/category.dart' as model;

/// Data Access Object for categories
@DriftAccessor(tables: [Categories, Expenses])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(AppDatabase db) : super(db);

  /// Get count of categories
  Future<int> getCategoryCount() async {
    final query = selectOnly(categories)..addColumns([categories.id.count()]);
    final result = await query.getSingle();
    return result.read(categories.id.count()) ?? 0;
  }

  /// Insert a new category
  Future<void> insertCategory({
    required String id,
    required String name,
    String? emoji,
    required bool isDefault,
    required bool isFavorite,
  }) async {
    await into(categories).insert(
      CategoriesCompanion.insert(
        id: id,
        name: name,
        emoji: Value(emoji),
        isDefault: isDefault,
        isFavorite: isFavorite,
        usageCount: 0,
        lastUsedAt: const Value(null),
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Get all categories ordered by name
  Future<List<model.Category>> getAllCategories() async {
    final query = select(categories)..orderBy([
      (t) => OrderingTerm(expression: t.isFavorite, mode: OrderingMode.desc),
      (t) => OrderingTerm(expression: t.usageCount, mode: OrderingMode.desc),
      (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc),
    ]);
    
    final results = await query.get();
    return results.map(_mapToModel).toList();
  }

  /// Get favorite categories
  Future<List<model.Category>> getFavoriteCategories() async {
    final query = select(categories)
      ..where((t) => t.isFavorite.equals(true))
      ..orderBy([
        (t) => OrderingTerm(expression: t.usageCount, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc),
      ]);
    
    final results = await query.get();
    return results.map(_mapToModel).toList();
  }

  /// Get recent categories (used within last 7 days)
  Future<List<model.Category>> getRecentCategories({int limit = 6}) async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    
    final query = select(categories)
      ..where((t) => t.lastUsedAt.isBiggerThanValue(sevenDaysAgo))
      ..orderBy([
        (t) => OrderingTerm(expression: t.lastUsedAt, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    
    final results = await query.get();
    return results.map(_mapToModel).toList();
  }

  /// Get most used categories
  Future<List<model.Category>> getMostUsedCategories({int limit = 10}) async {
    final query = select(categories)
      ..where((t) => t.usageCount.isBiggerThanValue(0))
      ..orderBy([
        (t) => OrderingTerm(expression: t.usageCount, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.lastUsedAt, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    
    final results = await query.get();
    return results.map(_mapToModel).toList();
  }

  /// Get category by ID
  Future<model.Category?> getCategoryById(String id) async {
    final query = select(categories)..where((t) => t.id.equals(id));
    final result = await query.getSingleOrNull();
    return result != null ? _mapToModel(result) : null;
  }

  /// Get category by name (case insensitive)
  Future<model.Category?> getCategoryByName(String name) async {
    final query = select(categories)..where((t) => t.name.lower().equals(name.toLowerCase()));
    final result = await query.getSingleOrNull();
    return result != null ? _mapToModel(result) : null;
  }

  /// Toggle favorite status of a category
  Future<bool> toggleFavorite(String categoryId) async {
    final category = await getCategoryById(categoryId);
    if (category == null) return false;

    final rowsAffected = await (update(categories)..where((t) => t.id.equals(categoryId)))
        .write(CategoriesCompanion(
          isFavorite: Value(!category.isFavorite),
        ));
    
    return rowsAffected > 0;
  }

  /// Record category usage (increment count and update last used)
  Future<bool> recordUsage(String categoryId) async {
    final category = await getCategoryById(categoryId);
    if (category == null) return false;

    final rowsAffected = await (update(categories)..where((t) => t.id.equals(categoryId)))
        .write(CategoriesCompanion(
          usageCount: Value(category.usageCount + 1),
          lastUsedAt: Value(DateTime.now()),
        ));
    
    return rowsAffected > 0;
  }

  /// Get usage count for a category (number of expenses using this category)
  Future<int> getCategoryUsageCount(String categoryId) async {
    final query = selectOnly(expenses)
      ..addColumns([expenses.id.count()])
      ..where(expenses.category.equals(categoryId));
    
    final result = await query.getSingle();
    return result.read(expenses.id.count()) ?? 0;
  }

  /// Delete a category
  Future<bool> deleteCategory(String categoryId) async {
    final rowsAffected = await (delete(categories)..where((t) => t.id.equals(categoryId))).go();
    return rowsAffected > 0;
  }

  /// Update category name and emoji
  Future<bool> updateCategory({
    required String categoryId,
    String? name,
    String? emoji,
  }) async {
    final companion = CategoriesCompanion();
    
    if (name != null) {
      companion.copyWith(name: Value(name));
    }
    if (emoji != null) {
      companion.copyWith(emoji: Value(emoji));
    }

    final rowsAffected = await (update(categories)..where((t) => t.id.equals(categoryId)))
        .write(companion);
    
    return rowsAffected > 0;
  }

  /// Get categories with usage statistics
  Future<List<CategoryUsageStats>> getCategoriesWithStats() async {
    final query = select(categories).join([
      leftOuterJoin(
        expenses,
        expenses.category.equalsExp(categories.name),
      ),
    ]);

    final results = await query.get();
    final categoryStats = <String, CategoryUsageStats>{};

    for (final row in results) {
      final category = row.readTable(categories);
      final expense = row.readTableOrNull(expenses);

      final categoryId = category.id;
      if (!categoryStats.containsKey(categoryId)) {
        categoryStats[categoryId] = CategoryUsageStats(
          category: _mapToModel(category),
          expenseCount: 0,
          totalAmount: 0,
          lastExpenseDate: null,
        );
      }

      if (expense != null) {
        final stats = categoryStats[categoryId]!;
        categoryStats[categoryId] = CategoryUsageStats(
          category: stats.category,
          expenseCount: stats.expenseCount + 1,
          totalAmount: stats.totalAmount + expense.amountMinor,
          lastExpenseDate: stats.lastExpenseDate == null
              ? _epochDaysToDateTime(expense.dateEpochDays)
              : [stats.lastExpenseDate!, _epochDaysToDateTime(expense.dateEpochDays)]
                  .reduce((a, b) => a.isAfter(b) ? a : b),
        );
      }
    }

    return categoryStats.values.toList();
  }

  /// Convert database row to model
  model.Category _mapToModel(CategoriesTableData data) {
    return model.Category(
      id: data.id,
      name: data.name,
      emoji: data.emoji,
      isDefault: data.isDefault,
      isFavorite: data.isFavorite,
      usageCount: data.usageCount,
      lastUsedAt: data.lastUsedAt,
      createdAt: data.createdAt,
    );
  }

  /// Convert epoch days to DateTime
  DateTime _epochDaysToDateTime(int epochDays) {
    return DateTime.fromMillisecondsSinceEpoch(epochDays * 24 * 60 * 60 * 1000);
  }
}

/// Category usage statistics
class CategoryUsageStats {
  final model.Category category;
  final int expenseCount;
  final int totalAmount; // in paise
  final DateTime? lastExpenseDate;

  const CategoryUsageStats({
    required this.category,
    required this.expenseCount,
    required this.totalAmount,
    this.lastExpenseDate,
  });
}

import 'package:uuid/uuid.dart';
import '../db/drift/app_database.dart';
import '../models/category.dart';
import '../../core/algorithms/fuzzy_search.dart';
import '../../core/utils/result.dart';

/// Repository for category management
class CategoryRepo {
  final CategoryDao _categoryDao;
  final _uuid = const Uuid();

  CategoryRepo(this._categoryDao);

  /// Initialize default categories if none exist
  Future<Result<void>> initializeDefaultCategories() async {
    try {
      final existingCount = await _categoryDao.getCategoryCount();
      if (existingCount > 0) {
        return const Result.success(null);
      }

      // Insert default categories
      for (final category in DefaultCategories.categories) {
        await _categoryDao.insertCategory(
          id: category.id,
          name: category.name,
          emoji: category.emoji,
          isDefault: category.isDefault,
          isFavorite: category.isFavorite,
        );
      }

      return const Result.success(null);
    } catch (e) {
      return Result.error('Failed to initialize default categories', e);
    }
  }

  /// Get all categories
  Future<Result<List<Category>>> getAllCategories() async {
    try {
      final categories = await _categoryDao.getAllCategories();
      return Result.success(categories);
    } catch (e) {
      return Result.error('Failed to get categories', e);
    }
  }

  /// Get favorite categories
  Future<Result<List<Category>>> getFavoriteCategories() async {
    try {
      final categories = await _categoryDao.getFavoriteCategories();
      return Result.success(categories);
    } catch (e) {
      return Result.error('Failed to get favorite categories', e);
    }
  }

  /// Get recent categories (used within last 7 days)
  Future<Result<List<Category>>> getRecentCategories({int limit = 6}) async {
    try {
      final categories = await _categoryDao.getRecentCategories(limit: limit);
      return Result.success(categories);
    } catch (e) {
      return Result.error('Failed to get recent categories', e);
    }
  }

  /// Get most used categories
  Future<Result<List<Category>>> getMostUsedCategories({int limit = 10}) async {
    try {
      final categories = await _categoryDao.getMostUsedCategories(limit: limit);
      return Result.success(categories);
    } catch (e) {
      return Result.error('Failed to get most used categories', e);
    }
  }

  /// Search categories with fuzzy matching
  Future<Result<List<Category>>> searchCategories(
    String query, {
    int maxResults = 10,
  }) async {
    try {
      final allCategories = await _categoryDao.getAllCategories();
      
      // Get recent usage scores for ranking
      final recentScores = <Category, double>{};
      for (final category in allCategories) {
        if (category.lastUsedAt != null) {
          final daysSince = DateTime.now().difference(category.lastUsedAt!).inDays;
          if (daysSince <= 30) {
            recentScores[category] = 1.0 - (daysSince / 30.0);
          }
        }
      }

      final results = FuzzySearch.search<Category>(
        query: query,
        items: allCategories,
        getText: (category) => category.name,
        recentScores: recentScores,
        maxResults: maxResults,
      );

      return Result.success(results.map((r) => r.item).toList());
    } catch (e) {
      return Result.error('Failed to search categories', e);
    }
  }

  /// Create a new category
  Future<Result<Category>> createCategory({
    required String name,
    String? emoji,
    bool isFavorite = false,
  }) async {
    try {
      // Check if category with same name already exists
      final existing = await _categoryDao.getCategoryByName(name);
      if (existing != null) {
        return const Result.error('Category with this name already exists');
      }

      final categoryId = _uuid.v4();
      await _categoryDao.insertCategory(
        id: categoryId,
        name: name,
        emoji: emoji,
        isDefault: false,
        isFavorite: isFavorite,
      );

      final category = await _categoryDao.getCategoryById(categoryId);
      if (category == null) {
        return const Result.error('Failed to retrieve created category');
      }

      return Result.success(category);
    } catch (e) {
      return Result.error('Failed to create category', e);
    }
  }

  /// Update category favorite status
  Future<Result<void>> toggleFavorite(String categoryId) async {
    try {
      final success = await _categoryDao.toggleFavorite(categoryId);
      return success
          ? const Result.success(null)
          : const Result.error('Failed to toggle favorite status');
    } catch (e) {
      return Result.error('Failed to toggle favorite status', e);
    }
  }

  /// Record category usage (increment count and update last used)
  Future<Result<void>> recordUsage(String categoryId) async {
    try {
      final success = await _categoryDao.recordUsage(categoryId);
      return success
          ? const Result.success(null)
          : const Result.error('Failed to record category usage');
    } catch (e) {
      return Result.error('Failed to record category usage', e);
    }
  }

  /// Get category by ID
  Future<Result<Category?>> getCategoryById(String id) async {
    try {
      final category = await _categoryDao.getCategoryById(id);
      return Result.success(category);
    } catch (e) {
      return Result.error('Failed to get category', e);
    }
  }

  /// Get category by name
  Future<Result<Category?>> getCategoryByName(String name) async {
    try {
      final category = await _categoryDao.getCategoryByName(name);
      return Result.success(category);
    } catch (e) {
      return Result.error('Failed to get category', e);
    }
  }

  /// Delete a custom category (cannot delete default categories)
  Future<Result<void>> deleteCategory(String categoryId) async {
    try {
      final category = await _categoryDao.getCategoryById(categoryId);
      if (category == null) {
        return const Result.error('Category not found');
      }

      if (category.isDefault) {
        return const Result.error('Cannot delete default categories');
      }

      // Check if category is being used in any expenses
      final usageCount = await _categoryDao.getCategoryUsageCount(categoryId);
      if (usageCount > 0) {
        return const Result.error('Cannot delete category that is being used in expenses');
      }

      final success = await _categoryDao.deleteCategory(categoryId);
      return success
          ? const Result.success(null)
          : const Result.error('Failed to delete category');
    } catch (e) {
      return Result.error('Failed to delete category', e);
    }
  }

  /// Get categories for quick selection (favorites + recent)
  Future<Result<List<Category>>> getQuickSelectCategories({int limit = 6}) async {
    try {
      final favorites = await _categoryDao.getFavoriteCategories();
      final recent = await _categoryDao.getRecentCategories(limit: limit);
      
      // Combine and deduplicate
      final quickCategories = <String, Category>{};
      
      // Add favorites first
      for (final category in favorites) {
        quickCategories[category.id] = category;
      }
      
      // Add recent categories if not already included
      for (final category in recent) {
        if (!quickCategories.containsKey(category.id)) {
          quickCategories[category.id] = category;
        }
      }
      
      // Sort by usage score (favorites + recency)
      final sortedCategories = quickCategories.values.toList()
        ..sort((a, b) {
          // Favorites first
          if (a.isFavorite && !b.isFavorite) return -1;
          if (!a.isFavorite && b.isFavorite) return 1;
          
          // Then by usage count
          final usageComparison = b.usageCount.compareTo(a.usageCount);
          if (usageComparison != 0) return usageComparison;
          
          // Finally by recency
          if (a.lastUsedAt != null && b.lastUsedAt != null) {
            return b.lastUsedAt!.compareTo(a.lastUsedAt!);
          } else if (a.lastUsedAt != null) {
            return -1;
          } else if (b.lastUsedAt != null) {
            return 1;
          }
          
          return 0;
        });

      return Result.success(sortedCategories.take(limit).toList());
    } catch (e) {
      return Result.error('Failed to get quick select categories', e);
    }
  }
}

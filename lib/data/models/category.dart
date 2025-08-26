import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

/// Category model for expense categorization
@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    String? emoji,
    @Default(false) bool isDefault,
    @Default(false) bool isFavorite,
    @Default(0) int usageCount,
    DateTime? lastUsedAt,
    required DateTime createdAt,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);
}

/// Default categories with emojis as per spec
class DefaultCategories {
  static const List<Category> categories = [
    Category(
      id: 'food',
      name: 'Food',
      emoji: '🍽️',
      isDefault: true,
      createdAt: _defaultDate,
    ),
    Category(
      id: 'transport',
      name: 'Transport',
      emoji: '🚕',
      isDefault: true,
      createdAt: _defaultDate,
    ),
    Category(
      id: 'groceries',
      name: 'Groceries',
      emoji: '🛒',
      isDefault: true,
      createdAt: _defaultDate,
    ),
    Category(
      id: 'utilities',
      name: 'Utilities',
      emoji: '💡',
      isDefault: true,
      createdAt: _defaultDate,
    ),
    Category(
      id: 'shopping',
      name: 'Shopping',
      emoji: '🛍️',
      isDefault: true,
      createdAt: _defaultDate,
    ),
    Category(
      id: 'entertainment',
      name: 'Entertainment',
      emoji: '🎬',
      isDefault: true,
      createdAt: _defaultDate,
    ),
    Category(
      id: 'health',
      name: 'Health',
      emoji: '🏥',
      isDefault: true,
      createdAt: _defaultDate,
    ),
    Category(
      id: 'education',
      name: 'Education',
      emoji: '🎓',
      isDefault: true,
      createdAt: _defaultDate,
    ),
    Category(
      id: 'bills',
      name: 'Bills',
      emoji: '🧾',
      isDefault: true,
      createdAt: _defaultDate,
    ),
    Category(
      id: 'misc',
      name: 'Misc',
      emoji: '🏷️',
      isDefault: true,
      createdAt: _defaultDate,
    ),
  ];

  static const DateTime _defaultDate = DateTime.utc(2024, 1, 1);

  /// Get category by name (case insensitive)
  static Category? findByName(String name) {
    final lowerName = name.toLowerCase();
    try {
      return categories.firstWhere(
        (cat) => cat.name.toLowerCase() == lowerName,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get category by ID
  static Category? findById(String id) {
    try {
      return categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get all category names
  static List<String> get names => categories.map((cat) => cat.name).toList();

  /// Get all category names with emojis
  static List<String> get namesWithEmojis => categories
      .map((cat) => cat.emoji != null ? '${cat.emoji} ${cat.name}' : cat.name)
      .toList();
}

/// Category usage tracking
class CategoryUsage {
  final String categoryId;
  final String categoryName;
  final int usageCount;
  final DateTime? lastUsedAt;
  final bool isFavorite;

  const CategoryUsage({
    required this.categoryId,
    required this.categoryName,
    required this.usageCount,
    this.lastUsedAt,
    required this.isFavorite,
  });

  /// Calculate recency score (0.0 to 1.0)
  double get recencyScore {
    if (lastUsedAt == null) return 0.0;
    
    final daysSince = DateTime.now().difference(lastUsedAt!).inDays;
    if (daysSince <= 0) return 1.0;
    if (daysSince >= 30) return 0.0;
    
    // Linear decay over 30 days
    return 1.0 - (daysSince / 30.0);
  }

  /// Calculate usage score based on count and recency
  double get usageScore {
    final countScore = (usageCount / 100.0).clamp(0.0, 1.0);
    return (countScore * 0.7) + (recencyScore * 0.3);
  }

  /// Check if category is recent (used within last 7 days)
  bool get isRecent {
    if (lastUsedAt == null) return false;
    return DateTime.now().difference(lastUsedAt!).inDays <= 7;
  }
}

/// Category filter options
enum CategoryFilter {
  all,
  favorites,
  recent,
  mostUsed,
  defaults,
  custom;

  String get displayName => switch (this) {
    CategoryFilter.all => 'All',
    CategoryFilter.favorites => 'Favorites',
    CategoryFilter.recent => 'Recent',
    CategoryFilter.mostUsed => 'Most Used',
    CategoryFilter.defaults => 'Default',
    CategoryFilter.custom => 'Custom',
  };
}

/// Category sort options
enum CategorySort {
  alphabetical,
  usage,
  recency,
  favorites;

  String get displayName => switch (this) {
    CategorySort.alphabetical => 'A-Z',
    CategorySort.usage => 'Most Used',
    CategorySort.recency => 'Recent',
    CategorySort.favorites => 'Favorites',
  };
}

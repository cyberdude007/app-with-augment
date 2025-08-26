import 'package:flutter/material.dart';
import '../app/theme/tokens.dart';
import '../data/models/category.dart';

/// A chip widget for displaying and selecting categories
class CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showUsageCount;
  final bool compact;

  const CategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.showUsageCount = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: compact 
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            border: isSelected
                ? Border.all(color: colorScheme.primary, width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji
              if (category.emoji != null) ...[
                Text(
                  category.emoji!,
                  style: TextStyle(
                    fontSize: compact ? 14 : 16,
                  ),
                ),
                SizedBox(width: compact ? 4 : 6),
              ],
              
              // Category name
              Text(
                category.name,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: compact ? 12 : 14,
                ),
              ),
              
              // Usage count badge
              if (showUsageCount && category.usageCount > 0) ...[
                SizedBox(width: compact ? 4 : 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  ),
                  child: Text(
                    category.usageCount.toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
              
              // Favorite indicator
              if (category.isFavorite) ...[
                SizedBox(width: compact ? 4 : 6),
                Icon(
                  Icons.star,
                  size: compact ? 12 : 14,
                  color: colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A horizontal scrollable list of category chips
class CategoryChipList extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<Category>? onCategorySelected;
  final VoidCallback? onLongPress;
  final bool showUsageCount;
  final bool compact;
  final EdgeInsets? padding;

  const CategoryChipList({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    this.onCategorySelected,
    this.onLongPress,
    this.showUsageCount = false,
    this.compact = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: AppTokens.space4),
      child: Row(
        children: categories.map((category) {
          final isSelected = category.id == selectedCategoryId;
          return Padding(
            padding: const EdgeInsets.only(right: AppTokens.space2),
            child: CategoryChip(
              category: category,
              isSelected: isSelected,
              onTap: () => onCategorySelected?.call(category),
              onLongPress: onLongPress,
              showUsageCount: showUsageCount,
              compact: compact,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// A grid of category chips
class CategoryChipGrid extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<Category>? onCategorySelected;
  final VoidCallback? onLongPress;
  final bool showUsageCount;
  final int crossAxisCount;
  final double childAspectRatio;
  final EdgeInsets? padding;

  const CategoryChipGrid({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    this.onCategorySelected,
    this.onLongPress,
    this.showUsageCount = false,
    this.crossAxisCount = 2,
    this.childAspectRatio = 3.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding ?? const EdgeInsets.all(AppTokens.space4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: AppTokens.space2,
          mainAxisSpacing: AppTokens.space2,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category.id == selectedCategoryId;
          
          return CategoryChip(
            category: category,
            isSelected: isSelected,
            onTap: () => onCategorySelected?.call(category),
            onLongPress: onLongPress,
            showUsageCount: showUsageCount,
          );
        },
      ),
    );
  }
}

/// A compact category selector with quick chips
class QuickCategorySelector extends StatelessWidget {
  final List<Category> quickCategories;
  final String? selectedCategoryId;
  final ValueChanged<Category>? onCategorySelected;
  final VoidCallback? onShowAllCategories;
  final String? placeholder;

  const QuickCategorySelector({
    super.key,
    required this.quickCategories,
    this.selectedCategoryId,
    this.onCategorySelected,
    this.onShowAllCategories,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick selection chips
        if (quickCategories.isNotEmpty) ...[
          CategoryChipList(
            categories: quickCategories,
            selectedCategoryId: selectedCategoryId,
            onCategorySelected: onCategorySelected,
            compact: true,
          ),
          const SizedBox(height: AppTokens.space2),
        ],
        
        // Show all button
        if (onShowAllCategories != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
            child: TextButton.icon(
              onPressed: onShowAllCategories,
              icon: const Icon(Icons.more_horiz, size: 16),
              label: Text(
                placeholder ?? 'Show all categories',
                style: theme.textTheme.labelMedium,
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/tokens.dart';
import '../../../data/models/category.dart';
import '../../../widgets/category_chip.dart';
import '../../../widgets/search_bar.dart';
import '../../../core/algorithms/fuzzy_search.dart';

/// Category picker that adapts to screen size
/// Shows bottom sheet on phone, side pane on tablet
class CategoryPicker extends ConsumerStatefulWidget {
  final List<Category> categories;
  final List<Category> recentCategories;
  final String? selectedCategoryId;
  final ValueChanged<Category> onCategorySelected;
  final VoidCallback? onCreateNew;
  final bool isExpanded; // true for tablet/desktop layout

  const CategoryPicker({
    super.key,
    required this.categories,
    required this.recentCategories,
    this.selectedCategoryId,
    required this.onCategorySelected,
    this.onCreateNew,
    this.isExpanded = false,
  });

  @override
  ConsumerState<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends ConsumerState<CategoryPicker> {
  final _searchController = TextEditingController();
  List<Category> _filteredCategories = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredCategories = widget.categories;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCategories = widget.categories;
      } else {
        // Use fuzzy search
        final results = FuzzySearch.search<Category>(
          query: query,
          items: widget.categories,
          getText: (category) => category.name,
          maxResults: 20,
        );
        _filteredCategories = results.map((r) => r.item).toList();
      }
    });
  }

  void _onCategoryTap(Category category) {
    widget.onCategorySelected(category);
    if (!widget.isExpanded) {
      // Close bottom sheet on mobile
      Navigator.of(context).pop();
    }
  }

  void _onCreateNew() {
    if (_searchQuery.isNotEmpty) {
      // Create new category with search query as name
      final newCategory = Category(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        name: _searchQuery,
        createdAt: DateTime.now(),
      );
      widget.onCategorySelected(newCategory);
      if (!widget.isExpanded) {
        Navigator.of(context).pop();
      }
    }
    widget.onCreateNew?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (widget.isExpanded) {
      return _buildExpandedLayout(theme);
    } else {
      return _buildCompactLayout(theme);
    }
  }

  Widget _buildExpandedLayout(ThemeData theme) {
    return Container(
      width: 320,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppTokens.space4),
            child: Text(
              'Select Category',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
            child: AppSearchBar(
              controller: _searchController,
              hintText: 'Search categories...',
              onChanged: _onSearchChanged,
              autofocus: false,
            ),
          ),
          
          const SizedBox(height: AppTokens.space4),
          
          // Content
          Expanded(
            child: _buildCategoryList(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLayout(ThemeData theme) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTokens.radiusXl),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: AppTokens.space3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
                child: Row(
                  children: [
                    Text(
                      'Select Category',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
              
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
                child: AppSearchBar(
                  controller: _searchController,
                  hintText: 'Search categories...',
                  onChanged: _onSearchChanged,
                  autofocus: true,
                ),
              ),
              
              const SizedBox(height: AppTokens.space4),
              
              // Content
              Expanded(
                child: _buildCategoryList(theme, scrollController: scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryList(ThemeData theme, {ScrollController? scrollController}) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
      children: [
        // Recent categories (if no search)
        if (_searchQuery.isEmpty && widget.recentCategories.isNotEmpty) ...[
          Text(
            'Recent',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTokens.space2),
          ...widget.recentCategories.map((category) => _buildCategoryTile(category, theme)),
          const SizedBox(height: AppTokens.space4),
        ],
        
        // All categories section
        Text(
          _searchQuery.isEmpty ? 'All Categories' : 'Search Results',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTokens.space2),
        
        // Category list
        ..._filteredCategories.map((category) => _buildCategoryTile(category, theme)),
        
        // Create new option
        if (_searchQuery.isNotEmpty && !_filteredCategories.any((c) => c.name.toLowerCase() == _searchQuery.toLowerCase())) ...[
          const SizedBox(height: AppTokens.space2),
          _buildCreateNewTile(theme),
        ],
        
        // Bottom padding
        const SizedBox(height: AppTokens.space8),
      ],
    );
  }

  Widget _buildCategoryTile(Category category, ThemeData theme) {
    final isSelected = category.id == widget.selectedCategoryId;
    
    return ListTile(
      leading: category.emoji != null
          ? Text(category.emoji!, style: const TextStyle(fontSize: 20))
          : Icon(
              Icons.label_outline,
              color: theme.colorScheme.onSurfaceVariant,
            ),
      title: Text(
        category.name,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (category.isFavorite)
            Icon(
              Icons.star,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          if (category.usageCount > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              ),
              child: Text(
                category.usageCount.toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          if (isSelected) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.check_circle,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ],
        ],
      ),
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
      onTap: () => _onCategoryTap(category),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }

  Widget _buildCreateNewTile(ThemeData theme) {
    return ListTile(
      leading: Icon(
        Icons.add_circle_outline,
        color: theme.colorScheme.primary,
      ),
      title: Text(
        'Create "$_searchQuery"',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: _onCreateNew,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }
}

/// Show category picker bottom sheet
Future<Category?> showCategoryPickerSheet({
  required BuildContext context,
  required List<Category> categories,
  required List<Category> recentCategories,
  String? selectedCategoryId,
  VoidCallback? onCreateNew,
}) {
  return showModalBottomSheet<Category>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CategoryPicker(
      categories: categories,
      recentCategories: recentCategories,
      selectedCategoryId: selectedCategoryId,
      onCategorySelected: (category) => Navigator.of(context).pop(category),
      onCreateNew: onCreateNew,
      isExpanded: false,
    ),
  );
}

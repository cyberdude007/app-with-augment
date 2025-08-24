import 'package:flutter/material.dart';
import '../app/theme/tokens.dart';

/// A customizable search bar widget
class AppSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final bool enabled;
  final Widget? leading;
  final List<Widget>? actions;

  const AppSearchBar({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.enabled = true,
    this.leading,
    this.actions,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    widget.onChanged?.call(_controller.text);
  }

  void _onClear() {
    _controller.clear();
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Leading widget or search icon
          Padding(
            padding: const EdgeInsets.only(left: AppTokens.space4),
            child: widget.leading ??
                Icon(
                  Icons.search,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: AppTokens.iconMd,
                ),
          ),
          
          // Text field
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: widget.onSubmitted,
              autofocus: widget.autofocus,
              enabled: widget.enabled,
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Search...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space3,
                  vertical: AppTokens.space3,
                ),
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
              style: TextStyle(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          
          // Clear button
          if (_hasText)
            IconButton(
              onPressed: _onClear,
              icon: Icon(
                Icons.clear,
                color: theme.colorScheme.onSurfaceVariant,
                size: AppTokens.iconMd,
              ),
              padding: const EdgeInsets.all(AppTokens.space2),
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          
          // Action buttons
          if (widget.actions != null) ...widget.actions!,
          
          const SizedBox(width: AppTokens.space2),
        ],
      ),
    );
  }
}

/// A search bar with filter options
class FilterableSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onFilterTap;
  final bool hasActiveFilters;
  final bool autofocus;
  final bool enabled;

  const FilterableSearchBar({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onFilterTap,
    this.hasActiveFilters = false,
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  State<FilterableSearchBar> createState() => _FilterableSearchBarState();
}

class _FilterableSearchBarState extends State<FilterableSearchBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSearchBar(
      controller: widget.controller,
      hintText: widget.hintText,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onClear: widget.onClear,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      actions: [
        IconButton(
          onPressed: widget.onFilterTap,
          icon: Stack(
            children: [
              Icon(
                Icons.filter_list,
                color: widget.hasActiveFilters
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: AppTokens.iconMd,
              ),
              if (widget.hasActiveFilters)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          padding: const EdgeInsets.all(AppTokens.space2),
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
      ],
    );
  }
}

/// A search bar with category chips
class CategorySearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?>? onCategoryChanged;
  final bool autofocus;
  final bool enabled;

  const CategorySearchBar({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.categories = const [],
    this.selectedCategory,
    this.onCategoryChanged,
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  State<CategorySearchBar> createState() => _CategorySearchBarState();
}

class _CategorySearchBarState extends State<CategorySearchBar> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppSearchBar(
          controller: widget.controller,
          hintText: widget.hintText,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          onClear: widget.onClear,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
        ),
        
        if (widget.categories.isNotEmpty) ...[
          const SizedBox(height: AppTokens.space3),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
              itemCount: widget.categories.length + 1,
              separatorBuilder: (context, index) => const SizedBox(width: AppTokens.space2),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return FilterChip(
                    label: const Text('All'),
                    selected: widget.selectedCategory == null,
                    onSelected: (selected) {
                      if (selected) {
                        widget.onCategoryChanged?.call(null);
                      }
                    },
                  );
                }
                
                final category = widget.categories[index - 1];
                return FilterChip(
                  label: Text(category),
                  selected: widget.selectedCategory == category,
                  onSelected: (selected) {
                    widget.onCategoryChanged?.call(selected ? category : null);
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// A compact search bar for app bars
class CompactSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final bool enabled;

  const CompactSearchBar({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  State<CompactSearchBar> createState() => _CompactSearchBarState();
}

class _CompactSearchBarState extends State<CompactSearchBar> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    widget.onChanged?.call(_controller.text);
  }

  void _onClear() {
    _controller.clear();
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppTokens.space3),
          Icon(
            Icons.search,
            color: theme.colorScheme.onSurfaceVariant,
            size: AppTokens.iconSm,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: widget.onSubmitted,
              autofocus: widget.autofocus,
              enabled: widget.enabled,
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Search...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space2,
                  vertical: AppTokens.space2,
                ),
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (_hasText)
            IconButton(
              onPressed: _onClear,
              icon: Icon(
                Icons.clear,
                color: theme.colorScheme.onSurfaceVariant,
                size: AppTokens.iconSm,
              ),
              padding: const EdgeInsets.all(AppTokens.space1),
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
            ),
          const SizedBox(width: AppTokens.space2),
        ],
      ),
    );
  }
}

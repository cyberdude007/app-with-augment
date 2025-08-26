import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../data/models/expense_type.dart';

/// Segmented toggle for switching between Split and Individual expense types
class ExpenseTypeToggle extends StatelessWidget {
  final ExpenseType selectedType;
  final ValueChanged<ExpenseType> onTypeChanged;
  final bool enabled;

  const ExpenseTypeToggle({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: ExpenseType.values.map((type) {
          final isSelected = type == selectedType;
          final isFirst = type == ExpenseType.values.first;
          final isLast = type == ExpenseType.values.last;

          return Expanded(
            child: GestureDetector(
              onTap: enabled ? () => onTypeChanged(type) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space4,
                  vertical: AppTokens.space3,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.horizontal(
                    left: isFirst ? const Radius.circular(AppTokens.radiusLg) : Radius.zero,
                    right: isLast ? const Radius.circular(AppTokens.radiusLg) : Radius.zero,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Text(
                      type.icon,
                      style: TextStyle(
                        fontSize: 20,
                        color: enabled
                            ? (isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant)
                            : colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                    
                    const SizedBox(height: AppTokens.space1),
                    
                    // Title
                    Text(
                      type.displayName,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: enabled
                            ? (isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant)
                            : colorScheme.onSurfaceVariant.withOpacity(0.5),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: AppTokens.space1),
                    
                    // Description
                    Text(
                      type.description,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: enabled
                            ? (isSelected 
                                ? colorScheme.onPrimary.withOpacity(0.8)
                                : colorScheme.onSurfaceVariant.withOpacity(0.7))
                            : colorScheme.onSurfaceVariant.withOpacity(0.4),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Compact version of expense type toggle for smaller screens
class CompactExpenseTypeToggle extends StatelessWidget {
  final ExpenseType selectedType;
  final ValueChanged<ExpenseType> onTypeChanged;
  final bool enabled;

  const CompactExpenseTypeToggle({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: ExpenseType.values.map((type) {
          final isSelected = type == selectedType;
          final isFirst = type == ExpenseType.values.first;
          final isLast = type == ExpenseType.values.last;

          return Expanded(
            child: GestureDetector(
              onTap: enabled ? () => onTypeChanged(type) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space3,
                  vertical: AppTokens.space2,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.horizontal(
                    left: isFirst ? const Radius.circular(AppTokens.radiusMd) : Radius.zero,
                    right: isLast ? const Radius.circular(AppTokens.radiusMd) : Radius.zero,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Text(
                      type.icon,
                      style: TextStyle(
                        fontSize: 16,
                        color: enabled
                            ? (isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant)
                            : colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                    
                    const SizedBox(width: AppTokens.space1),
                    
                    // Title
                    Text(
                      type.displayName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: enabled
                            ? (isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant)
                            : colorScheme.onSurfaceVariant.withOpacity(0.5),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Info banner for individual expenses
class IndividualExpenseInfo extends StatelessWidget {
  const IndividualExpenseInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppTokens.space3),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: AppTokens.space2),
          Expanded(
            child: Text(
              'Recorded only in your ledger.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Split method selector for split expenses
class SplitMethodSelector extends StatelessWidget {
  final SplitMethod selectedMethod;
  final ValueChanged<SplitMethod> onMethodChanged;
  final bool enabled;

  const SplitMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Split Method',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTokens.space2),
        Wrap(
          spacing: AppTokens.space2,
          runSpacing: AppTokens.space2,
          children: SplitMethod.values.map((method) {
            final isSelected = method == selectedMethod;
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(method.icon),
                  const SizedBox(width: AppTokens.space1),
                  Text(method.displayName),
                ],
              ),
              selected: isSelected,
              onSelected: enabled ? (selected) {
                if (selected) onMethodChanged(method);
              } : null,
              tooltip: method.description,
            );
          }).toList(),
        ),
      ],
    );
  }
}

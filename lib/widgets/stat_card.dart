import 'package:flutter/material.dart';
import '../app/theme/tokens.dart';

/// A card widget for displaying statistics
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.color,
    this.icon,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        child: Padding(
          padding: AppTokens.cardPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (icon != null)
                    Icon(
                      icon,
                      size: AppTokens.iconMd,
                      color: effectiveColor,
                    ),
                ],
              ),
              
              const SizedBox(height: AppTokens.space2),
              
              // Value
              if (isLoading)
                SizedBox(
                  height: 24,
                  width: 60,
                  child: LinearProgressIndicator(
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
                  ),
                )
              else
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: effectiveColor,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A larger stat card with more details
class DetailedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading;
  final Widget? trailing;

  const DetailedStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.color,
    this.icon,
    this.onTap,
    this.isLoading = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        child: Padding(
          padding: AppTokens.cardPaddingLarge,
          child: Row(
            children: [
              // Icon
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppTokens.space3),
                  decoration: BoxDecoration(
                    color: effectiveColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                  ),
                  child: Icon(
                    icon,
                    size: AppTokens.iconLg,
                    color: effectiveColor,
                  ),
                ),
                const SizedBox(width: AppTokens.space4),
              ],
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppTokens.space1),
                    if (isLoading)
                      SizedBox(
                        height: 28,
                        width: 120,
                        child: LinearProgressIndicator(
                          backgroundColor: theme.colorScheme.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
                        ),
                      )
                    else
                      Text(
                        value,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: effectiveColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppTokens.space1),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Trailing widget
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

/// A horizontal stat card for dashboard layouts
class HorizontalStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? change;
  final bool isPositiveChange;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading;

  const HorizontalStatCard({
    super.key,
    required this.title,
    required this.value,
    this.change,
    this.isPositiveChange = true,
    this.color,
    this.icon,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        child: Padding(
          padding: AppTokens.cardPadding,
          child: Row(
            children: [
              // Icon
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppTokens.space2),
                  decoration: BoxDecoration(
                    color: effectiveColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                  child: Icon(
                    icon,
                    size: AppTokens.iconMd,
                    color: effectiveColor,
                  ),
                ),
                const SizedBox(width: AppTokens.space3),
              ],
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppTokens.space1),
                    if (isLoading)
                      SizedBox(
                        height: 20,
                        width: 80,
                        child: LinearProgressIndicator(
                          backgroundColor: theme.colorScheme.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
                        ),
                      )
                    else
                      Text(
                        value,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: effectiveColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Change indicator
              if (change != null && !isLoading) ...[
                const SizedBox(width: AppTokens.space2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space2,
                    vertical: AppTokens.space1,
                  ),
                  decoration: BoxDecoration(
                    color: (isPositiveChange ? Colors.green : Colors.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositiveChange ? Icons.trending_up : Icons.trending_down,
                        size: AppTokens.iconSm,
                        color: isPositiveChange ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: AppTokens.space1),
                      Text(
                        change!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isPositiveChange ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact stat card for grid layouts
class CompactStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading;

  const CompactStatCard({
    super.key,
    required this.title,
    required this.value,
    this.color,
    this.icon,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: AppTokens.iconLg,
                  color: effectiveColor,
                ),
                const SizedBox(height: AppTokens.space2),
              ],
              if (isLoading)
                SizedBox(
                  height: 20,
                  width: 60,
                  child: LinearProgressIndicator(
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
                  ),
                )
              else
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: effectiveColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: AppTokens.space1),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
  }
}

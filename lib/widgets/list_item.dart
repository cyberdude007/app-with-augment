import 'package:flutter/material.dart';
import '../app/theme/tokens.dart';

/// A customizable list item widget
class AppListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final bool dense;
  final EdgeInsetsGeometry? contentPadding;

  const AppListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.dense = false,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppTokens.space1),
      child: ListTile(
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: enabled 
                ? theme.colorScheme.onSurface 
                : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: enabled 
                      ? theme.colorScheme.onSurfaceVariant 
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              )
            : null,
        leading: leading,
        trailing: trailing,
        onTap: enabled ? onTap : null,
        onLongPress: enabled ? onLongPress : null,
        enabled: enabled,
        dense: dense,
        contentPadding: contentPadding ?? AppTokens.listItemPadding,
      ),
    );
  }
}

/// A list item with an avatar
class AvatarListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? avatarText;
  final String? avatarEmoji;
  final Color? avatarColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;

  const AvatarListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.avatarText,
    this.avatarEmoji,
    this.avatarColor,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveAvatarColor = avatarColor ?? theme.colorScheme.primary;

    return AppListItem(
      title: title,
      subtitle: subtitle,
      leading: CircleAvatar(
        backgroundColor: effectiveAvatarColor.withOpacity(0.1),
        child: avatarEmoji != null
            ? Text(
                avatarEmoji!,
                style: const TextStyle(fontSize: 20),
              )
            : Text(
                avatarText ?? title.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: effectiveAvatarColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
      enabled: enabled,
    );
  }
}

/// A list item with an icon
class IconListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;

  const IconListItem({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.iconColor,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;

    return AppListItem(
      title: title,
      subtitle: subtitle,
      leading: Container(
        padding: const EdgeInsets.all(AppTokens.space2),
        decoration: BoxDecoration(
          color: effectiveIconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
        child: Icon(
          icon,
          color: effectiveIconColor,
          size: AppTokens.iconMd,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
      enabled: enabled,
    );
  }
}

/// A list item for expenses
class ExpenseListItem extends StatelessWidget {
  final String description;
  final String amount;
  final String? paidBy;
  final String? category;
  final String date;
  final bool isSettled;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ExpenseListItem({
    super.key,
    required this.description,
    required this.amount,
    required this.date,
    this.paidBy,
    this.category,
    this.isSettled = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppListItem(
      title: description,
      subtitle: _buildSubtitle(context),
      leading: Container(
        padding: const EdgeInsets.all(AppTokens.space2),
        decoration: BoxDecoration(
          color: isSettled 
              ? Colors.green.withOpacity(0.1)
              : theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
        child: Icon(
          _getCategoryIcon(),
          color: isSettled ? Colors.green : theme.colorScheme.primary,
          size: AppTokens.iconMd,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            amount,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            date,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  String _buildSubtitle(BuildContext context) {
    final parts = <String>[];
    
    if (paidBy != null) {
      parts.add('Paid by $paidBy');
    }
    
    if (category != null) {
      parts.add(category!);
    }
    
    if (isSettled) {
      parts.add('Settled');
    }
    
    return parts.join(' • ');
  }

  IconData _getCategoryIcon() {
    if (category == null) return Icons.receipt;
    
    return switch (category!.toLowerCase()) {
      'food' => Icons.restaurant,
      'transport' => Icons.directions_car,
      'groceries' => Icons.shopping_cart,
      'utilities' => Icons.electrical_services,
      'shopping' => Icons.shopping_bag,
      'entertainment' => Icons.movie,
      'health' => Icons.local_hospital,
      'education' => Icons.school,
      'bills' => Icons.receipt_long,
      _ => Icons.receipt,
    };
  }
}

/// A list item for members
class MemberListItem extends StatelessWidget {
  final String name;
  final String? balance;
  final String? avatarEmoji;
  final bool isOwed;
  final bool isOwing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MemberListItem({
    super.key,
    required this.name,
    this.balance,
    this.avatarEmoji,
    this.isOwed = false,
    this.isOwing = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color? balanceColor;
    if (isOwed) {
      balanceColor = Colors.green;
    } else if (isOwing) {
      balanceColor = Colors.red;
    }

    return AvatarListItem(
      title: name,
      subtitle: _getSubtitle(),
      avatarEmoji: avatarEmoji,
      trailing: balance != null
          ? Text(
              balance!,
              style: theme.textTheme.titleMedium?.copyWith(
                color: balanceColor,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  String? _getSubtitle() {
    if (isOwed) return 'Owes you';
    if (isOwing) return 'You owe';
    return null;
  }
}

/// A list item for groups
class GroupListItem extends StatelessWidget {
  final String name;
  final int memberCount;
  final String? balance;
  final String? totalSpent;
  final String? lastActivity;
  final bool isSettled;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GroupListItem({
    super.key,
    required this.name,
    required this.memberCount,
    this.balance,
    this.totalSpent,
    this.lastActivity,
    this.isSettled = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppListItem(
      title: name,
      subtitle: _buildSubtitle(),
      leading: Container(
        padding: const EdgeInsets.all(AppTokens.space2),
        decoration: BoxDecoration(
          color: isSettled 
              ? Colors.green.withOpacity(0.1)
              : theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
        child: Icon(
          Icons.group,
          color: isSettled ? Colors.green : theme.colorScheme.primary,
          size: AppTokens.iconMd,
        ),
      ),
      trailing: balance != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  balance!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (totalSpent != null)
                  Text(
                    'Total: $totalSpent',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            )
          : null,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    
    parts.add('$memberCount member${memberCount == 1 ? '' : 's'}');
    
    if (lastActivity != null) {
      parts.add(lastActivity!);
    }
    
    if (isSettled) {
      parts.add('Settled');
    }
    
    return parts.join(' • ');
  }
}

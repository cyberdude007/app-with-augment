import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../widgets/list_item.dart';

/// Settings screen for app configuration
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: AppTokens.screenPadding,
        children: [
          // Account section
          _buildSectionHeader(context, 'Account'),
          IconListItem(
            title: 'Profile',
            subtitle: 'Manage your profile information',
            icon: Icons.person_outline,
            onTap: () => _showComingSoon(context),
          ),
          IconListItem(
            title: 'Backup & Sync',
            subtitle: 'Export and import your data',
            icon: Icons.backup_outlined,
            onTap: () => _showBackupOptions(context),
          ),

          const SizedBox(height: AppTokens.space6),

          // Security section
          _buildSectionHeader(context, 'Security'),
          IconListItem(
            title: 'App Lock',
            subtitle: 'PIN and biometric authentication',
            icon: Icons.lock_outline,
            onTap: () => _showSecuritySettings(context),
          ),

          const SizedBox(height: AppTokens.space6),

          // Preferences section
          _buildSectionHeader(context, 'Preferences'),
          IconListItem(
            title: 'Theme',
            subtitle: 'Light, dark, or system',
            icon: Icons.palette_outlined,
            trailing: const Text('System'),
            onTap: () => _showThemeSelector(context),
          ),
          IconListItem(
            title: 'Notifications',
            subtitle: 'Reminder and alert settings',
            icon: Icons.notifications_outlined,
            onTap: () => _showNotificationSettings(context),
          ),
          IconListItem(
            title: 'Currency',
            subtitle: 'Default currency for new expenses',
            icon: Icons.currency_rupee,
            trailing: const Text('INR'),
            onTap: () => _showComingSoon(context),
          ),

          const SizedBox(height: AppTokens.space6),

          // Data section
          _buildSectionHeader(context, 'Data'),
          IconListItem(
            title: 'Categories',
            subtitle: 'Manage expense categories',
            icon: Icons.category_outlined,
            onTap: () => _showComingSoon(context),
          ),
          IconListItem(
            title: 'Export Data',
            subtitle: 'Download your data as CSV or JSON',
            icon: Icons.download_outlined,
            onTap: () => _showExportOptions(context),
          ),
          IconListItem(
            title: 'Clear Data',
            subtitle: 'Reset all app data',
            icon: Icons.delete_outline,
            iconColor: Colors.red,
            onTap: () => _showClearDataDialog(context),
          ),

          const SizedBox(height: AppTokens.space6),

          // About section
          _buildSectionHeader(context, 'About'),
          IconListItem(
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            icon: Icons.help_outline,
            onTap: () => _showComingSoon(context),
          ),
          IconListItem(
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            icon: Icons.privacy_tip_outlined,
            onTap: () => _showComingSoon(context),
          ),
          IconListItem(
            title: 'About PaisaSplit',
            subtitle: 'Version 1.0.0',
            icon: Icons.info_outline,
            onTap: () => _showAboutDialog(context),
          ),

          const SizedBox(height: AppTokens.space6),

          // Debug section (only in debug mode)
          if (kDebugMode) ...[
            _buildSectionHeader(context, 'Debug'),
            IconListItem(
              title: 'App Statistics',
              subtitle: 'View app usage statistics',
              icon: Icons.analytics_outlined,
              onTap: () => _showAppStats(context),
            ),
          ],
        ],
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(
        left: AppTokens.space2,
        bottom: AppTokens.space2,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Show coming soon dialog
  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: const Text('This feature is coming in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show theme selector
  void _showThemeSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'light',
              groupValue: 'system',
              onChanged: (value) {
                Navigator.of(context).pop();
                // TODO: Update theme
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'dark',
              groupValue: 'system',
              onChanged: (value) {
                Navigator.of(context).pop();
                // TODO: Update theme
              },
            ),
            RadioListTile<String>(
              title: const Text('System'),
              value: 'system',
              groupValue: 'system',
              onChanged: (value) {
                Navigator.of(context).pop();
                // TODO: Update theme
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Show security settings
  void _showSecuritySettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: AppTokens.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Settings',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTokens.space4),
            SwitchListTile(
              title: const Text('Enable PIN'),
              subtitle: const Text('Require PIN to open app'),
              value: false,
              onChanged: (value) {
                // TODO: Handle PIN toggle
              },
            ),
            SwitchListTile(
              title: const Text('Enable Biometric'),
              subtitle: const Text('Use fingerprint or face unlock'),
              value: true,
              onChanged: (value) {
                // TODO: Handle biometric toggle
              },
            ),
            ListTile(
              title: const Text('Auto-lock timeout'),
              subtitle: const Text('5 minutes'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Show timeout selector
              },
            ),
            const SizedBox(height: AppTokens.space4),
          ],
        ),
      ),
    );
  }

  /// Show notification settings
  void _showNotificationSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: AppTokens.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Settings',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTokens.space4),
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text('Receive reminders and alerts'),
              value: true,
              onChanged: (value) {
                // TODO: Handle notifications toggle
              },
            ),
            SwitchListTile(
              title: const Text('Expense Reminders'),
              subtitle: const Text('Remind to add expenses'),
              value: true,
              onChanged: (value) {
                // TODO: Handle expense reminders toggle
              },
            ),
            SwitchListTile(
              title: const Text('Settlement Reminders'),
              subtitle: const Text('Remind about pending settlements'),
              value: true,
              onChanged: (value) {
                // TODO: Handle settlement reminders toggle
              },
            ),
            const SizedBox(height: AppTokens.space4),
          ],
        ),
      ),
    );
  }

  /// Show backup options
  void _showBackupOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: AppTokens.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup & Sync',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTokens.space4),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Export Backup'),
              subtitle: const Text('Save your data to a file'),
              onTap: () {
                Navigator.of(context).pop();
                _showExportOptions(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Import Backup'),
              subtitle: const Text('Restore data from a file'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Handle import
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Last backup'),
              subtitle: const Text('Never'),
            ),
            const SizedBox(height: AppTokens.space4),
          ],
        ),
      ),
    );
  }

  /// Show export options
  void _showExportOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Choose export format:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Export as JSON
            },
            child: const Text('JSON'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Export as CSV
            },
            child: const Text('CSV'),
          ),
        ],
      ),
    );
  }

  /// Show clear data dialog
  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your expenses, groups, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Clear all data
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }

  /// Show about dialog
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'PaisaSplit',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.account_balance_wallet,
          size: 32,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      children: const [
        Text('Offline-first shared expense app that doubles as a personal financial journal.'),
        SizedBox(height: 16),
        Text('Built with Flutter and Drift for reliable offline functionality.'),
      ],
    );
  }

  /// Show app statistics
  void _showAppStats(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Statistics'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Members: 0'),
            Text('Groups: 0'),
            Text('Expenses: 0'),
            Text('Settlements: 0'),
            Text('Database size: 0 KB'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Debug mode check
const bool kDebugMode = bool.fromEnvironment('dart.vm.product') == false;

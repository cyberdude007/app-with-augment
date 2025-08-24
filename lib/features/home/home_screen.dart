import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/tokens.dart';
import '../../core/money/money.dart';
import '../../core/utils/date_fmt.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/list_item.dart';
import '../../widgets/search_bar.dart';

/// Home screen showing balance overview and groups
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('PaisaSplit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showNotifications(context),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMenu(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            // Balance overview section
            SliverToBoxAdapter(
              child: Padding(
                padding: AppTokens.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Balance',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppTokens.space4),
                    _buildBalanceCards(),
                    const SizedBox(height: AppTokens.space6),
                  ],
                ),
              ),
            ),
            
            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: AppTokens.screenPaddingHorizontal,
                child: AppSearchBar(
                  controller: _searchController,
                  hintText: 'Search groups...',
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space4)),
            
            // Groups section
            SliverToBoxAdapter(
              child: Padding(
                padding: AppTokens.screenPaddingHorizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Groups',
                      style: theme.textTheme.headlineSmall,
                    ),
                    TextButton.icon(
                      onPressed: () => _createNewGroup(context),
                      icon: const Icon(Icons.add),
                      label: const Text('New Group'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space2)),
            
            // Groups list
            _buildGroupsList(),
          ],
        ),
      ),
    );
  }

  /// Build balance overview cards
  Widget _buildBalanceCards() {
    // Mock data - replace with actual data from providers
    final youOwe = Money.fromRupees(1250.50);
    final youGet = Money.fromRupees(850.75);
    final netBalance = youGet - youOwe;

    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'You owe',
            value: youOwe.format(),
            color: Colors.red,
            icon: Icons.arrow_upward,
          ),
        ),
        const SizedBox(width: AppTokens.space4),
        Expanded(
          child: StatCard(
            title: 'You get',
            value: youGet.format(),
            color: Colors.green,
            icon: Icons.arrow_downward,
          ),
        ),
        const SizedBox(width: AppTokens.space4),
        Expanded(
          child: StatCard(
            title: 'Net balance',
            value: netBalance.format(),
            color: netBalance.isNegative ? Colors.red : Colors.green,
            icon: netBalance.isNegative ? Icons.trending_down : Icons.trending_up,
          ),
        ),
      ],
    );
  }

  /// Build groups list
  Widget _buildGroupsList() {
    // Mock data - replace with actual data from providers
    final groups = _getMockGroups();
    final filteredGroups = _searchQuery.isEmpty
        ? groups
        : groups.where((group) => 
            group.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    if (filteredGroups.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _searchQuery.isEmpty ? Icons.group_add : Icons.search_off,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppTokens.space4),
              Text(
                _searchQuery.isEmpty 
                    ? 'No groups yet'
                    : 'No groups found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTokens.space2),
              Text(
                _searchQuery.isEmpty
                    ? 'Create your first group to start splitting expenses'
                    : 'Try a different search term',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (_searchQuery.isEmpty) ...[
                const SizedBox(height: AppTokens.space6),
                ElevatedButton.icon(
                  onPressed: () => _createNewGroup(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Group'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final group = filteredGroups[index];
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space4,
              vertical: AppTokens.space1,
            ),
            child: AppListItem(
              title: group.name,
              subtitle: '${group.memberCount} members • ${group.lastActivity}',
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    group.balance.format(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: group.balance.isNegative 
                          ? Colors.red 
                          : group.balance.isPositive 
                              ? Colors.green 
                              : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Total: ${group.totalSpent.format()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              onTap: () => context.push('/group/${group.id}'),
            ),
          );
        },
        childCount: filteredGroups.length,
      ),
    );
  }

  /// Get mock groups data
  List<MockGroup> _getMockGroups() {
    return [
      MockGroup(
        id: '1',
        name: 'Weekend Trip',
        memberCount: 4,
        balance: Money.fromRupees(-250.50),
        totalSpent: Money.fromRupees(2500.00),
        lastActivity: '2 days ago',
      ),
      MockGroup(
        id: '2',
        name: 'Roommates',
        memberCount: 3,
        balance: Money.fromRupees(150.25),
        totalSpent: Money.fromRupees(5200.75),
        lastActivity: 'Yesterday',
      ),
      MockGroup(
        id: '3',
        name: 'Office Lunch',
        memberCount: 8,
        balance: Money.zero,
        totalSpent: Money.fromRupees(1800.00),
        lastActivity: 'Today',
      ),
    ];
  }

  /// Handle refresh
  Future<void> _onRefresh() async {
    // Refresh data from providers
    await Future.delayed(const Duration(seconds: 1)); // Mock delay
  }

  /// Show notifications
  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Text('No new notifications'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show menu
  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup Data'),
            onTap: () {
              Navigator.of(context).pop();
              _showBackupDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore Data'),
            onTap: () {
              Navigator.of(context).pop();
              _showRestoreDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.of(context).pop();
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  /// Create new group
  void _createNewGroup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Group'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'Group Name',
            hintText: 'Enter group name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Create group logic
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  /// Show backup dialog
  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Data'),
        content: const Text('Export your data to a secure backup file.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Backup logic
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  /// Show restore dialog
  void _showRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Data'),
        content: const Text('Import data from a backup file.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Restore logic
            },
            child: const Text('Import'),
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
      children: [
        const Text('Offline-first shared expense app that doubles as a personal financial journal.'),
      ],
    );
  }
}

/// Mock group data class
class MockGroup {
  final String id;
  final String name;
  final int memberCount;
  final Money balance;
  final Money totalSpent;
  final String lastActivity;

  const MockGroup({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.balance,
    required this.totalSpent,
    required this.lastActivity,
  });
}

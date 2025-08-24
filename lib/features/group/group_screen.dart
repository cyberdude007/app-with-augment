import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/tokens.dart';
import '../../core/money/money.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/list_item.dart';

/// Group detail screen showing expenses and balances
class GroupScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends ConsumerState<GroupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mock group data - replace with actual data from providers
    final group = _getMockGroup();

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () => _showMembers(context),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit Group'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settle',
                child: ListTile(
                  leading: Icon(Icons.account_balance),
                  title: Text('Settle Up'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (value) => _handleMenuAction(context, value as String),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Balances'),
            Tab(text: 'Activity'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExpensesTab(group),
          _buildBalancesTab(group),
          _buildActivityTab(group),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/new-expense?groupId=${widget.groupId}'),
        tooltip: 'Add Expense',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Build expenses tab
  Widget _buildExpensesTab(MockGroupDetail group) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        slivers: [
          // Group summary
          SliverToBoxAdapter(
            child: Padding(
              padding: AppTokens.screenPadding,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Total Spent',
                          value: group.totalSpent.format(),
                          icon: Icons.account_balance_wallet,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: AppTokens.space4),
                      Expanded(
                        child: StatCard(
                          title: 'Your Balance',
                          value: group.yourBalance.format(),
                          icon: group.yourBalance.isNegative 
                              ? Icons.trending_down 
                              : Icons.trending_up,
                          color: group.yourBalance.isNegative 
                              ? Colors.red 
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space6),
                ],
              ),
            ),
          ),

          // Expenses list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final expense = group.expenses[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space4,
                    vertical: AppTokens.space1,
                  ),
                  child: ExpenseListItem(
                    description: expense.description,
                    amount: expense.amount.format(),
                    paidBy: expense.paidBy,
                    category: expense.category,
                    date: expense.date,
                    isSettled: expense.isSettled,
                    onTap: () => _showExpenseDetails(context, expense),
                  ),
                );
              },
              childCount: group.expenses.length,
            ),
          ),
        ],
      ),
    );
  }

  /// Build balances tab
  Widget _buildBalancesTab(MockGroupDetail group) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        padding: AppTokens.screenPadding,
        itemCount: group.members.length,
        itemBuilder: (context, index) {
          final member = group.members[index];
          return MemberListItem(
            name: member.name,
            balance: member.balance.format(),
            avatarEmoji: member.avatarEmoji,
            isOwed: member.balance.isPositive,
            isOwing: member.balance.isNegative,
            onTap: () => _showMemberDetails(context, member),
          );
        },
      ),
    );
  }

  /// Build activity tab
  Widget _buildActivityTab(MockGroupDetail group) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        padding: AppTokens.screenPadding,
        itemCount: group.activities.length,
        itemBuilder: (context, index) {
          final activity = group.activities[index];
          return Card(
            margin: const EdgeInsets.only(bottom: AppTokens.space2),
            child: ListTile(
              leading: Icon(activity.icon),
              title: Text(activity.description),
              subtitle: Text(activity.timestamp),
              trailing: activity.amount != null
                  ? Text(
                      activity.amount!.format(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  /// Get mock group data
  MockGroupDetail _getMockGroup() {
    return MockGroupDetail(
      id: widget.groupId,
      name: 'Weekend Trip',
      totalSpent: Money.fromRupees(2500.00),
      yourBalance: Money.fromRupees(-250.50),
      members: [
        MockMember(
          id: '1',
          name: 'You',
          balance: Money.fromRupees(-250.50),
          avatarEmoji: '😊',
        ),
        MockMember(
          id: '2',
          name: 'Alice',
          balance: Money.fromRupees(150.25),
          avatarEmoji: '👩',
        ),
        MockMember(
          id: '3',
          name: 'Bob',
          balance: Money.fromRupees(100.25),
          avatarEmoji: '👨',
        ),
      ],
      expenses: [
        MockExpense(
          id: '1',
          description: 'Hotel Booking',
          amount: Money.fromRupees(1200.00),
          paidBy: 'Alice',
          category: 'Accommodation',
          date: '2 days ago',
          isSettled: false,
        ),
        MockExpense(
          id: '2',
          description: 'Dinner at Restaurant',
          amount: Money.fromRupees(800.00),
          paidBy: 'You',
          category: 'Food',
          date: 'Yesterday',
          isSettled: false,
        ),
        MockExpense(
          id: '3',
          description: 'Taxi to Airport',
          amount: Money.fromRupees(500.00),
          paidBy: 'Bob',
          category: 'Transport',
          date: 'Today',
          isSettled: false,
        ),
      ],
      activities: [
        MockActivity(
          description: 'You added "Taxi to Airport"',
          timestamp: '2 hours ago',
          amount: Money.fromRupees(500.00),
          icon: Icons.add_circle_outline,
        ),
        MockActivity(
          description: 'Alice joined the group',
          timestamp: '3 days ago',
          amount: null,
          icon: Icons.person_add,
        ),
      ],
    );
  }

  /// Handle menu actions
  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        _showComingSoon(context, 'Edit Group');
        break;
      case 'settle':
        context.push('/settle-up/${widget.groupId}');
        break;
      case 'export':
        _showComingSoon(context, 'Export Group');
        break;
    }
  }

  /// Show members dialog
  void _showMembers(BuildContext context) {
    final group = _getMockGroup();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Group Members'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: group.members.length,
            itemBuilder: (context, index) {
              final member = group.members[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(member.avatarEmoji ?? member.name[0]),
                ),
                title: Text(member.name),
                subtitle: Text(member.balance.format()),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showComingSoon(context, 'Add Member');
            },
            child: const Text('Add Member'),
          ),
        ],
      ),
    );
  }

  /// Show expense details
  void _showExpenseDetails(BuildContext context, MockExpense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(expense.description),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ${expense.amount.format()}'),
            Text('Paid by: ${expense.paidBy}'),
            Text('Category: ${expense.category}'),
            Text('Date: ${expense.date}'),
            Text('Status: ${expense.isSettled ? 'Settled' : 'Pending'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/edit-expense/${expense.id}');
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  /// Show member details
  void _showMemberDetails(BuildContext context, MockMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Balance: ${member.balance.format()}'),
            if (member.balance.isPositive)
              const Text('This member is owed money')
            else if (member.balance.isNegative)
              const Text('This member owes money')
            else
              const Text('This member is settled up'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show coming soon dialog
  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: const Text('This feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Handle refresh
  Future<void> _onRefresh() async {
    // Refresh group data
    await Future.delayed(const Duration(seconds: 1)); // Mock delay
  }
}

/// Mock group detail data
class MockGroupDetail {
  final String id;
  final String name;
  final Money totalSpent;
  final Money yourBalance;
  final List<MockMember> members;
  final List<MockExpense> expenses;
  final List<MockActivity> activities;

  const MockGroupDetail({
    required this.id,
    required this.name,
    required this.totalSpent,
    required this.yourBalance,
    required this.members,
    required this.expenses,
    required this.activities,
  });
}

/// Mock member data
class MockMember {
  final String id;
  final String name;
  final Money balance;
  final String? avatarEmoji;

  const MockMember({
    required this.id,
    required this.name,
    required this.balance,
    this.avatarEmoji,
  });
}

/// Mock expense data
class MockExpense {
  final String id;
  final String description;
  final Money amount;
  final String paidBy;
  final String category;
  final String date;
  final bool isSettled;

  const MockExpense({
    required this.id,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.category,
    required this.date,
    required this.isSettled,
  });
}

/// Mock activity data
class MockActivity {
  final String description;
  final String timestamp;
  final Money? amount;
  final IconData icon;

  const MockActivity({
    required this.description,
    required this.timestamp,
    required this.amount,
    required this.icon,
  });
}

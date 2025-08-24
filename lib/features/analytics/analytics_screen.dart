import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../core/money/money.dart';
import '../../core/utils/date_fmt.dart';
import '../../widgets/stat_card.dart';

/// Analytics screen showing spending insights
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateRange _selectedRange = DateRange.thisMonth;

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          PopupMenuButton<DateRange>(
            icon: const Icon(Icons.date_range),
            onSelected: (range) {
              setState(() {
                _selectedRange = range;
              });
            },
            itemBuilder: (context) => DateRange.values.map((range) {
              return PopupMenuItem(
                value: range,
                child: Row(
                  children: [
                    if (_selectedRange == range)
                      Icon(
                        Icons.check,
                        size: AppTokens.iconSm,
                        color: theme.colorScheme.primary,
                      )
                    else
                      const SizedBox(width: AppTokens.iconSm),
                    const SizedBox(width: AppTokens.space2),
                    Text(range.displayName),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Categories'),
            Tab(text: 'Trends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildCategoriesTab(),
          _buildTrendsTab(),
        ],
      ),
    );
  }

  /// Build overview tab
  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        padding: AppTokens.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector
            _buildPeriodHeader(),
            const SizedBox(height: AppTokens.space6),

            // Summary cards
            _buildSummaryCards(),
            const SizedBox(height: AppTokens.space6),

            // Recent activity
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  /// Build categories tab
  Widget _buildCategoriesTab() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        padding: AppTokens.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period header
            _buildPeriodHeader(),
            const SizedBox(height: AppTokens.space6),

            // Category breakdown
            _buildCategoryBreakdown(),
          ],
        ),
      ),
    );
  }

  /// Build trends tab
  Widget _buildTrendsTab() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        padding: AppTokens.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period header
            _buildPeriodHeader(),
            const SizedBox(height: AppTokens.space6),

            // Spending trends
            _buildSpendingTrends(),
          ],
        ),
      ),
    );
  }

  /// Build period header
  Widget _buildPeriodHeader() {
    final theme = Theme.of(context);
    final (startDate, endDate) = _getDateRange();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedRange.displayName,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppTokens.space1),
        Text(
          DateFormatter.dateRange(startDate, endDate),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Build summary cards
  Widget _buildSummaryCards() {
    // Mock data - replace with actual data from providers
    final totalSpent = Money.fromRupees(12450.75);
    final avgPerDay = Money.fromRupees(415.36);
    final expenseCount = 28;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DetailedStatCard(
                title: 'Total Spent',
                value: totalSpent.format(),
                icon: Icons.account_balance_wallet,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space4),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Avg/Day',
                value: avgPerDay.format(),
                icon: Icons.trending_up,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: AppTokens.space4),
            Expanded(
              child: StatCard(
                title: 'Expenses',
                value: expenseCount.toString(),
                icon: Icons.receipt,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build recent activity
  Widget _buildRecentActivity() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppTokens.space4),
        
        // Mock recent expenses
        ..._getMockRecentExpenses().map((expense) => Card(
          margin: const EdgeInsets.only(bottom: AppTokens.space2),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(AppTokens.space2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              ),
              child: Icon(
                expense.icon,
                color: theme.colorScheme.primary,
                size: AppTokens.iconMd,
              ),
            ),
            title: Text(expense.description),
            subtitle: Text('${expense.category} • ${expense.date}'),
            trailing: Text(
              expense.amount.format(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )),
      ],
    );
  }

  /// Build category breakdown
  Widget _buildCategoryBreakdown() {
    final theme = Theme.of(context);
    final categories = _getMockCategoryData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spending by Category',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppTokens.space4),
        
        ...categories.map((category) => Card(
          margin: const EdgeInsets.only(bottom: AppTokens.space2),
          child: Padding(
            padding: AppTokens.cardPadding,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTokens.space2),
                          decoration: BoxDecoration(
                            color: category.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                          ),
                          child: Icon(
                            category.icon,
                            color: category.color,
                            size: AppTokens.iconMd,
                          ),
                        ),
                        const SizedBox(width: AppTokens.space3),
                        Text(
                          category.name,
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          category.amount.format(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${category.percentage.toStringAsFixed(1)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.space2),
                LinearProgressIndicator(
                  value: category.percentage / 100,
                  backgroundColor: category.color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(category.color),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  /// Build spending trends
  Widget _buildSpendingTrends() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spending Trends',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppTokens.space4),
        
        Card(
          child: Padding(
            padding: AppTokens.cardPaddingLarge,
            child: Column(
              children: [
                Text(
                  'Chart visualization would go here',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppTokens.space4),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppTokens.space2),
                        Text(
                          'Spending chart placeholder',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Get date range for selected period
  (DateTime, DateTime) _getDateRange() {
    final now = DateTime.now();
    
    return switch (_selectedRange) {
      DateRange.thisWeek => (
        DateFormatter.startOfWeek(now),
        DateFormatter.endOfWeek(now),
      ),
      DateRange.thisMonth => (
        DateFormatter.startOfMonth(now),
        DateFormatter.endOfMonth(now),
      ),
      DateRange.thisYear => (
        DateFormatter.startOfYear(now),
        DateFormatter.endOfYear(now),
      ),
      DateRange.last30Days => (
        now.subtract(const Duration(days: 30)),
        now,
      ),
      DateRange.last90Days => (
        now.subtract(const Duration(days: 90)),
        now,
      ),
    };
  }

  /// Get mock recent expenses
  List<MockExpense> _getMockRecentExpenses() {
    return [
      MockExpense(
        description: 'Grocery Shopping',
        category: 'Groceries',
        amount: Money.fromRupees(850.50),
        date: 'Today',
        icon: Icons.shopping_cart,
      ),
      MockExpense(
        description: 'Lunch at Restaurant',
        category: 'Food',
        amount: Money.fromRupees(450.00),
        date: 'Yesterday',
        icon: Icons.restaurant,
      ),
      MockExpense(
        description: 'Uber Ride',
        category: 'Transport',
        amount: Money.fromRupees(120.75),
        date: '2 days ago',
        icon: Icons.directions_car,
      ),
    ];
  }

  /// Get mock category data
  List<MockCategory> _getMockCategoryData() {
    return [
      MockCategory(
        name: 'Food',
        amount: Money.fromRupees(4200.50),
        percentage: 33.7,
        color: Colors.orange,
        icon: Icons.restaurant,
      ),
      MockCategory(
        name: 'Transport',
        amount: Money.fromRupees(2800.25),
        percentage: 22.5,
        color: Colors.blue,
        icon: Icons.directions_car,
      ),
      MockCategory(
        name: 'Groceries',
        amount: Money.fromRupees(2100.00),
        percentage: 16.9,
        color: Colors.green,
        icon: Icons.shopping_cart,
      ),
      MockCategory(
        name: 'Entertainment',
        amount: Money.fromRupees(1500.75),
        percentage: 12.1,
        color: Colors.purple,
        icon: Icons.movie,
      ),
      MockCategory(
        name: 'Others',
        amount: Money.fromRupees(1849.25),
        percentage: 14.8,
        color: Colors.grey,
        icon: Icons.more_horiz,
      ),
    ];
  }

  /// Handle refresh
  Future<void> _onRefresh() async {
    // Refresh analytics data
    await Future.delayed(const Duration(seconds: 1)); // Mock delay
  }
}

/// Date range options
enum DateRange {
  thisWeek('This Week'),
  thisMonth('This Month'),
  thisYear('This Year'),
  last30Days('Last 30 Days'),
  last90Days('Last 90 Days');

  const DateRange(this.displayName);
  final String displayName;
}

/// Mock expense data
class MockExpense {
  final String description;
  final String category;
  final Money amount;
  final String date;
  final IconData icon;

  const MockExpense({
    required this.description,
    required this.category,
    required this.amount,
    required this.date,
    required this.icon,
  });
}

/// Mock category data
class MockCategory {
  final String name;
  final Money amount;
  final double percentage;
  final Color color;
  final IconData icon;

  const MockCategory({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.icon,
  });
}

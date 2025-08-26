import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../app/theme/tokens.dart';
import '../../core/money/money.dart';
import '../../core/utils/date_fmt.dart';
import '../../widgets/stat_card.dart';

/// Analytics screen with Consumption vs Cashflow toggle and time period tabs
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AnalyticsMode _selectedMode = AnalyticsMode.consumption;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'This Month'),
            Tab(text: 'Last 6 Months'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Analytics mode toggle
          _buildModeToggle(),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildThisMonthView(),
                _buildLast6MonthsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      margin: const EdgeInsets.all(AppTokens.space4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: AnalyticsMode.values.map((mode) {
          final isSelected = mode == _selectedMode;
          final isFirst = mode == AnalyticsMode.values.first;
          final isLast = mode == AnalyticsMode.values.last;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMode = mode;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space4,
                  vertical: AppTokens.space3,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.horizontal(
                    left: isFirst ? const Radius.circular(AppTokens.radiusLg) : Radius.zero,
                    right: isLast ? const Radius.circular(AppTokens.radiusLg) : Radius.zero,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mode.displayName,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTokens.space1),
                    Text(
                      mode.description,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.8)
                            : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
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

  Widget _buildThisMonthView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          _buildSummaryCards(),
          
          const SizedBox(height: AppTokens.space6),
          
          // Category breakdown chart
          _buildCategoryChart(),
          
          const SizedBox(height: AppTokens.space6),
          
          // Top categories list
          _buildTopCategoriesList(),
          
          const SizedBox(height: AppTokens.space6),
          
          // Top partners (for split expenses)
          if (_selectedMode == AnalyticsMode.consumption)
            _buildTopPartnersList(),
        ],
      ),
    );
  }

  Widget _buildLast6MonthsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly trend chart
          _buildMonthlyTrendChart(),
          
          const SizedBox(height: AppTokens.space6),
          
          // Category trends
          _buildCategoryTrends(),
          
          const SizedBox(height: AppTokens.space6),
          
          // Monthly summary
          _buildMonthlySummary(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    // Mock data - will be replaced with real analytics
    final totalAmount = _selectedMode == AnalyticsMode.consumption
        ? Money.fromRupees(12500.0)
        : Money.fromRupees(18750.0);
    
    final avgDaily = Money.fromRupees(totalAmount.rupees / 30);
    final transactionCount = _selectedMode == AnalyticsMode.consumption ? 45 : 32;

    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: _selectedMode == AnalyticsMode.consumption ? 'Total Consumption' : 'Total Cashflow',
            value: totalAmount.formatDisplay(),
            color: Theme.of(context).colorScheme.primary,
            icon: _selectedMode == AnalyticsMode.consumption ? Icons.pie_chart : Icons.trending_up,
          ),
        ),
        const SizedBox(width: AppTokens.space3),
        Expanded(
          child: StatCard(
            title: 'Daily Average',
            value: avgDaily.formatDisplay(),
            color: Theme.of(context).colorScheme.secondary,
            icon: Icons.calendar_today,
          ),
        ),
        const SizedBox(width: AppTokens.space3),
        Expanded(
          child: StatCard(
            title: 'Transactions',
            value: transactionCount.toString(),
            color: Theme.of(context).colorScheme.tertiary,
            icon: Icons.receipt_long,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTokens.space4),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _getMockPieChartSections(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategoriesList() {
    final categories = _getMockTopCategories();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Categories',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTokens.space3),
            ...categories.map((category) => _buildCategoryListItem(category)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPartnersList() {
    final partners = _getMockTopPartners();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Partners',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTokens.space3),
            ...partners.map((partner) => _buildPartnerListItem(partner)),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTrendChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Trend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTokens.space4),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getMockLineChartSpots(),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTrends() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Trends',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTokens.space3),
            const Text('Category trend analysis - Coming soon'),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTokens.space3),
            const Text('Monthly breakdown - Coming soon'),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryListItem(MockCategoryData category) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
      child: Row(
        children: [
          Text(
            category.emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: AppTokens.space2),
          Expanded(
            child: Text(
              category.name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                category.amount.formatDisplay(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${category.percentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerListItem(MockPartnerData partner) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            child: Text(partner.name[0]),
          ),
          const SizedBox(width: AppTokens.space2),
          Expanded(
            child: Text(
              partner.name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                partner.amount.formatDisplay(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${partner.transactionCount} transactions',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Mock data methods
  List<PieChartSectionData> _getMockPieChartSections() {
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Theme.of(context).colorScheme.error,
      Theme.of(context).colorScheme.outline,
    ];

    return [
      PieChartSectionData(value: 35, color: colors[0], title: 'Food\n35%', radius: 60),
      PieChartSectionData(value: 25, color: colors[1], title: 'Transport\n25%', radius: 60),
      PieChartSectionData(value: 20, color: colors[2], title: 'Shopping\n20%', radius: 60),
      PieChartSectionData(value: 12, color: colors[3], title: 'Bills\n12%', radius: 60),
      PieChartSectionData(value: 8, color: colors[4], title: 'Others\n8%', radius: 60),
    ];
  }

  List<FlSpot> _getMockLineChartSpots() {
    return [
      const FlSpot(0, 8000),
      const FlSpot(1, 12000),
      const FlSpot(2, 9500),
      const FlSpot(3, 15000),
      const FlSpot(4, 11000),
      const FlSpot(5, 12500),
    ];
  }

  List<MockCategoryData> _getMockTopCategories() {
    return [
      MockCategoryData('Food', '🍽️', Money.fromRupees(4375.0), 35.0),
      MockCategoryData('Transport', '🚕', Money.fromRupees(3125.0), 25.0),
      MockCategoryData('Shopping', '🛍️', Money.fromRupees(2500.0), 20.0),
      MockCategoryData('Bills', '🧾', Money.fromRupees(1500.0), 12.0),
      MockCategoryData('Entertainment', '🎬', Money.fromRupees(1000.0), 8.0),
    ];
  }

  List<MockPartnerData> _getMockTopPartners() {
    return [
      MockPartnerData('Alice', Money.fromRupees(3200.0), 12),
      MockPartnerData('Bob', Money.fromRupees(2800.0), 8),
      MockPartnerData('Charlie', Money.fromRupees(2100.0), 6),
      MockPartnerData('Diana', Money.fromRupees(1500.0), 4),
    ];
  }
}

/// Analytics mode enumeration
enum AnalyticsMode {
  consumption,
  cashflow;

  String get displayName => switch (this) {
    AnalyticsMode.consumption => 'Consumption',
    AnalyticsMode.cashflow => 'Cashflow',
  };

  String get description => switch (this) {
    AnalyticsMode.consumption => 'My Share',
    AnalyticsMode.cashflow => 'Out-of-Pocket',
  };
}

/// Mock data classes
class MockCategoryData {
  final String name;
  final String emoji;
  final Money amount;
  final double percentage;

  const MockCategoryData(this.name, this.emoji, this.amount, this.percentage);
}

class MockPartnerData {
  final String name;
  final Money amount;
  final int transactionCount;

  const MockPartnerData(this.name, this.amount, this.transactionCount);
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/tokens.dart';
import '../../core/money/money.dart';
import '../../widgets/list_item.dart';

/// Screen for settling up group balances
class SettleUpScreen extends ConsumerStatefulWidget {
  final String groupId;

  const SettleUpScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends ConsumerState<SettleUpScreen> {
  List<Settlement> _suggestedSettlements = [];

  @override
  void initState() {
    super.initState();
    _calculateSettlements();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settle Up'),
        actions: [
          TextButton(
            onPressed: _settleAll,
            child: const Text('Settle All'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          padding: AppTokens.screenPadding,
          children: [
            // Group info
            Card(
              child: Padding(
                padding: AppTokens.cardPaddingLarge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekend Trip',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppTokens.space2),
                    Text(
                      'Total spent: ${Money.fromRupees(2500.00).format()}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTokens.space6),

            // Current balances
            Text(
              'Current Balances',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTokens.space4),

            ..._getCurrentBalances().map((balance) => MemberListItem(
              name: balance.memberName,
              balance: balance.amount.format(),
              avatarEmoji: balance.avatarEmoji,
              isOwed: balance.amount.isPositive,
              isOwing: balance.amount.isNegative,
            )),

            const SizedBox(height: AppTokens.space6),

            // Suggested settlements
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Suggested Settlements',
                  style: theme.textTheme.headlineSmall,
                ),
                TextButton(
                  onPressed: _optimizeSettlements,
                  child: const Text('Optimize'),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space4),

            if (_suggestedSettlements.isEmpty)
              Card(
                child: Padding(
                  padding: AppTokens.cardPaddingLarge,
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: Colors.green,
                      ),
                      const SizedBox(height: AppTokens.space4),
                      Text(
                        'All settled up!',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: AppTokens.space2),
                      Text(
                        'Everyone is even in this group.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._suggestedSettlements.map((settlement) => Card(
                margin: const EdgeInsets.only(bottom: AppTokens.space2),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(settlement.fromAvatarEmoji ?? settlement.fromName[0]),
                  ),
                  title: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyLarge,
                      children: [
                        TextSpan(text: settlement.fromName),
                        const TextSpan(text: ' pays '),
                        TextSpan(text: settlement.toName),
                      ],
                    ),
                  ),
                  subtitle: Text('Settles ${settlement.description}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        settlement.amount.format(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _recordSettlement(settlement),
                        child: const Text('Record'),
                      ),
                    ],
                  ),
                ),
              )),

            const SizedBox(height: AppTokens.space6),

            // Manual settlement
            Card(
              child: Padding(
                padding: AppTokens.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Record Manual Settlement',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTokens.space2),
                    Text(
                      'Record a payment that happened outside the app',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppTokens.space4),
                    ElevatedButton.icon(
                      onPressed: _showManualSettlementDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Settlement'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTokens.space6),

            // Settlement history
            Text(
              'Settlement History',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTokens.space4),

            ..._getSettlementHistory().map((settlement) => Card(
              margin: const EdgeInsets.only(bottom: AppTokens.space2),
              child: ListTile(
                leading: const Icon(Icons.payment, color: Colors.green),
                title: RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: [
                      TextSpan(text: settlement.fromName),
                      const TextSpan(text: ' paid '),
                      TextSpan(text: settlement.toName),
                    ],
                  ),
                ),
                subtitle: Text(settlement.date),
                trailing: Text(
                  settlement.amount.format(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// Calculate suggested settlements
  void _calculateSettlements() {
    // Mock settlement calculation - replace with actual algorithm
    _suggestedSettlements = [
      Settlement(
        fromName: 'You',
        fromAvatarEmoji: '😊',
        toName: 'Alice',
        toAvatarEmoji: '👩',
        amount: Money.fromRupees(250.50),
        description: 'your share of group expenses',
      ),
    ];
  }

  /// Get current balances
  List<MemberBalance> _getCurrentBalances() {
    return [
      MemberBalance(
        memberName: 'You',
        amount: Money.fromRupees(-250.50),
        avatarEmoji: '😊',
      ),
      MemberBalance(
        memberName: 'Alice',
        amount: Money.fromRupees(150.25),
        avatarEmoji: '👩',
      ),
      MemberBalance(
        memberName: 'Bob',
        amount: Money.fromRupees(100.25),
        avatarEmoji: '👨',
      ),
    ];
  }

  /// Get settlement history
  List<SettlementHistory> _getSettlementHistory() {
    return [
      SettlementHistory(
        fromName: 'Bob',
        toName: 'Alice',
        amount: Money.fromRupees(50.00),
        date: '3 days ago',
      ),
    ];
  }

  /// Optimize settlements
  void _optimizeSettlements() {
    // TODO: Implement settlement optimization algorithm
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settlements optimized!'),
      ),
    );
  }

  /// Record a settlement
  void _recordSettlement(Settlement settlement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Settlement'),
        content: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyLarge,
            children: [
              const TextSpan(text: 'Record that '),
              TextSpan(
                text: settlement.fromName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' paid '),
              TextSpan(
                text: settlement.toName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' '),
              TextSpan(
                text: settlement.amount.format(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '?'),
            ],
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
              // TODO: Record settlement
              setState(() {
                _suggestedSettlements.remove(settlement);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settlement recorded!'),
                ),
              );
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  /// Show manual settlement dialog
  void _showManualSettlementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Settlement'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This feature allows you to record payments made outside the app.'),
            SizedBox(height: 16),
            Text('Coming soon!'),
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

  /// Settle all balances
  void _settleAll() {
    if (_suggestedSettlements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All balances are already settled!'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settle All'),
        content: Text(
          'This will record all ${_suggestedSettlements.length} suggested settlements. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Record all settlements
              setState(() {
                _suggestedSettlements.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All settlements recorded!'),
                ),
              );
            },
            child: const Text('Settle All'),
          ),
        ],
      ),
    );
  }

  /// Handle refresh
  Future<void> _onRefresh() async {
    _calculateSettlements();
    setState(() {});
    await Future.delayed(const Duration(seconds: 1)); // Mock delay
  }
}

/// Settlement suggestion
class Settlement {
  final String fromName;
  final String? fromAvatarEmoji;
  final String toName;
  final String? toAvatarEmoji;
  final Money amount;
  final String description;

  const Settlement({
    required this.fromName,
    this.fromAvatarEmoji,
    required this.toName,
    this.toAvatarEmoji,
    required this.amount,
    required this.description,
  });
}

/// Member balance
class MemberBalance {
  final String memberName;
  final Money amount;
  final String? avatarEmoji;

  const MemberBalance({
    required this.memberName,
    required this.amount,
    this.avatarEmoji,
  });
}

/// Settlement history item
class SettlementHistory {
  final String fromName;
  final String toName;
  final Money amount;
  final String date;

  const SettlementHistory({
    required this.fromName,
    required this.toName,
    required this.amount,
    required this.date,
  });
}

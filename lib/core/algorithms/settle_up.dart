import '../money/money.dart';

/// Algorithm for calculating who should pay whom to settle group expenses
class SettleUpAlgorithm {
  SettleUpAlgorithm._();

  /// Calculate optimal transfers to settle all debts in a group
  /// 
  /// Takes a map of member ID to net balance (positive = creditor, negative = debtor)
  /// Returns a list of transfers that will bring all balances to zero
  /// 
  /// Uses greedy algorithm: match largest debtor with largest creditor
  static List<Transfer> calculateTransfers(Map<String, Money> netBalances) {
    if (netBalances.isEmpty) return [];

    // Validate that total net balance is zero (or very close due to rounding)
    final totalBalance = netBalances.values.sum();
    if (totalBalance.paise.abs() > 1) {
      throw ArgumentError(
        'Net balances must sum to zero, got ${totalBalance.format()}',
      );
    }

    // Separate creditors (positive balance) and debtors (negative balance)
    final creditors = <String, Money>{};
    final debtors = <String, Money>{};

    for (final entry in netBalances.entries) {
      final memberId = entry.key;
      final balance = entry.value;

      if (balance.isPositive) {
        creditors[memberId] = balance;
      } else if (balance.isNegative) {
        debtors[memberId] = balance.abs; // Store as positive amount
      }
      // Skip zero balances
    }

    return _greedySettle(creditors, debtors);
  }

  /// Greedy algorithm to minimize number of transfers
  static List<Transfer> _greedySettle(
    Map<String, Money> creditors,
    Map<String, Money> debtors,
  ) {
    final transfers = <Transfer>[];
    
    // Create mutable copies
    final remainingCreditors = Map<String, Money>.from(creditors);
    final remainingDebtors = Map<String, Money>.from(debtors);

    while (remainingCreditors.isNotEmpty && remainingDebtors.isNotEmpty) {
      // Find largest creditor and debtor
      final largestCreditor = _findLargestBalance(remainingCreditors);
      final largestDebtor = _findLargestBalance(remainingDebtors);

      final creditorId = largestCreditor.key;
      final debtorId = largestDebtor.key;
      final creditorAmount = largestCreditor.value;
      final debtorAmount = largestDebtor.value;

      // Transfer the minimum of what creditor is owed and debtor owes
      final transferAmount = Money.min(creditorAmount, debtorAmount);

      transfers.add(Transfer(
        fromMemberId: debtorId,
        toMemberId: creditorId,
        amount: transferAmount,
      ));

      // Update remaining balances
      final newCreditorAmount = creditorAmount - transferAmount;
      final newDebtorAmount = debtorAmount - transferAmount;

      if (newCreditorAmount.isZero) {
        remainingCreditors.remove(creditorId);
      } else {
        remainingCreditors[creditorId] = newCreditorAmount;
      }

      if (newDebtorAmount.isZero) {
        remainingDebtors.remove(debtorId);
      } else {
        remainingDebtors[debtorId] = newDebtorAmount;
      }
    }

    return transfers;
  }

  /// Find the entry with the largest balance
  static MapEntry<String, Money> _findLargestBalance(Map<String, Money> balances) {
    return balances.entries.reduce((a, b) => a.value > b.value ? a : b);
  }

  /// Calculate net balances for each member in a group
  /// 
  /// Takes expenses and settlements, returns net balance per member
  /// Positive balance = member is owed money (creditor)
  /// Negative balance = member owes money (debtor)
  static Map<String, Money> calculateNetBalances({
    required List<ExpenseShare> expenseShares,
    required List<Settlement> settlements,
  }) {
    final balances = <String, Money>{};

    // Add expense shares (what each member owes/is owed)
    for (final share in expenseShares) {
      final payerId = share.payerId;
      final memberId = share.memberId;
      final amount = share.amount;

      // Payer gets credited (positive balance)
      balances[payerId] = (balances[payerId] ?? Money.zero) + amount;
      
      // Member who benefited gets debited (negative balance)
      balances[memberId] = (balances[memberId] ?? Money.zero) - amount;
    }

    // Subtract settlements (payments made to settle debts)
    for (final settlement in settlements) {
      final fromId = settlement.fromMemberId;
      final toId = settlement.toMemberId;
      final amount = settlement.amount;

      // Payer's debt decreases (balance becomes more positive)
      balances[fromId] = (balances[fromId] ?? Money.zero) + amount;
      
      // Receiver's credit decreases (balance becomes less positive)
      balances[toId] = (balances[toId] ?? Money.zero) - amount;
    }

    // Remove zero balances for cleaner output
    balances.removeWhere((_, balance) => balance.isZero);

    return balances;
  }

  /// Validate that a list of transfers settles all debts
  static bool validateTransfers(
    Map<String, Money> originalBalances,
    List<Transfer> transfers,
  ) {
    final balancesAfterTransfers = Map<String, Money>.from(originalBalances);

    for (final transfer in transfers) {
      final fromId = transfer.fromMemberId;
      final toId = transfer.toMemberId;
      final amount = transfer.amount;

      balancesAfterTransfers[fromId] = 
          (balancesAfterTransfers[fromId] ?? Money.zero) + amount;
      balancesAfterTransfers[toId] = 
          (balancesAfterTransfers[toId] ?? Money.zero) - amount;
    }

    // All balances should be zero (or very close due to rounding)
    return balancesAfterTransfers.values.every((balance) => balance.paise.abs() <= 1);
  }

  /// Get summary of who owes what in a group
  static GroupBalanceSummary getGroupSummary(Map<String, Money> netBalances) {
    Money totalOwed = Money.zero;
    Money totalToReceive = Money.zero;
    final creditors = <String, Money>{};
    final debtors = <String, Money>{};

    for (final entry in netBalances.entries) {
      final memberId = entry.key;
      final balance = entry.value;

      if (balance.isPositive) {
        creditors[memberId] = balance;
        totalToReceive = totalToReceive + balance;
      } else if (balance.isNegative) {
        debtors[memberId] = balance.abs;
        totalOwed = totalOwed + balance.abs;
      }
    }

    return GroupBalanceSummary(
      totalOwed: totalOwed,
      totalToReceive: totalToReceive,
      creditors: creditors,
      debtors: debtors,
    );
  }
}

/// Represents a transfer from one member to another
class Transfer {
  final String fromMemberId;
  final String toMemberId;
  final Money amount;

  const Transfer({
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transfer &&
          fromMemberId == other.fromMemberId &&
          toMemberId == other.toMemberId &&
          amount == other.amount;

  @override
  int get hashCode => Object.hash(fromMemberId, toMemberId, amount);

  @override
  String toString() => 
      'Transfer($fromMemberId → $toMemberId: ${amount.format()})';

  /// Convert to JSON representation
  Map<String, dynamic> toJson() => {
        'fromMemberId': fromMemberId,
        'toMemberId': toMemberId,
        'amount': amount.toJson(),
      };

  /// Create Transfer from JSON representation
  static Transfer fromJson(Map<String, dynamic> json) => Transfer(
        fromMemberId: json['fromMemberId'] as String,
        toMemberId: json['toMemberId'] as String,
        amount: Money.fromJson(json['amount']),
      );
}

/// Represents an expense share (who paid and who benefited)
class ExpenseShare {
  final String payerId;
  final String memberId;
  final Money amount;

  const ExpenseShare({
    required this.payerId,
    required this.memberId,
    required this.amount,
  });

  @override
  String toString() => 
      'ExpenseShare($payerId paid ${amount.format()} for $memberId)';
}

/// Represents a settlement payment
class Settlement {
  final String fromMemberId;
  final String toMemberId;
  final Money amount;

  const Settlement({
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
  });

  @override
  String toString() => 
      'Settlement($fromMemberId paid ${amount.format()} to $toMemberId)';
}

/// Summary of group balance state
class GroupBalanceSummary {
  final Money totalOwed;
  final Money totalToReceive;
  final Map<String, Money> creditors;
  final Map<String, Money> debtors;

  const GroupBalanceSummary({
    required this.totalOwed,
    required this.totalToReceive,
    required this.creditors,
    required this.debtors,
  });

  /// Check if group is settled (no outstanding debts)
  bool get isSettled => totalOwed.isZero && totalToReceive.isZero;

  /// Get net balance for a specific member
  Money getNetBalance(String memberId) {
    if (creditors.containsKey(memberId)) {
      return creditors[memberId]!;
    } else if (debtors.containsKey(memberId)) {
      return -debtors[memberId]!;
    } else {
      return Money.zero;
    }
  }

  @override
  String toString() => 
      'GroupBalanceSummary(owed: ${totalOwed.format()}, to receive: ${totalToReceive.format()})';
}

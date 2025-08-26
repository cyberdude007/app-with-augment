import 'dart:math';
import '../money/money.dart';

/// Split calculation algorithms with deterministic rounding
class SplitCalculator {
  SplitCalculator._();

  /// Calculate equal split with deterministic remainder distribution
  /// Uses stable order (UUID ascending) for remainder distribution
  static Map<String, Money> calculateEqualSplit(
    Money totalAmount,
    List<String> memberIds,
  ) {
    if (memberIds.isEmpty) {
      throw ArgumentError('Member list cannot be empty');
    }

    // Sort member IDs for deterministic ordering
    final sortedMemberIds = List<String>.from(memberIds)..sort();
    
    final totalPaise = totalAmount.paise;
    final memberCount = sortedMemberIds.length;
    
    // Calculate base amount per member (floor division)
    final baseAmountPaise = totalPaise ~/ memberCount;
    final remainder = totalPaise % memberCount;
    
    final result = <String, Money>{};
    
    // Distribute base amount to all members
    for (int i = 0; i < sortedMemberIds.length; i++) {
      final memberId = sortedMemberIds[i];
      // Add +1 paise to first 'remainder' members for deterministic distribution
      final memberAmountPaise = baseAmountPaise + (i < remainder ? 1 : 0);
      result[memberId] = Money.fromPaise(memberAmountPaise);
    }
    
    return result;
  }

  /// Calculate percentage split with deterministic rounding
  static Map<String, Money> calculatePercentageSplit(
    Money totalAmount,
    Map<String, double> memberPercentages,
  ) {
    if (memberPercentages.isEmpty) {
      throw ArgumentError('Member percentages cannot be empty');
    }

    // Validate percentages sum to 100
    final totalPercentage = memberPercentages.values.fold(0.0, (a, b) => a + b);
    if ((totalPercentage - 100.0).abs() > 0.01) {
      throw ArgumentError('Percentages must sum to 100%, got $totalPercentage%');
    }

    final totalPaise = totalAmount.paise;
    final result = <String, Money>{};
    int distributedPaise = 0;
    
    // Sort member IDs for deterministic ordering
    final sortedMemberIds = memberPercentages.keys.toList()..sort();
    
    // Calculate floor amounts for each member
    for (final memberId in sortedMemberIds) {
      final percentage = memberPercentages[memberId]!;
      final memberAmountPaise = (totalPaise * percentage / 100.0).floor();
      result[memberId] = Money.fromPaise(memberAmountPaise);
      distributedPaise += memberAmountPaise;
    }
    
    // Distribute remainder using stable order
    final remainder = totalPaise - distributedPaise;
    for (int i = 0; i < remainder && i < sortedMemberIds.length; i++) {
      final memberId = sortedMemberIds[i];
      final currentAmount = result[memberId]!;
      result[memberId] = Money.fromPaise(currentAmount.paise + 1);
    }
    
    return result;
  }

  /// Validate exact split amounts
  static bool validateExactSplit(
    Money totalAmount,
    Map<String, Money> memberAmounts,
  ) {
    if (memberAmounts.isEmpty) return false;
    
    final sumPaise = memberAmounts.values
        .fold(0, (sum, amount) => sum + amount.paise);
    
    return sumPaise == totalAmount.paise;
  }

  /// Calculate exact split (validation only, amounts provided by user)
  static Map<String, Money> calculateExactSplit(
    Money totalAmount,
    Map<String, Money> memberAmounts,
  ) {
    if (!validateExactSplit(totalAmount, memberAmounts)) {
      final actualTotal = Money.fromPaise(
        memberAmounts.values.fold(0, (sum, amount) => sum + amount.paise),
      );
      throw ArgumentError(
        'Exact split amounts (${actualTotal.toDisplayString()}) '
        'do not equal total amount (${totalAmount.toDisplayString()})',
      );
    }
    
    return Map<String, Money>.from(memberAmounts);
  }
}

/// Settlement optimization algorithms
class SettlementCalculator {
  SettlementCalculator._();

  /// Calculate who should pay whom to settle all debts
  /// Returns list of transfers that bring all balances to zero
  static List<Settlement> calculateOptimalSettlements(
    Map<String, Money> memberBalances,
  ) {
    if (memberBalances.isEmpty) return [];

    // Separate creditors (positive balance) and debtors (negative balance)
    final creditors = <String, int>{};
    final debtors = <String, int>{};
    
    for (final entry in memberBalances.entries) {
      final balancePaise = entry.value.paise;
      if (balancePaise > 0) {
        creditors[entry.key] = balancePaise;
      } else if (balancePaise < 0) {
        debtors[entry.key] = -balancePaise; // Store as positive amount
      }
    }
    
    final settlements = <Settlement>[];
    
    // Greedy algorithm: match largest creditor with largest debtor
    while (creditors.isNotEmpty && debtors.isNotEmpty) {
      // Find largest creditor and debtor
      final maxCreditor = creditors.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      final maxDebtor = debtors.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      
      // Calculate settlement amount
      final settlementAmount = min(maxCreditor.value, maxDebtor.value);
      
      settlements.add(Settlement(
        fromMemberId: maxDebtor.key,
        toMemberId: maxCreditor.key,
        amount: Money.fromPaise(settlementAmount),
      ));
      
      // Update balances
      creditors[maxCreditor.key] = maxCreditor.value - settlementAmount;
      debtors[maxDebtor.key] = maxDebtor.value - settlementAmount;
      
      // Remove members with zero balance
      if (creditors[maxCreditor.key] == 0) {
        creditors.remove(maxCreditor.key);
      }
      if (debtors[maxDebtor.key] == 0) {
        debtors.remove(maxDebtor.key);
      }
    }
    
    return settlements;
  }
}

/// Settlement transfer representation
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
  String toString() {
    return 'Settlement(from: $fromMemberId, to: $toMemberId, amount: ${amount.toDisplayString()})';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Settlement &&
        other.fromMemberId == fromMemberId &&
        other.toMemberId == toMemberId &&
        other.amount == amount;
  }
  
  @override
  int get hashCode {
    return Object.hash(fromMemberId, toMemberId, amount);
  }
}

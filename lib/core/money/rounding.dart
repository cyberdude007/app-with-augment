import 'money.dart';

/// Utilities for deterministic rounding when splitting money
class MoneyRounding {
  MoneyRounding._();

  /// Split money equally among participants with deterministic remainder distribution
  /// 
  /// Uses stable sorting by participant ID to ensure consistent results.
  /// Remainder paise are distributed to the first N participants in sorted order.
  /// 
  /// Example: ₹100 split among 3 participants with IDs ['c', 'a', 'b']
  /// - Base amount: ₹33.33 each (3333 paise)
  /// - Remainder: 1 paise
  /// - Sorted IDs: ['a', 'b', 'c']
  /// - Result: a=3334 paise, b=3333 paise, c=3333 paise
  static Map<String, Money> splitEqually(
    Money totalAmount,
    List<String> participantIds,
  ) {
    if (participantIds.isEmpty) {
      throw ArgumentError('Cannot split among zero participants');
    }

    final participantCount = participantIds.length;
    final baseAmountPaise = totalAmount.paise ~/ participantCount;
    final remainderPaise = totalAmount.paise % participantCount;

    // Sort participant IDs for deterministic ordering
    final sortedIds = List<String>.from(participantIds)..sort();

    final result = <String, Money>{};

    for (int i = 0; i < sortedIds.length; i++) {
      final participantId = sortedIds[i];
      final extraPaise = i < remainderPaise ? 1 : 0;
      final totalPaise = baseAmountPaise + extraPaise;
      result[participantId] = Money.fromPaise(totalPaise);
    }

    return result;
  }

  /// Split money by exact amounts
  /// 
  /// Validates that the sum of shares equals the total amount.
  static Map<String, Money> splitExact(
    Money totalAmount,
    Map<String, Money> shares,
  ) {
    if (shares.isEmpty) {
      throw ArgumentError('Cannot split with no shares specified');
    }

    final totalShares = shares.values.sum();
    if (totalShares != totalAmount) {
      throw ArgumentError(
        'Sum of shares (${totalShares.format()}) does not equal total amount (${totalAmount.format()})',
      );
    }

    return Map<String, Money>.from(shares);
  }

  /// Split money by percentages with deterministic remainder distribution
  /// 
  /// Percentages should sum to 100.0, but small floating point errors are tolerated.
  /// Remainder paise are distributed using the same stable ordering as equal splits.
  static Map<String, Money> splitByPercentage(
    Money totalAmount,
    Map<String, double> percentages,
  ) {
    if (percentages.isEmpty) {
      throw ArgumentError('Cannot split with no percentages specified');
    }

    final totalPercentage = percentages.values.fold(0.0, (sum, pct) => sum + pct);
    if ((totalPercentage - 100.0).abs() > 0.01) {
      throw ArgumentError(
        'Percentages must sum to 100.0, got $totalPercentage',
      );
    }

    // Calculate base amounts (floor of percentage * total)
    final baseAmounts = <String, int>{};
    int totalAllocatedPaise = 0;

    for (final entry in percentages.entries) {
      final participantId = entry.key;
      final percentage = entry.value;
      final amountPaise = (totalAmount.paise * percentage / 100.0).floor();
      baseAmounts[participantId] = amountPaise;
      totalAllocatedPaise += amountPaise;
    }

    // Calculate remainder and distribute deterministically
    final remainderPaise = totalAmount.paise - totalAllocatedPaise;
    final sortedIds = baseAmounts.keys.toList()..sort();

    final result = <String, Money>{};
    for (int i = 0; i < sortedIds.length; i++) {
      final participantId = sortedIds[i];
      final baseAmount = baseAmounts[participantId]!;
      final extraPaise = i < remainderPaise ? 1 : 0;
      result[participantId] = Money.fromPaise(baseAmount + extraPaise);
    }

    return result;
  }

  /// Validate that split results sum to the original amount
  static bool validateSplit(Money originalAmount, Map<String, Money> splits) {
    final totalSplit = splits.values.sum();
    return totalSplit == originalAmount;
  }

  /// Get the largest remainder when splitting equally
  /// Used for testing and validation
  static int getMaxRemainderForEqualSplit(int totalPaise, int participantCount) {
    return totalPaise % participantCount;
  }

  /// Calculate how many participants get an extra paise in equal split
  static int getParticipantsWithExtraPaise(int totalPaise, int participantCount) {
    return totalPaise % participantCount;
  }

  /// Round money to nearest paise (no-op since we already store in paise)
  static Money roundToPaise(Money amount) => amount;

  /// Round money to nearest rupee
  static Money roundToRupee(Money amount) {
    final roundedRupees = amount.rupees.round();
    return Money.fromRupees(roundedRupees.toDouble());
  }

  /// Round money up to nearest rupee
  static Money ceilToRupee(Money amount) {
    final ceiledRupees = amount.rupees.ceil();
    return Money.fromRupees(ceiledRupees.toDouble());
  }

  /// Round money down to nearest rupee
  static Money floorToRupee(Money amount) {
    final flooredRupees = amount.rupees.floor();
    return Money.fromRupees(flooredRupees.toDouble());
  }
}

/// Split method enumeration
enum SplitMethod {
  equally('Equally'),
  exact('Exact Amounts'),
  percentage('By Percentage');

  const SplitMethod(this.displayName);

  final String displayName;

  /// Get split method from string
  static SplitMethod fromString(String value) {
    return SplitMethod.values.firstWhere(
      (method) => method.name == value,
      orElse: () => SplitMethod.equally,
    );
  }
}

/// Result of a money split operation
class SplitResult {
  final Map<String, Money> shares;
  final SplitMethod method;
  final Money totalAmount;

  const SplitResult({
    required this.shares,
    required this.method,
    required this.totalAmount,
  });

  /// Validate that the split is correct
  bool get isValid => MoneyRounding.validateSplit(totalAmount, shares);

  /// Get list of participant IDs
  List<String> get participantIds => shares.keys.toList();

  /// Get share for a specific participant
  Money getShare(String participantId) =>
      shares[participantId] ?? Money.zero;

  /// Check if participant is included in the split
  bool hasParticipant(String participantId) => shares.containsKey(participantId);

  /// Get total number of participants
  int get participantCount => shares.length;

  /// Convert to JSON representation
  Map<String, dynamic> toJson() => {
        'shares': shares.map((id, money) => MapEntry(id, money.toJson())),
        'method': method.name,
        'totalAmount': totalAmount.toJson(),
      };

  /// Create SplitResult from JSON representation
  static SplitResult fromJson(Map<String, dynamic> json) {
    final sharesJson = json['shares'] as Map<String, dynamic>;
    final shares = sharesJson.map(
      (id, moneyJson) => MapEntry(id, Money.fromJson(moneyJson)),
    );

    return SplitResult(
      shares: shares,
      method: SplitMethod.fromString(json['method'] as String),
      totalAmount: Money.fromJson(json['totalAmount']),
    );
  }

  @override
  String toString() => 'SplitResult(${shares.length} participants, ${totalAmount.format()})';
}

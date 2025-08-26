/// Expense type enumeration
enum ExpenseType {
  split('SPLIT'),
  individual('INDIVIDUAL');

  const ExpenseType(this.value);
  
  final String value;

  /// Create ExpenseType from string value
  static ExpenseType fromString(String value) {
    return switch (value.toUpperCase()) {
      'SPLIT' => ExpenseType.split,
      'INDIVIDUAL' => ExpenseType.individual,
      _ => throw ArgumentError('Invalid expense type: $value'),
    };
  }

  /// Display name for UI
  String get displayName => switch (this) {
    ExpenseType.split => 'Split',
    ExpenseType.individual => 'Individual',
  };

  /// Description for UI
  String get description => switch (this) {
    ExpenseType.split => 'Share with group members',
    ExpenseType.individual => 'Record only in your ledger',
  };

  /// Icon for UI
  String get icon => switch (this) {
    ExpenseType.split => '👥',
    ExpenseType.individual => '👤',
  };
}

/// Split method for split expenses
enum SplitMethod {
  equally('EQUALLY'),
  exact('EXACT'),
  percentage('PERCENTAGE');

  const SplitMethod(this.value);
  
  final String value;

  /// Create SplitMethod from string value
  static SplitMethod fromString(String value) {
    return switch (value.toUpperCase()) {
      'EQUALLY' => SplitMethod.equally,
      'EXACT' => SplitMethod.exact,
      'PERCENTAGE' => SplitMethod.percentage,
      _ => throw ArgumentError('Invalid split method: $value'),
    };
  }

  /// Display name for UI
  String get displayName => switch (this) {
    SplitMethod.equally => 'Equally',
    SplitMethod.exact => 'Exact',
    SplitMethod.percentage => 'Percentage',
  };

  /// Description for UI
  String get description => switch (this) {
    SplitMethod.equally => 'Split amount equally among members',
    SplitMethod.exact => 'Enter exact amounts for each member',
    SplitMethod.percentage => 'Split by percentage for each member',
  };

  /// Icon for UI
  String get icon => switch (this) {
    SplitMethod.equally => '⚖️',
    SplitMethod.exact => '💰',
    SplitMethod.percentage => '📊',
  };
}

/// Expense form state
class ExpenseFormState {
  final ExpenseType type;
  final String description;
  final String amount;
  final String payerId;
  final DateTime date;
  final String category;
  final String notes;
  final String? groupId;
  final SplitMethod splitMethod;
  final Map<String, String> splitAmounts; // memberId -> amount string
  final Map<String, String> splitPercentages; // memberId -> percentage string

  const ExpenseFormState({
    this.type = ExpenseType.split,
    this.description = '',
    this.amount = '',
    this.payerId = '',
    DateTime? date,
    this.category = '',
    this.notes = '',
    this.groupId,
    this.splitMethod = SplitMethod.equally,
    this.splitAmounts = const {},
    this.splitPercentages = const {},
  }) : date = date ?? const ExpenseFormState._defaultDate();

  const ExpenseFormState._defaultDate() : date = null;

  /// Create a copy with updated fields
  ExpenseFormState copyWith({
    ExpenseType? type,
    String? description,
    String? amount,
    String? payerId,
    DateTime? date,
    String? category,
    String? notes,
    String? groupId,
    SplitMethod? splitMethod,
    Map<String, String>? splitAmounts,
    Map<String, String>? splitPercentages,
  }) {
    return ExpenseFormState(
      type: type ?? this.type,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      payerId: payerId ?? this.payerId,
      date: date ?? this.date ?? DateTime.now(),
      category: category ?? this.category,
      notes: notes ?? this.notes,
      groupId: groupId ?? this.groupId,
      splitMethod: splitMethod ?? this.splitMethod,
      splitAmounts: splitAmounts ?? this.splitAmounts,
      splitPercentages: splitPercentages ?? this.splitPercentages,
    );
  }

  /// Check if form is valid for submission
  bool get isValid {
    // Common validations
    if (description.trim().isEmpty) return false;
    if (amount.trim().isEmpty) return false;
    if (double.tryParse(amount) == null || double.parse(amount) <= 0) return false;
    if (payerId.isEmpty) return false;
    if (category.trim().isEmpty) return false;

    // Split-specific validations
    if (type == ExpenseType.split) {
      if (groupId == null || groupId!.isEmpty) return false;
      
      switch (splitMethod) {
        case SplitMethod.equally:
          // No additional validation needed
          break;
        case SplitMethod.exact:
          // Check that all split amounts are valid and sum to total
          if (splitAmounts.isEmpty) return false;
          double totalSplit = 0;
          for (final amountStr in splitAmounts.values) {
            final splitAmount = double.tryParse(amountStr);
            if (splitAmount == null || splitAmount < 0) return false;
            totalSplit += splitAmount;
          }
          final totalAmount = double.parse(amount);
          if ((totalSplit - totalAmount).abs() > 0.01) return false;
          break;
        case SplitMethod.percentage:
          // Check that all percentages are valid and sum to 100
          if (splitPercentages.isEmpty) return false;
          double totalPercentage = 0;
          for (final percentageStr in splitPercentages.values) {
            final percentage = double.tryParse(percentageStr);
            if (percentage == null || percentage < 0 || percentage > 100) return false;
            totalPercentage += percentage;
          }
          if ((totalPercentage - 100.0).abs() > 0.01) return false;
          break;
      }
    }

    return true;
  }

  /// Get validation errors
  List<String> get validationErrors {
    final errors = <String>[];

    // Common validations
    if (description.trim().isEmpty) {
      errors.add('Description is required');
    }
    if (amount.trim().isEmpty) {
      errors.add('Amount is required');
    } else {
      final parsedAmount = double.tryParse(amount);
      if (parsedAmount == null) {
        errors.add('Amount must be a valid number');
      } else if (parsedAmount <= 0) {
        errors.add('Amount must be greater than zero');
      }
    }
    if (payerId.isEmpty) {
      errors.add('Payer is required');
    }
    if (category.trim().isEmpty) {
      errors.add('Category is required');
    }

    // Split-specific validations
    if (type == ExpenseType.split) {
      if (groupId == null || groupId!.isEmpty) {
        errors.add('Group is required for split expenses');
      }
      
      switch (splitMethod) {
        case SplitMethod.equally:
          // No additional validation needed
          break;
        case SplitMethod.exact:
          if (splitAmounts.isEmpty) {
            errors.add('Split amounts are required');
          } else {
            double totalSplit = 0;
            bool hasInvalidAmount = false;
            for (final entry in splitAmounts.entries) {
              final splitAmount = double.tryParse(entry.value);
              if (splitAmount == null || splitAmount < 0) {
                errors.add('Invalid split amount for member ${entry.key}');
                hasInvalidAmount = true;
              } else {
                totalSplit += splitAmount;
              }
            }
            if (!hasInvalidAmount && amount.isNotEmpty) {
              final totalAmount = double.tryParse(amount);
              if (totalAmount != null && (totalSplit - totalAmount).abs() > 0.01) {
                errors.add('Split amounts must equal total amount');
              }
            }
          }
          break;
        case SplitMethod.percentage:
          if (splitPercentages.isEmpty) {
            errors.add('Split percentages are required');
          } else {
            double totalPercentage = 0;
            bool hasInvalidPercentage = false;
            for (final entry in splitPercentages.entries) {
              final percentage = double.tryParse(entry.value);
              if (percentage == null || percentage < 0 || percentage > 100) {
                errors.add('Invalid percentage for member ${entry.key}');
                hasInvalidPercentage = true;
              } else {
                totalPercentage += percentage;
              }
            }
            if (!hasInvalidPercentage && (totalPercentage - 100.0).abs() > 0.01) {
              errors.add('Percentages must sum to 100%');
            }
          }
          break;
      }
    }

    return errors;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseFormState &&
        other.type == type &&
        other.description == description &&
        other.amount == amount &&
        other.payerId == payerId &&
        other.date == date &&
        other.category == category &&
        other.notes == notes &&
        other.groupId == groupId &&
        other.splitMethod == splitMethod &&
        _mapEquals(other.splitAmounts, splitAmounts) &&
        _mapEquals(other.splitPercentages, splitPercentages);
  }

  @override
  int get hashCode {
    return Object.hash(
      type,
      description,
      amount,
      payerId,
      date,
      category,
      notes,
      groupId,
      splitMethod,
      splitAmounts,
      splitPercentages,
    );
  }

  bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}

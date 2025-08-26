import 'package:intl/intl.dart';

/// Money class that stores amounts in paise (smallest currency unit)
/// All monetary calculations are done in paise to avoid floating point errors
class Money {
  /// Amount in paise (1 rupee = 100 paise)
  final int paise;

  const Money._(this.paise);

  /// Create Money from paise
  const Money.fromPaise(int paise) : paise = paise;

  /// Create Money from rupees (converts to paise)
  Money.fromRupees(double rupees) : paise = (rupees * 100).round();

  /// Create Money from string representation (e.g., "123.45")
  Money.fromString(String value) : paise = (double.parse(value) * 100).round();

  /// Zero money
  static const Money zero = Money._(0);

  /// Get amount in rupees as double
  double get rupees => paise / 100.0;

  /// Check if amount is zero
  bool get isZero => paise == 0;

  /// Check if amount is positive
  bool get isPositive => paise > 0;

  /// Check if amount is negative
  bool get isNegative => paise < 0;

  /// Get absolute value
  Money get abs => Money._(paise.abs());

  /// Negate the amount
  Money operator -() => Money._(-paise);

  /// Add two money amounts
  Money operator +(Money other) => Money._(paise + other.paise);

  /// Subtract two money amounts
  Money operator -(Money other) => Money._(paise - other.paise);

  /// Multiply by a factor
  Money operator *(double factor) => Money._((paise * factor).round());

  /// Divide by a factor
  Money operator /(double factor) => Money._((paise / factor).round());

  /// Compare money amounts
  bool operator >(Money other) => paise > other.paise;
  bool operator <(Money other) => paise < other.paise;
  bool operator >=(Money other) => paise >= other.paise;
  bool operator <=(Money other) => paise <= other.paise;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Money && paise == other.paise;

  @override
  int get hashCode => paise.hashCode;

  /// Compare to another Money (for sorting)
  int compareTo(Money other) => paise.compareTo(other.paise);

  /// Format as Indian currency with ₹ symbol
  String format({bool showSymbol = true, bool showDecimals = true}) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: showSymbol ? '₹' : '',
      decimalDigits: showDecimals ? 2 : 0,
    );
    return formatter.format(rupees);
  }

  /// Format as compact currency (e.g., ₹1.2K, ₹1.5L)
  String formatCompact({bool showSymbol = true}) {
    final formatter = NumberFormat.compactCurrency(
      locale: 'en_IN',
      symbol: showSymbol ? '₹' : '',
      decimalDigits: 1,
    );
    return formatter.format(rupees);
  }

  /// Format for display in lists (no decimals if whole number)
  String formatDisplay({bool showSymbol = true}) {
    if (paise % 100 == 0) {
      // Whole rupees, no decimals
      return format(showSymbol: showSymbol, showDecimals: false);
    } else {
      // Has paise, show decimals
      return format(showSymbol: showSymbol, showDecimals: true);
    }
  }

  /// Format as display string (alias for toString for spec compatibility)
  String toDisplayString() => formatDisplay();

  /// Format as plain number string (for input fields)
  String toPlainString() {
    if (paise % 100 == 0) {
      return (paise ~/ 100).toString();
    } else {
      return (paise / 100.0).toStringAsFixed(2);
    }
  }

  /// Create Money from user input string
  static Money? tryParse(String input) {
    if (input.isEmpty) return null;
    
    // Remove currency symbols and whitespace
    final cleaned = input
        .replaceAll('₹', '')
        .replaceAll(',', '')
        .trim();
    
    final parsed = double.tryParse(cleaned);
    if (parsed == null) return null;
    
    return Money.fromRupees(parsed);
  }

  /// Parse Money from user input string (throws on invalid input)
  static Money parse(String input) {
    final result = tryParse(input);
    if (result == null) {
      throw FormatException('Invalid money format: $input');
    }
    return result;
  }

  /// Sum a list of Money amounts
  static Money sum(Iterable<Money> amounts) {
    return amounts.fold(Money.zero, (sum, amount) => sum + amount);
  }

  /// Get the maximum of two Money amounts
  static Money max(Money a, Money b) => a > b ? a : b;

  /// Get the minimum of two Money amounts
  static Money min(Money a, Money b) => a < b ? a : b;

  @override
  String toString() => format();

  /// Convert to JSON representation
  Map<String, dynamic> toJson() => {'paise': paise};

  /// Create Money from JSON representation
  static Money fromJson(Map<String, dynamic> json) =>
      Money.fromPaise(json['paise'] as int);
}

/// Extension methods for working with Money
extension MoneyIterable on Iterable<Money> {
  /// Sum all money amounts in the iterable
  Money sum() => Money.sum(this);

  /// Get the maximum money amount
  Money? get maxOrNull => isEmpty ? null : reduce(Money.max);

  /// Get the minimum money amount
  Money? get minOrNull => isEmpty ? null : reduce(Money.min);
}

/// Extension methods for int to create Money
extension IntToMoney on int {
  /// Convert int to Money (treating as paise)
  Money get paise => Money.fromPaise(this);

  /// Convert int to Money (treating as rupees)
  Money get rupees => Money.fromRupees(toDouble());
}

/// Extension methods for double to create Money
extension DoubleToMoney on double {
  /// Convert double to Money (treating as rupees)
  Money get rupees => Money.fromRupees(this);
}

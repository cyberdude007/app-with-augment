import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_split/core/algorithms/split_calculator.dart';
import 'package:paisa_split/core/money/money.dart';

void main() {
  group('SplitCalculator', () {
    group('calculateEqualSplit', () {
      test('should split amount equally with no remainder', () {
        final amount = Money.fromRupees(100.0);
        final memberIds = ['alice', 'bob', 'charlie', 'diana'];
        
        final result = SplitCalculator.calculateEqualSplit(amount, memberIds);
        
        expect(result.length, equals(4));
        expect(result['alice'], equals(Money.fromRupees(25.0)));
        expect(result['bob'], equals(Money.fromRupees(25.0)));
        expect(result['charlie'], equals(Money.fromRupees(25.0)));
        expect(result['diana'], equals(Money.fromRupees(25.0)));
        
        // Verify total equals original amount
        final total = result.values.fold(Money.zero, (sum, amount) => sum + amount);
        expect(total, equals(amount));
      });

      test('should distribute remainder deterministically', () {
        final amount = Money.fromRupees(100.01); // 10001 paise
        final memberIds = ['charlie', 'alice', 'bob']; // Unsorted order
        
        final result = SplitCalculator.calculateEqualSplit(amount, memberIds);
        
        expect(result.length, equals(3));
        // After sorting: alice, bob, charlie
        // 10001 / 3 = 3333 remainder 2
        // alice and bob get +1 paise each
        expect(result['alice'], equals(Money.fromPaise(3334))); // 33.34
        expect(result['bob'], equals(Money.fromPaise(3334)));   // 33.34
        expect(result['charlie'], equals(Money.fromPaise(3333))); // 33.33
        
        // Verify total equals original amount
        final total = result.values.fold(Money.zero, (sum, amount) => sum + amount);
        expect(total, equals(amount));
      });

      test('should handle single member', () {
        final amount = Money.fromRupees(50.0);
        final memberIds = ['alice'];
        
        final result = SplitCalculator.calculateEqualSplit(amount, memberIds);
        
        expect(result.length, equals(1));
        expect(result['alice'], equals(amount));
      });

      test('should throw error for empty member list', () {
        final amount = Money.fromRupees(100.0);
        final memberIds = <String>[];
        
        expect(
          () => SplitCalculator.calculateEqualSplit(amount, memberIds),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should be deterministic with same input', () {
        final amount = Money.fromRupees(100.03);
        final memberIds = ['zulu', 'alpha', 'bravo'];
        
        final result1 = SplitCalculator.calculateEqualSplit(amount, memberIds);
        final result2 = SplitCalculator.calculateEqualSplit(amount, memberIds);
        
        expect(result1, equals(result2));
      });

      test('acceptance criteria: ₹500 for 5 members', () {
        final amount = Money.fromRupees(500.0);
        final memberIds = ['member1', 'member2', 'member3', 'member4', 'member5'];
        
        final result = SplitCalculator.calculateEqualSplit(amount, memberIds);
        
        expect(result.length, equals(5));
        // Each member should get exactly ₹100
        for (final memberId in memberIds) {
          expect(result[memberId], equals(Money.fromRupees(100.0)));
        }
        
        // Verify total
        final total = result.values.fold(Money.zero, (sum, amount) => sum + amount);
        expect(total, equals(amount));
      });
    });

    group('calculatePercentageSplit', () {
      test('should split by percentage correctly', () {
        final amount = Money.fromRupees(1000.0);
        final percentages = {
          'alice': 40.0,
          'bob': 35.0,
          'charlie': 25.0,
        };
        
        final result = SplitCalculator.calculatePercentageSplit(amount, percentages);
        
        expect(result.length, equals(3));
        expect(result['alice'], equals(Money.fromRupees(400.0)));
        expect(result['bob'], equals(Money.fromRupees(350.0)));
        expect(result['charlie'], equals(Money.fromRupees(250.0)));
        
        // Verify total
        final total = result.values.fold(Money.zero, (sum, amount) => sum + amount);
        expect(total, equals(amount));
      });

      test('should handle remainder distribution deterministically', () {
        final amount = Money.fromRupees(100.0); // 10000 paise
        final percentages = {
          'charlie': 33.33,
          'alice': 33.33,
          'bob': 33.34,
        };
        
        final result = SplitCalculator.calculatePercentageSplit(amount, percentages);
        
        // Floor amounts: alice=3333, bob=3334, charlie=3333
        // Remainder: 10000 - (3333+3334+3333) = 0
        expect(result['alice'], equals(Money.fromPaise(3333)));
        expect(result['bob'], equals(Money.fromPaise(3334)));
        expect(result['charlie'], equals(Money.fromPaise(3333)));
        
        // Verify total
        final total = result.values.fold(Money.zero, (sum, amount) => sum + amount);
        expect(total, equals(amount));
      });

      test('should throw error if percentages do not sum to 100', () {
        final amount = Money.fromRupees(100.0);
        final percentages = {
          'alice': 40.0,
          'bob': 35.0,
          'charlie': 20.0, // Total = 95%
        };
        
        expect(
          () => SplitCalculator.calculatePercentageSplit(amount, percentages),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw error for empty percentages', () {
        final amount = Money.fromRupees(100.0);
        final percentages = <String, double>{};
        
        expect(
          () => SplitCalculator.calculatePercentageSplit(amount, percentages),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle small remainder correctly', () {
        final amount = Money.fromRupees(100.01); // 10001 paise
        final percentages = {
          'alice': 33.33,
          'bob': 33.33,
          'charlie': 33.34,
        };
        
        final result = SplitCalculator.calculatePercentageSplit(amount, percentages);
        
        // Verify total equals original amount
        final total = result.values.fold(Money.zero, (sum, amount) => sum + amount);
        expect(total, equals(amount));
      });
    });

    group('validateExactSplit', () {
      test('should return true for valid exact split', () {
        final amount = Money.fromRupees(100.0);
        final splits = {
          'alice': Money.fromRupees(40.0),
          'bob': Money.fromRupees(35.0),
          'charlie': Money.fromRupees(25.0),
        };
        
        final result = SplitCalculator.validateExactSplit(amount, splits);
        
        expect(result, isTrue);
      });

      test('should return false for invalid exact split', () {
        final amount = Money.fromRupees(100.0);
        final splits = {
          'alice': Money.fromRupees(40.0),
          'bob': Money.fromRupees(35.0),
          'charlie': Money.fromRupees(20.0), // Total = 95
        };
        
        final result = SplitCalculator.validateExactSplit(amount, splits);
        
        expect(result, isFalse);
      });

      test('should return false for empty splits', () {
        final amount = Money.fromRupees(100.0);
        final splits = <String, Money>{};
        
        final result = SplitCalculator.validateExactSplit(amount, splits);
        
        expect(result, isFalse);
      });
    });

    group('calculateExactSplit', () {
      test('should return splits for valid exact split', () {
        final amount = Money.fromRupees(100.0);
        final splits = {
          'alice': Money.fromRupees(40.0),
          'bob': Money.fromRupees(35.0),
          'charlie': Money.fromRupees(25.0),
        };
        
        final result = SplitCalculator.calculateExactSplit(amount, splits);
        
        expect(result, equals(splits));
      });

      test('should throw error for invalid exact split', () {
        final amount = Money.fromRupees(100.0);
        final splits = {
          'alice': Money.fromRupees(40.0),
          'bob': Money.fromRupees(35.0),
          'charlie': Money.fromRupees(20.0), // Total = 95
        };
        
        expect(
          () => SplitCalculator.calculateExactSplit(amount, splits),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}

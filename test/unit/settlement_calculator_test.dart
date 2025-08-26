import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_split/core/algorithms/split_calculator.dart';
import 'package:paisa_split/core/money/money.dart';

void main() {
  group('SettlementCalculator', () {
    group('calculateOptimalSettlements', () {
      test('should return empty list for empty balances', () {
        final balances = <String, Money>{};
        
        final result = SettlementCalculator.calculateOptimalSettlements(balances);
        
        expect(result, isEmpty);
      });

      test('should return empty list for zero balances', () {
        final balances = {
          'alice': Money.zero,
          'bob': Money.zero,
          'charlie': Money.zero,
        };
        
        final result = SettlementCalculator.calculateOptimalSettlements(balances);
        
        expect(result, isEmpty);
      });

      test('should handle simple two-person settlement', () {
        final balances = {
          'alice': Money.fromRupees(100.0),  // Alice is owed ₹100
          'bob': Money.fromRupees(-100.0),   // Bob owes ₹100
        };
        
        final result = SettlementCalculator.calculateOptimalSettlements(balances);
        
        expect(result.length, equals(1));
        expect(result[0].fromMemberId, equals('bob'));
        expect(result[0].toMemberId, equals('alice'));
        expect(result[0].amount, equals(Money.fromRupees(100.0)));
      });

      test('should optimize multiple settlements', () {
        final balances = {
          'alice': Money.fromRupees(150.0),   // Alice is owed ₹150
          'bob': Money.fromRupees(-50.0),     // Bob owes ₹50
          'charlie': Money.fromRupees(-100.0), // Charlie owes ₹100
        };
        
        final result = SettlementCalculator.calculateOptimalSettlements(balances);
        
        expect(result.length, equals(2));
        
        // Verify all debts are settled
        final totalSettled = result.fold(Money.zero, (sum, settlement) => sum + settlement.amount);
        expect(totalSettled, equals(Money.fromRupees(150.0)));
        
        // Verify settlements are from debtors to creditors
        for (final settlement in result) {
          expect(balances[settlement.fromMemberId]!.isNegative, isTrue);
          expect(balances[settlement.toMemberId]!.isPositive, isTrue);
        }
      });

      test('should handle complex multi-person scenario', () {
        final balances = {
          'alice': Money.fromRupees(200.0),   // Alice is owed ₹200
          'bob': Money.fromRupees(100.0),     // Bob is owed ₹100
          'charlie': Money.fromRupees(-150.0), // Charlie owes ₹150
          'diana': Money.fromRupees(-150.0),   // Diana owes ₹150
        };
        
        final result = SettlementCalculator.calculateOptimalSettlements(balances);
        
        // Should minimize number of transactions
        expect(result.length, lessThanOrEqualTo(3));
        
        // Verify total amount settled equals total debt
        final totalSettled = result.fold(Money.zero, (sum, settlement) => sum + settlement.amount);
        expect(totalSettled, equals(Money.fromRupees(300.0)));
        
        // Verify all settlements are valid
        for (final settlement in result) {
          expect(settlement.amount.isPositive, isTrue);
          expect(balances[settlement.fromMemberId]!.isNegative, isTrue);
          expect(balances[settlement.toMemberId]!.isPositive, isTrue);
        }
      });

      test('should bring all balances to zero', () {
        final balances = {
          'alice': Money.fromRupees(75.0),
          'bob': Money.fromRupees(25.0),
          'charlie': Money.fromRupees(-50.0),
          'diana': Money.fromRupees(-50.0),
        };
        
        final result = SettlementCalculator.calculateOptimalSettlements(balances);
        
        // Apply settlements to balances
        final finalBalances = Map<String, Money>.from(balances);
        for (final settlement in result) {
          finalBalances[settlement.fromMemberId] = 
              finalBalances[settlement.fromMemberId]! + settlement.amount;
          finalBalances[settlement.toMemberId] = 
              finalBalances[settlement.toMemberId]! - settlement.amount;
        }
        
        // All balances should be zero (or very close due to rounding)
        for (final balance in finalBalances.values) {
          expect(balance.paise.abs(), lessThanOrEqualTo(1)); // Within 1 paise
        }
      });

      test('should handle single creditor multiple debtors', () {
        final balances = {
          'alice': Money.fromRupees(300.0),   // Alice is owed ₹300
          'bob': Money.fromRupees(-100.0),    // Bob owes ₹100
          'charlie': Money.fromRupees(-100.0), // Charlie owes ₹100
          'diana': Money.fromRupees(-100.0),   // Diana owes ₹100
        };
        
        final result = SettlementCalculator.calculateOptimalSettlements(balances);
        
        expect(result.length, equals(3));
        
        // All settlements should be to Alice
        for (final settlement in result) {
          expect(settlement.toMemberId, equals('alice'));
          expect(settlement.amount, equals(Money.fromRupees(100.0)));
        }
      });

      test('should handle single debtor multiple creditors', () {
        final balances = {
          'alice': Money.fromRupees(100.0),   // Alice is owed ₹100
          'bob': Money.fromRupees(100.0),     // Bob is owed ₹100
          'charlie': Money.fromRupees(100.0), // Charlie is owed ₹100
          'diana': Money.fromRupees(-300.0),   // Diana owes ₹300
        };
        
        final result = SettlementCalculator.calculateOptimalSettlements(balances);
        
        expect(result.length, equals(3));
        
        // All settlements should be from Diana
        for (final settlement in result) {
          expect(settlement.fromMemberId, equals('diana'));
          expect(settlement.amount, equals(Money.fromRupees(100.0)));
        }
      });

      test('should use greedy algorithm (largest amounts first)', () {
        final balances = {
          'alice': Money.fromRupees(200.0),   // Largest creditor
          'bob': Money.fromRupees(50.0),      // Smaller creditor
          'charlie': Money.fromRupees(-150.0), // Largest debtor
          'diana': Money.fromRupees(-100.0),   // Smaller debtor
        };
        
        final result = SettlementCalculator.calculateOptimalSettlements(balances);
        
        // First settlement should be between largest creditor and largest debtor
        final firstSettlement = result.first;
        expect(firstSettlement.toMemberId, equals('alice'));
        expect(firstSettlement.fromMemberId, equals('charlie'));
        expect(firstSettlement.amount, equals(Money.fromRupees(150.0)));
      });

      test('acceptance criteria: suggested transfers bring all nets to zero', () {
        // Example scenario from spec
        final balances = {
          'alice': Money.fromRupees(100.0),   // Alice is owed ₹100
          'bob': Money.fromRupees(-50.0),     // Bob owes ₹50
          'charlie': Money.fromRupees(-50.0), // Charlie owes ₹50
        };
        
        final result = SettlementCalculator.calculateOptimalSettlements(balances);
        
        // Apply settlements to verify all balances become zero
        final finalBalances = Map<String, Money>.from(balances);
        for (final settlement in result) {
          finalBalances[settlement.fromMemberId] = 
              finalBalances[settlement.fromMemberId]! + settlement.amount;
          finalBalances[settlement.toMemberId] = 
              finalBalances[settlement.toMemberId]! - settlement.amount;
        }
        
        // All final balances should be zero
        for (final balance in finalBalances.values) {
          expect(balance, equals(Money.zero));
        }
      });

      test('should handle fractional amounts correctly', () {
        final balances = {
          'alice': Money.fromRupees(33.33),
          'bob': Money.fromRupees(33.33),
          'charlie': Money.fromRupees(-66.66),
        };
        
        final result = SettlementCalculator.calculateOptimalSettlements(balances);
        
        // Verify total settlement amount
        final totalSettled = result.fold(Money.zero, (sum, settlement) => sum + settlement.amount);
        expect(totalSettled, equals(Money.fromRupees(66.66)));
      });
    });
  });

  group('Settlement', () {
    test('should create settlement correctly', () {
      final settlement = Settlement(
        fromMemberId: 'alice',
        toMemberId: 'bob',
        amount: Money.fromRupees(100.0),
      );
      
      expect(settlement.fromMemberId, equals('alice'));
      expect(settlement.toMemberId, equals('bob'));
      expect(settlement.amount, equals(Money.fromRupees(100.0)));
    });

    test('should implement equality correctly', () {
      final settlement1 = Settlement(
        fromMemberId: 'alice',
        toMemberId: 'bob',
        amount: Money.fromRupees(100.0),
      );
      
      final settlement2 = Settlement(
        fromMemberId: 'alice',
        toMemberId: 'bob',
        amount: Money.fromRupees(100.0),
      );
      
      final settlement3 = Settlement(
        fromMemberId: 'alice',
        toMemberId: 'bob',
        amount: Money.fromRupees(50.0),
      );
      
      expect(settlement1, equals(settlement2));
      expect(settlement1, isNot(equals(settlement3)));
    });

    test('should have proper toString representation', () {
      final settlement = Settlement(
        fromMemberId: 'alice',
        toMemberId: 'bob',
        amount: Money.fromRupees(100.0),
      );
      
      final string = settlement.toString();
      expect(string, contains('alice'));
      expect(string, contains('bob'));
      expect(string, contains('₹100'));
    });
  });
}

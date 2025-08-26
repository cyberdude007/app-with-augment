import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_split/core/money/money.dart';

void main() {
  group('Money', () {
    group('construction', () {
      test('should create from paise correctly', () {
        final money = Money.fromPaise(12345);
        expect(money.paise, equals(12345));
        expect(money.rupees, equals(123.45));
      });

      test('should create from rupees correctly', () {
        final money = Money.fromRupees(123.45);
        expect(money.paise, equals(12345));
        expect(money.rupees, equals(123.45));
      });

      test('should create from string correctly', () {
        final money = Money.fromString('123.45');
        expect(money.paise, equals(12345));
        expect(money.rupees, equals(123.45));
      });

      test('should handle zero correctly', () {
        expect(Money.zero.paise, equals(0));
        expect(Money.zero.rupees, equals(0.0));
        expect(Money.zero.isZero, isTrue);
      });
    });

    group('properties', () {
      test('should identify positive amounts', () {
        final money = Money.fromRupees(100.0);
        expect(money.isPositive, isTrue);
        expect(money.isNegative, isFalse);
        expect(money.isZero, isFalse);
      });

      test('should identify negative amounts', () {
        final money = Money.fromRupees(-100.0);
        expect(money.isPositive, isFalse);
        expect(money.isNegative, isTrue);
        expect(money.isZero, isFalse);
      });

      test('should calculate absolute value', () {
        final negative = Money.fromRupees(-100.0);
        final positive = negative.abs;
        expect(positive.paise, equals(10000));
        expect(positive.isPositive, isTrue);
      });
    });

    group('arithmetic operations', () {
      test('should add correctly', () {
        final a = Money.fromRupees(100.0);
        final b = Money.fromRupees(50.0);
        final result = a + b;
        expect(result, equals(Money.fromRupees(150.0)));
      });

      test('should subtract correctly', () {
        final a = Money.fromRupees(100.0);
        final b = Money.fromRupees(30.0);
        final result = a - b;
        expect(result, equals(Money.fromRupees(70.0)));
      });

      test('should multiply correctly', () {
        final money = Money.fromRupees(100.0);
        final result = money * 1.5;
        expect(result, equals(Money.fromRupees(150.0)));
      });

      test('should divide correctly', () {
        final money = Money.fromRupees(100.0);
        final result = money / 2.0;
        expect(result, equals(Money.fromRupees(50.0)));
      });

      test('should negate correctly', () {
        final money = Money.fromRupees(100.0);
        final result = -money;
        expect(result, equals(Money.fromRupees(-100.0)));
      });
    });

    group('comparison operations', () {
      test('should compare correctly', () {
        final a = Money.fromRupees(100.0);
        final b = Money.fromRupees(50.0);
        final c = Money.fromRupees(100.0);

        expect(a > b, isTrue);
        expect(b < a, isTrue);
        expect(a >= c, isTrue);
        expect(a <= c, isTrue);
        expect(a == c, isTrue);
        expect(a != b, isTrue);
      });

      test('should implement compareTo correctly', () {
        final a = Money.fromRupees(100.0);
        final b = Money.fromRupees(50.0);
        final c = Money.fromRupees(100.0);

        expect(a.compareTo(b), greaterThan(0));
        expect(b.compareTo(a), lessThan(0));
        expect(a.compareTo(c), equals(0));
      });
    });

    group('Indian rupee formatting', () {
      test('should format basic amounts correctly', () {
        final money = Money.fromRupees(1234.56);
        expect(money.format(), equals('₹1,234.56'));
      });

      test('should format large amounts with Indian grouping', () {
        final money = Money.fromRupees(1234567.89);
        // Indian number system: 12,34,567.89
        expect(money.format(), equals('₹12,34,567.89'));
      });

      test('should format crores correctly', () {
        final money = Money.fromRupees(12345678.90);
        // 1,23,45,678.90
        expect(money.format(), equals('₹1,23,45,678.90'));
      });

      test('should format without symbol when requested', () {
        final money = Money.fromRupees(1234.56);
        expect(money.format(showSymbol: false), equals('1,234.56'));
      });

      test('should format without decimals when requested', () {
        final money = Money.fromRupees(1234.56);
        expect(money.format(showDecimals: false), equals('₹1,235')); // Rounded
      });

      test('should format compact amounts', () {
        final money = Money.fromRupees(1500000.0);
        expect(money.formatCompact(), equals('₹15L')); // 15 Lakh
      });

      test('should format display amounts intelligently', () {
        final wholeAmount = Money.fromRupees(1000.0);
        expect(wholeAmount.formatDisplay(), equals('₹1,000'));

        final fractionalAmount = Money.fromRupees(1000.50);
        expect(fractionalAmount.formatDisplay(), equals('₹1,000.50'));
      });

      test('should format as plain string for input', () {
        final wholeAmount = Money.fromRupees(1000.0);
        expect(wholeAmount.toPlainString(), equals('1000'));

        final fractionalAmount = Money.fromRupees(1000.50);
        expect(fractionalAmount.toPlainString(), equals('1000.50'));
      });

      test('should implement toDisplayString for spec compatibility', () {
        final money = Money.fromRupees(1234.56);
        expect(money.toDisplayString(), equals('₹1,234.56'));
      });
    });

    group('parsing', () {
      test('should parse valid input strings', () {
        expect(Money.tryParse('123.45'), equals(Money.fromRupees(123.45)));
        expect(Money.tryParse('₹123.45'), equals(Money.fromRupees(123.45)));
        expect(Money.tryParse('1,234.56'), equals(Money.fromRupees(1234.56)));
        expect(Money.tryParse(' 123.45 '), equals(Money.fromRupees(123.45)));
      });

      test('should return null for invalid input', () {
        expect(Money.tryParse(''), isNull);
        expect(Money.tryParse('abc'), isNull);
        expect(Money.tryParse('12.34.56'), isNull);
      });

      test('should throw for invalid input with parse', () {
        expect(() => Money.parse('abc'), throwsA(isA<FormatException>()));
      });

      test('should parse successfully with parse', () {
        final money = Money.parse('123.45');
        expect(money, equals(Money.fromRupees(123.45)));
      });
    });

    group('utility methods', () {
      test('should sum amounts correctly', () {
        final amounts = [
          Money.fromRupees(100.0),
          Money.fromRupees(200.0),
          Money.fromRupees(300.0),
        ];
        
        final sum = Money.sum(amounts);
        expect(sum, equals(Money.fromRupees(600.0)));
      });

      test('should find maximum correctly', () {
        final a = Money.fromRupees(100.0);
        final b = Money.fromRupees(200.0);
        
        expect(Money.max(a, b), equals(b));
        expect(Money.max(b, a), equals(b));
      });

      test('should find minimum correctly', () {
        final a = Money.fromRupees(100.0);
        final b = Money.fromRupees(200.0);
        
        expect(Money.min(a, b), equals(a));
        expect(Money.min(b, a), equals(a));
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        final money = Money.fromRupees(123.45);
        final json = money.toJson();
        
        expect(json, equals({'paise': 12345}));
      });

      test('should deserialize from JSON correctly', () {
        final json = {'paise': 12345};
        final money = Money.fromJson(json);
        
        expect(money, equals(Money.fromRupees(123.45)));
      });
    });

    group('extension methods', () {
      test('should work with MoneyIterable extension', () {
        final amounts = [
          Money.fromRupees(100.0),
          Money.fromRupees(200.0),
          Money.fromRupees(50.0),
        ];
        
        expect(amounts.sum(), equals(Money.fromRupees(350.0)));
        expect(amounts.maxOrNull, equals(Money.fromRupees(200.0)));
        expect(amounts.minOrNull, equals(Money.fromRupees(50.0)));
      });

      test('should handle empty iterable', () {
        final amounts = <Money>[];
        
        expect(amounts.sum(), equals(Money.zero));
        expect(amounts.maxOrNull, isNull);
        expect(amounts.minOrNull, isNull);
      });

      test('should work with IntToMoney extension', () {
        expect(12345.paise, equals(Money.fromPaise(12345)));
        expect(123.rupees, equals(Money.fromRupees(123.0)));
      });

      test('should work with DoubleToMoney extension', () {
        expect(123.45.rupees, equals(Money.fromRupees(123.45)));
      });
    });

    group('edge cases', () {
      test('should handle very large amounts', () {
        final money = Money.fromRupees(999999999.99);
        expect(money.paise, equals(99999999999));
        expect(money.format(), contains('₹'));
      });

      test('should handle very small amounts', () {
        final money = Money.fromPaise(1);
        expect(money.rupees, equals(0.01));
        expect(money.format(), equals('₹0.01'));
      });

      test('should handle rounding correctly', () {
        final money = Money.fromRupees(123.456); // Should round to 123.46
        expect(money.paise, equals(12346));
      });
    });

    group('toString', () {
      test('should use format() for toString', () {
        final money = Money.fromRupees(123.45);
        expect(money.toString(), equals(money.format()));
      });
    });
  });
}

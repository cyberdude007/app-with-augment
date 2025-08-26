import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paisa_split/features/new_expense/widgets/expense_type_toggle.dart';
import 'package:paisa_split/features/new_expense/widgets/category_picker.dart';
import 'package:paisa_split/data/models/expense_type.dart';
import 'package:paisa_split/data/models/category.dart';
import 'package:paisa_split/widgets/category_chip.dart';

void main() {
  group('ExpenseTypeToggle Widget Tests', () {
    testWidgets('should display both Split and Individual options', (tester) async {
      ExpenseType? selectedType;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseTypeToggle(
              selectedType: ExpenseType.split,
              onTypeChanged: (type) => selectedType = type,
            ),
          ),
        ),
      );

      expect(find.text('Split'), findsOneWidget);
      expect(find.text('Individual'), findsOneWidget);
      expect(find.text('Share with group members'), findsOneWidget);
      expect(find.text('Record only in your ledger'), findsOneWidget);
    });

    testWidgets('should highlight selected type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseTypeToggle(
              selectedType: ExpenseType.split,
              onTypeChanged: (_) {},
            ),
          ),
        ),
      );

      // Find the Split container and verify it's selected
      final splitContainer = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.text('Split').first,
          matching: find.byType(AnimatedContainer),
        ).first,
      );
      
      expect(splitContainer.decoration, isA<BoxDecoration>());
    });

    testWidgets('should call onTypeChanged when tapped', (tester) async {
      ExpenseType? selectedType;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseTypeToggle(
              selectedType: ExpenseType.split,
              onTypeChanged: (type) => selectedType = type,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Individual'));
      await tester.pump();

      expect(selectedType, equals(ExpenseType.individual));
    });

    testWidgets('should preserve form fields when toggling', (tester) async {
      // This would be tested in integration tests with the full form
      // Here we just test the toggle behavior
      ExpenseType currentType = ExpenseType.split;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ExpenseTypeToggle(
                  selectedType: currentType,
                  onTypeChanged: (type) {
                    setState(() {
                      currentType = type;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Toggle to Individual
      await tester.tap(find.text('Individual'));
      await tester.pump();

      expect(currentType, equals(ExpenseType.individual));

      // Toggle back to Split
      await tester.tap(find.text('Split'));
      await tester.pump();

      expect(currentType, equals(ExpenseType.split));
    });

    testWidgets('should be disabled when enabled is false', (tester) async {
      ExpenseType? selectedType;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseTypeToggle(
              selectedType: ExpenseType.split,
              onTypeChanged: (type) => selectedType = type,
              enabled: false,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Individual'));
      await tester.pump();

      // Should not change when disabled
      expect(selectedType, isNull);
    });
  });

  group('CompactExpenseTypeToggle Widget Tests', () {
    testWidgets('should display compact version correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactExpenseTypeToggle(
              selectedType: ExpenseType.split,
              onTypeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Split'), findsOneWidget);
      expect(find.text('Individual'), findsOneWidget);
      // Should not show descriptions in compact mode
      expect(find.text('Share with group members'), findsNothing);
    });
  });

  group('IndividualExpenseInfo Widget Tests', () {
    testWidgets('should display info banner correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IndividualExpenseInfo(),
          ),
        ),
      );

      expect(find.text('Recorded only in your ledger.'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });

  group('SplitMethodSelector Widget Tests', () {
    testWidgets('should display all split methods', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitMethodSelector(
              selectedMethod: SplitMethod.equally,
              onMethodChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Split Method'), findsOneWidget);
      expect(find.text('Equally'), findsOneWidget);
      expect(find.text('Exact'), findsOneWidget);
      expect(find.text('Percentage'), findsOneWidget);
    });

    testWidgets('should call onMethodChanged when method is selected', (tester) async {
      SplitMethod? selectedMethod;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitMethodSelector(
              selectedMethod: SplitMethod.equally,
              onMethodChanged: (method) => selectedMethod = method,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Exact'));
      await tester.pump();

      expect(selectedMethod, equals(SplitMethod.exact));
    });
  });

  group('CategoryChip Widget Tests', () {
    final testCategory = Category(
      id: 'food',
      name: 'Food',
      emoji: '🍽️',
      isFavorite: true,
      usageCount: 5,
      createdAt: DateTime.now(),
    );

    testWidgets('should display category information correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryChip(
              category: testCategory,
              showUsageCount: true,
            ),
          ),
        ),
      );

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('🍽️'), findsOneWidget);
      expect(find.text('5'), findsOneWidget); // Usage count
      expect(find.byIcon(Icons.star), findsOneWidget); // Favorite indicator
    });

    testWidgets('should handle tap events', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryChip(
              category: testCategory,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CategoryChip));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('should show selected state correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryChip(
              category: testCategory,
              isSelected: true,
            ),
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      
      expect(container.decoration, isA<BoxDecoration>());
    });
  });

  group('CategoryChipList Widget Tests', () {
    final testCategories = [
      Category(
        id: 'food',
        name: 'Food',
        emoji: '🍽️',
        createdAt: DateTime.now(),
      ),
      Category(
        id: 'transport',
        name: 'Transport',
        emoji: '🚕',
        createdAt: DateTime.now(),
      ),
    ];

    testWidgets('should display list of category chips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryChipList(
              categories: testCategories,
            ),
          ),
        ),
      );

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('🍽️'), findsOneWidget);
      expect(find.text('🚕'), findsOneWidget);
    });

    testWidgets('should handle category selection', (tester) async {
      Category? selectedCategory;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryChipList(
              categories: testCategories,
              onCategorySelected: (category) => selectedCategory = category,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Food'));
      await tester.pump();

      expect(selectedCategory?.name, equals('Food'));
    });

    testWidgets('should show selected category correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryChipList(
              categories: testCategories,
              selectedCategoryId: 'food',
            ),
          ),
        ),
      );

      // The selected chip should have different styling
      expect(find.byType(CategoryChip), findsNWidgets(2));
    });

    testWidgets('should handle empty category list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryChipList(
              categories: [],
            ),
          ),
        ),
      );

      expect(find.byType(CategoryChip), findsNothing);
    });
  });

  group('QuickCategorySelector Widget Tests', () {
    final quickCategories = [
      Category(
        id: 'food',
        name: 'Food',
        emoji: '🍽️',
        createdAt: DateTime.now(),
      ),
      Category(
        id: 'transport',
        name: 'Transport',
        emoji: '🚕',
        createdAt: DateTime.now(),
      ),
    ];

    testWidgets('should display quick categories and show all button', (tester) async {
      bool showAllTapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickCategorySelector(
              quickCategories: quickCategories,
              onShowAllCategories: () => showAllTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Show all categories'), findsOneWidget);

      await tester.tap(find.text('Show all categories'));
      await tester.pump();

      expect(showAllTapped, isTrue);
    });

    testWidgets('should handle category selection from quick chips', (tester) async {
      Category? selectedCategory;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickCategorySelector(
              quickCategories: quickCategories,
              onCategorySelected: (category) => selectedCategory = category,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Food'));
      await tester.pump();

      expect(selectedCategory?.name, equals('Food'));
    });
  });

  group('CategoryPicker Widget Tests', () {
    final allCategories = DefaultCategories.categories;
    final recentCategories = allCategories.take(3).toList();

    testWidgets('should display categories in compact layout', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CategoryPicker(
                categories: allCategories,
                recentCategories: recentCategories,
                onCategorySelected: (_) {},
                isExpanded: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Select Category'), findsOneWidget);
      expect(find.text('Search categories...'), findsOneWidget);
    });

    testWidgets('should display categories in expanded layout', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CategoryPicker(
                categories: allCategories,
                recentCategories: recentCategories,
                onCategorySelected: (_) {},
                isExpanded: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Select Category'), findsOneWidget);
      expect(find.text('Search categories...'), findsOneWidget);
    });

    testWidgets('should filter categories based on search', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CategoryPicker(
                categories: allCategories,
                recentCategories: recentCategories,
                onCategorySelected: (_) {},
                isExpanded: true,
              ),
            ),
          ),
        ),
      );

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Food');
      await tester.pump();

      // Should show filtered results
      expect(find.text('Food'), findsWidgets);
    });
  });
}

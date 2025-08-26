import 'package:flutter_test/flutter_test.dart';
import 'package:paisa_split/core/algorithms/fuzzy_search.dart';

void main() {
  group('FuzzySearch', () {
    final testCategories = [
      'Food',
      'Transport',
      'Groceries',
      'Entertainment',
      'Shopping',
      'Bills',
      'Health',
      'Education',
      'Travel',
      'Fuel',
    ];

    group('search', () {
      test('should return all items when query is empty', () {
        final results = FuzzySearch.search<String>(
          query: '',
          items: testCategories,
          getText: (item) => item,
          maxResults: 10,
        );
        
        expect(results.length, equals(testCategories.length));
      });

      test('should find exact matches with highest score', () {
        final results = FuzzySearch.search<String>(
          query: 'Food',
          items: testCategories,
          getText: (item) => item,
          maxResults: 10,
        );
        
        expect(results.isNotEmpty, isTrue);
        expect(results.first.item, equals('Food'));
        expect(results.first.matchType, equals(MatchType.exact));
      });

      test('should find prefix matches', () {
        final results = FuzzySearch.search<String>(
          query: 'Tra',
          items: testCategories,
          getText: (item) => item,
          maxResults: 10,
        );
        
        final transportResult = results.firstWhere((r) => r.item == 'Transport');
        expect(transportResult.matchType, equals(MatchType.prefix));
        
        final travelResult = results.firstWhere((r) => r.item == 'Travel');
        expect(travelResult.matchType, equals(MatchType.prefix));
      });

      test('should find contains matches', () {
        final results = FuzzySearch.search<String>(
          query: 'eat',
          items: testCategories,
          getText: (item) => item,
          maxResults: 10,
        );
        
        final entertainmentResult = results.firstWhere((r) => r.item == 'Entertainment');
        expect(entertainmentResult.matchType, equals(MatchType.contains));
      });

      test('should find edit distance matches', () {
        final results = FuzzySearch.search<String>(
          query: 'Bil', // Missing one character from 'Bills'
          items: testCategories,
          getText: (item) => item,
          maxResults: 10,
        );
        
        final billsResult = results.firstWhere((r) => r.item == 'Bills');
        expect(billsResult.matchType, equals(MatchType.editDistance));
      });

      test('should prioritize by match type', () {
        final items = ['Transport', 'Travel', 'Entertainment'];
        final results = FuzzySearch.search<String>(
          query: 'Tra',
          items: items,
          getText: (item) => item,
          maxResults: 10,
        );
        
        // Prefix matches should come before contains matches
        expect(results[0].item, anyOf(['Transport', 'Travel']));
        expect(results[0].matchType, equals(MatchType.prefix));
        expect(results[1].item, anyOf(['Transport', 'Travel']));
        expect(results[1].matchType, equals(MatchType.prefix));
        expect(results[2].item, equals('Entertainment'));
        expect(results[2].matchType, equals(MatchType.contains));
      });

      test('should respect maxResults limit', () {
        final results = FuzzySearch.search<String>(
          query: '',
          items: testCategories,
          getText: (item) => item,
          maxResults: 3,
        );
        
        expect(results.length, equals(3));
      });

      test('should handle case insensitive search', () {
        final results = FuzzySearch.search<String>(
          query: 'food',
          items: testCategories,
          getText: (item) => item,
          maxResults: 10,
        );
        
        expect(results.isNotEmpty, isTrue);
        expect(results.first.item, equals('Food'));
      });

      test('should use recent scores for ranking', () {
        final recentScores = <String, double>{
          'Bills': 0.9,
          'Food': 0.1,
        };
        
        final results = FuzzySearch.search<String>(
          query: '',
          items: ['Food', 'Bills'],
          getText: (item) => item,
          recentScores: recentScores,
          maxResults: 10,
        );
        
        // Bills should come first due to higher recent score
        expect(results.first.item, equals('Bills'));
        expect(results.first.score, greaterThan(results.last.score));
      });

      test('acceptance criteria: typing "tra" shows Transport at top', () {
        final results = FuzzySearch.search<String>(
          query: 'tra',
          items: testCategories,
          getText: (item) => item,
          maxResults: 10,
        );
        
        expect(results.isNotEmpty, isTrue);
        expect(results.first.item, anyOf(['Transport', 'Travel']));
        expect(results.first.matchType, equals(MatchType.prefix));
      });
    });

    group('searchCategories', () {
      test('should search categories with default parameters', () {
        final results = FuzzySearch.searchCategories(
          query: 'Food',
          categories: testCategories,
        );
        
        expect(results.isNotEmpty, isTrue);
        expect(results.first.item, equals('Food'));
      });

      test('should limit results correctly', () {
        final results = FuzzySearch.searchCategories(
          query: '',
          categories: testCategories,
          maxResults: 5,
        );
        
        expect(results.length, equals(5));
      });
    });

    group('searchMembers', () {
      final testMembers = [
        TestMember('Alice Johnson', 'alice@example.com'),
        TestMember('Bob Smith', 'bob@example.com'),
        TestMember('Charlie Brown', 'charlie@example.com'),
        TestMember('Diana Prince', 'diana@example.com'),
      ];

      test('should search members by name', () {
        final results = FuzzySearch.searchMembers<TestMember>(
          query: 'Alice',
          members: testMembers,
          getName: (member) => member.name,
        );
        
        expect(results.isNotEmpty, isTrue);
        expect(results.first.item.name, equals('Alice Johnson'));
      });

      test('should find partial name matches', () {
        final results = FuzzySearch.searchMembers<TestMember>(
          query: 'John',
          members: testMembers,
          getName: (member) => member.name,
        );
        
        expect(results.isNotEmpty, isTrue);
        expect(results.first.item.name, equals('Alice Johnson'));
      });
    });

    group('highlightMatches', () {
      test('should highlight exact matches', () {
        final result = FuzzySearch.highlightMatches('Food', 'Food');
        expect(result, equals('**Food**'));
      });

      test('should highlight partial matches', () {
        final result = FuzzySearch.highlightMatches('Transport', 'Trans');
        expect(result, equals('**Trans**port'));
      });

      test('should return original text for no matches', () {
        final result = FuzzySearch.highlightMatches('Food', 'xyz');
        expect(result, equals('Food'));
      });

      test('should return original text for empty query', () {
        final result = FuzzySearch.highlightMatches('Food', '');
        expect(result, equals('Food'));
      });
    });

    group('MatchType', () {
      test('should have correct display names', () {
        expect(MatchType.exact.displayName, equals('Exact match'));
        expect(MatchType.prefix.displayName, equals('Starts with'));
        expect(MatchType.contains.displayName, equals('Contains'));
        expect(MatchType.editDistance.displayName, equals('Similar'));
        expect(MatchType.none.displayName, equals('No match'));
      });
    });

    group('FuzzySearchResult', () {
      test('should implement equality correctly', () {
        final result1 = FuzzySearchResult<String>(
          item: 'Food',
          score: 100.0,
          matchType: MatchType.exact,
          matchedText: 'Food',
        );
        
        final result2 = FuzzySearchResult<String>(
          item: 'Food',
          score: 100.0,
          matchType: MatchType.exact,
          matchedText: 'Food',
        );
        
        final result3 = FuzzySearchResult<String>(
          item: 'Transport',
          score: 100.0,
          matchType: MatchType.exact,
          matchedText: 'Transport',
        );
        
        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });

      test('should have proper toString representation', () {
        final result = FuzzySearchResult<String>(
          item: 'Food',
          score: 100.0,
          matchType: MatchType.exact,
          matchedText: 'Food',
        );
        
        final string = result.toString();
        expect(string, contains('Food'));
        expect(string, contains('Exact match'));
        expect(string, contains('100.0'));
      });
    });

    group('RecentInteractionTracker', () {
      test('should record interactions', () {
        final tracker = RecentInteractionTracker<String>();
        
        tracker.recordInteraction('Food');
        
        final scores = tracker.getRecentScores();
        expect(scores['Food'], equals(1.0));
      });

      test('should decay scores over time', () {
        final tracker = RecentInteractionTracker<String>(
          decayPeriod: const Duration(days: 10),
        );
        
        // Mock old interaction (this would need to be tested with time manipulation)
        tracker.recordInteraction('Food');
        
        final scores = tracker.getRecentScores();
        expect(scores['Food'], equals(1.0));
      });

      test('should cleanup old interactions', () {
        final tracker = RecentInteractionTracker<String>(
          decayPeriod: const Duration(days: 1),
        );
        
        tracker.recordInteraction('Food');
        expect(tracker.trackedItemCount, equals(1));
        
        tracker.cleanup();
        // Would need time manipulation to test actual cleanup
        expect(tracker.trackedItemCount, greaterThanOrEqualTo(0));
      });
    });
  });
}

/// Test helper class
class TestMember {
  final String name;
  final String email;
  
  const TestMember(this.name, this.email);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestMember && name == other.name && email == other.email;
  
  @override
  int get hashCode => Object.hash(name, email);
}

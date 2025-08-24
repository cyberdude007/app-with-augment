/// Fuzzy search algorithm for finding matches in lists
class FuzzySearch {
  FuzzySearch._();

  /// Search for items matching the query
  /// 
  /// Returns results ranked by relevance:
  /// 1. Exact matches (highest priority)
  /// 2. Prefix matches
  /// 3. Contains matches
  /// 4. Edit distance ≤ 1 matches
  /// 
  /// Within each category, results are sorted by:
  /// - Recent interaction score (if provided)
  /// - Alphabetical order (for stable results)
  static List<FuzzySearchResult<T>> search<T>({
    required String query,
    required List<T> items,
    required String Function(T) getText,
    Map<T, double>? recentScores,
    int maxResults = 50,
  }) {
    if (query.isEmpty) {
      // Return all items sorted by recent score
      final results = items.map((item) => FuzzySearchResult(
        item: item,
        score: recentScores?[item] ?? 0.0,
        matchType: MatchType.none,
        matchedText: getText(item),
      )).toList();
      
      results.sort((a, b) => b.score.compareTo(a.score));
      return results.take(maxResults).toList();
    }

    final normalizedQuery = _normalize(query);
    final results = <FuzzySearchResult<T>>[];

    for (final item in items) {
      final text = getText(item);
      final normalizedText = _normalize(text);
      final recentScore = recentScores?[item] ?? 0.0;

      final matchType = _getMatchType(normalizedQuery, normalizedText);
      if (matchType != MatchType.none) {
        results.add(FuzzySearchResult(
          item: item,
          score: _calculateScore(matchType, recentScore),
          matchType: matchType,
          matchedText: text,
        ));
      }
    }

    // Sort by score (descending), then by text (ascending) for stable results
    results.sort((a, b) {
      final scoreComparison = b.score.compareTo(a.score);
      if (scoreComparison != 0) return scoreComparison;
      return a.matchedText.compareTo(b.matchedText);
    });

    return results.take(maxResults).toList();
  }

  /// Normalize text for comparison (lowercase, remove diacritics, trim)
  static String _normalize(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[ç]'), 'c');
  }

  /// Determine the type of match between query and text
  static MatchType _getMatchType(String normalizedQuery, String normalizedText) {
    if (normalizedText == normalizedQuery) {
      return MatchType.exact;
    }
    
    if (normalizedText.startsWith(normalizedQuery)) {
      return MatchType.prefix;
    }
    
    if (normalizedText.contains(normalizedQuery)) {
      return MatchType.contains;
    }
    
    if (_editDistance(normalizedQuery, normalizedText) <= 1) {
      return MatchType.editDistance;
    }
    
    return MatchType.none;
  }

  /// Calculate relevance score based on match type and recent interaction
  static double _calculateScore(MatchType matchType, double recentScore) {
    final baseScore = switch (matchType) {
      MatchType.exact => 1000.0,
      MatchType.prefix => 800.0,
      MatchType.contains => 600.0,
      MatchType.editDistance => 400.0,
      MatchType.none => 0.0,
    };
    
    // Add recent interaction bonus (0-100 range)
    return baseScore + (recentScore * 100);
  }

  /// Calculate edit distance (Levenshtein distance) between two strings
  /// Optimized to return early if distance exceeds threshold
  static int _editDistance(String s1, String s2, {int maxDistance = 1}) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length > maxDistance ? maxDistance + 1 : s2.length;
    if (s2.isEmpty) return s1.length > maxDistance ? maxDistance + 1 : s1.length;

    final len1 = s1.length;
    final len2 = s2.length;

    // If length difference is greater than maxDistance, early return
    if ((len1 - len2).abs() > maxDistance) {
      return maxDistance + 1;
    }

    // Use two rows instead of full matrix for memory efficiency
    var previousRow = List<int>.generate(len2 + 1, (i) => i);
    var currentRow = List<int>.filled(len2 + 1, 0);

    for (int i = 1; i <= len1; i++) {
      currentRow[0] = i;
      var minInRow = i;

      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        currentRow[j] = [
          currentRow[j - 1] + 1, // insertion
          previousRow[j] + 1,     // deletion
          previousRow[j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);

        if (currentRow[j] < minInRow) {
          minInRow = currentRow[j];
        }
      }

      // Early termination if minimum distance in row exceeds threshold
      if (minInRow > maxDistance) {
        return maxDistance + 1;
      }

      // Swap rows
      final temp = previousRow;
      previousRow = currentRow;
      currentRow = temp;
    }

    return previousRow[len2];
  }

  /// Search for categories with fuzzy matching
  static List<FuzzySearchResult<String>> searchCategories({
    required String query,
    required List<String> categories,
    Map<String, double>? recentScores,
    int maxResults = 10,
  }) {
    return search<String>(
      query: query,
      items: categories,
      getText: (category) => category,
      recentScores: recentScores,
      maxResults: maxResults,
    );
  }

  /// Search for members with fuzzy matching
  static List<FuzzySearchResult<T>> searchMembers<T>({
    required String query,
    required List<T> members,
    required String Function(T) getName,
    Map<T, double>? recentScores,
    int maxResults = 20,
  }) {
    return search<T>(
      query: query,
      items: members,
      getText: getName,
      recentScores: recentScores,
      maxResults: maxResults,
    );
  }

  /// Highlight matching parts of text for display
  static String highlightMatches(String text, String query) {
    if (query.isEmpty) return text;
    
    final normalizedText = _normalize(text);
    final normalizedQuery = _normalize(query);
    
    final index = normalizedText.indexOf(normalizedQuery);
    if (index == -1) return text;
    
    // Find the actual position in the original text
    var actualIndex = 0;
    var normalizedIndex = 0;
    
    while (normalizedIndex < index && actualIndex < text.length) {
      if (_normalize(text[actualIndex]) == normalizedText[normalizedIndex]) {
        normalizedIndex++;
      }
      actualIndex++;
    }
    
    if (actualIndex >= text.length) return text;
    
    final beforeMatch = text.substring(0, actualIndex);
    final match = text.substring(actualIndex, actualIndex + query.length);
    final afterMatch = text.substring(actualIndex + query.length);
    
    return '$beforeMatch**$match**$afterMatch';
  }
}

/// Type of match found during fuzzy search
enum MatchType {
  exact,
  prefix,
  contains,
  editDistance,
  none;

  /// Get display name for match type
  String get displayName => switch (this) {
    MatchType.exact => 'Exact match',
    MatchType.prefix => 'Starts with',
    MatchType.contains => 'Contains',
    MatchType.editDistance => 'Similar',
    MatchType.none => 'No match',
  };
}

/// Result of a fuzzy search operation
class FuzzySearchResult<T> {
  final T item;
  final double score;
  final MatchType matchType;
  final String matchedText;

  const FuzzySearchResult({
    required this.item,
    required this.score,
    required this.matchType,
    required this.matchedText,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FuzzySearchResult<T> &&
          item == other.item &&
          score == other.score &&
          matchType == other.matchType &&
          matchedText == other.matchedText;

  @override
  int get hashCode => Object.hash(item, score, matchType, matchedText);

  @override
  String toString() => 
      'FuzzySearchResult($matchedText, ${matchType.displayName}, score: $score)';
}

/// Helper class for tracking recent interactions
class RecentInteractionTracker<T> {
  final Map<T, DateTime> _lastInteraction = {};
  final Duration _decayPeriod;

  RecentInteractionTracker({
    Duration decayPeriod = const Duration(days: 30),
  }) : _decayPeriod = decayPeriod;

  /// Record an interaction with an item
  void recordInteraction(T item) {
    _lastInteraction[item] = DateTime.now();
  }

  /// Get recent interaction scores (0.0 to 1.0)
  Map<T, double> getRecentScores() {
    final now = DateTime.now();
    final scores = <T, double>{};

    for (final entry in _lastInteraction.entries) {
      final item = entry.key;
      final lastInteraction = entry.value;
      final daysSince = now.difference(lastInteraction).inDays;

      if (daysSince <= _decayPeriod.inDays) {
        // Linear decay from 1.0 to 0.0 over the decay period
        final score = 1.0 - (daysSince / _decayPeriod.inDays);
        scores[item] = score.clamp(0.0, 1.0);
      }
    }

    return scores;
  }

  /// Clear old interactions beyond the decay period
  void cleanup() {
    final cutoff = DateTime.now().subtract(_decayPeriod);
    _lastInteraction.removeWhere((_, lastInteraction) => 
        lastInteraction.isBefore(cutoff));
  }

  /// Get number of tracked items
  int get trackedItemCount => _lastInteraction.length;
}

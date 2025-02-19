import 'package:flutter/foundation.dart';

/// Abstract interface for artist-specific song matching implementations.
/// 
/// This interface defines the contract that all artist-specific song matchers
/// must implement to provide consistent song matching behavior across different
/// artists.
abstract class SongMatcher {
  /// The unique identifier for the artist this matcher handles
  String get artistId;

  /// The display name of the artist
  String get artistName;

  /// Finds similar song titles based on a query string.
  /// 
  /// Returns a list of potential matches sorted by relevance.
  /// The implementation should handle:
  /// - Exact matches
  /// - Case-insensitive matches
  /// - Abbreviations
  /// - Partial matches
  Future<List<String>> findSimilarTitles(String query);

  /// Finds the best matching official title for a given input.
  /// 
  /// Returns null if no suitable match is found.
  /// The implementation should handle:
  /// - Exact matches
  /// - Case-insensitive matches
  /// - Abbreviations
  /// - Partial matches
  Future<String?> findMatchingTitle(String title);

  /// Adds a new song to the official list for this artist.
  /// 
  /// This allows the song matcher to learn new official songs over time.
  Future<void> addToOfficialList(String newSong);

  /// Adds a new abbreviation mapping to an official song title.
  /// 
  /// This allows the song matcher to learn new abbreviations over time.
  Future<void> addToAbbreviations(String abbreviation, String officialTitle);

  /// Configuration for title cleaning and matching.
  @protected
  SongMatcherConfig get config;
}

/// Configuration for song matcher implementations.
/// 
/// This class encapsulates artist-specific matching rules and patterns.
class SongMatcherConfig {
  /// Regular expressions for cleaning song titles
  final List<Pattern> cleaningPatterns;

  /// Custom rules for handling transitions between songs
  final List<Pattern> transitionPatterns;

  /// Whether to preserve original case when matching
  final bool preserveCase;

  /// Minimum length for partial matches
  final int minPartialMatchLength;

  /// Custom scoring weights for different match types
  final MatchWeights matchWeights;

  const SongMatcherConfig({
    this.cleaningPatterns = const [],
    this.transitionPatterns = const [],
    this.preserveCase = false,
    this.minPartialMatchLength = 3,
    this.matchWeights = const MatchWeights(),
  });
}

/// Weights for different types of matches to help with relevance sorting.
class MatchWeights {
  /// Weight for exact matches
  final double exactMatch;

  /// Weight for case-insensitive matches
  final double caseInsensitiveMatch;

  /// Weight for abbreviation matches
  final double abbreviationMatch;

  /// Weight for partial matches
  final double partialMatch;

  /// Base weight for length difference penalty
  final double lengthDifferencePenalty;

  const MatchWeights({
    this.exactMatch = 1.0,
    this.caseInsensitiveMatch = 0.9,
    this.abbreviationMatch = 0.8,
    this.partialMatch = 0.5,
    this.lengthDifferencePenalty = 0.1,
  });
}

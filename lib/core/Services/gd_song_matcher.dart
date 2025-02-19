import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../../services/logger_service.dart';
import 'song_matcher.dart';

/// Grateful Dead specific implementation of SongMatcher.
class GdSongMatcher implements SongMatcher {
  @override
  String get artistId => 'grateful_dead';

  @override
  String get artistName => 'Grateful Dead';

  List<String>? _officialSongs;
  Map<String, String>? _abbreviations;

  @override
  SongMatcherConfig get config => const SongMatcherConfig(
    cleaningPatterns: [
      r'(?:\s*-+\s*>|\s*>)+\s*$',  // Remove transition markers
      r'\[\d{4}-\d{2}-\d{2}\]',    // Remove dates
    ],
    transitionPatterns: [
      r'\s*-+\s*>\s*',             // Standard transition
      r'\s*>\s*',                  // Short transition
    ],
    preserveCase: false,
    minPartialMatchLength: 3,
    matchWeights: MatchWeights(
      exactMatch: 1.0,
      caseInsensitiveMatch: 0.9,
      abbreviationMatch: 0.8,
      partialMatch: 0.5,
      lengthDifferencePenalty: 0.1,
    ),
  );

  Future<void> _loadOfficialSongs() async {
    if (_officialSongs != null) return;

    try {
      final file = File(path.join(
        Directory.current.path,
        'assets',
        'official_gd_songs.json'
      ));
      
      if (await file.exists()) {
        final jsonContent = await file.readAsString();
        final List<dynamic> songList = jsonDecode(jsonContent);
        _officialSongs = songList.cast<String>();
        LoggerService.instance.info('Loaded ${_officialSongs!.length} official songs');
      } else {
        LoggerService.instance.warning('official_gd_songs.json not found');
        _officialSongs = [];
      }
    } catch (e, stack) {
      LoggerService.instance.error('Error loading official songs', e, stack);
      _officialSongs = [];
    }
  }

  Future<void> _loadAbbreviations() async {
    if (_abbreviations != null) return;

    try {
      final file = File(path.join(
        Directory.current.path,
        'assets',
        'song_abbreviations.json'
      ));
      
      if (await file.exists()) {
        final jsonContent = await file.readAsString();
        final Map<String, dynamic> abbrevMap = jsonDecode(jsonContent);
        _abbreviations = abbrevMap.map((key, value) => MapEntry(key, value as String));
      } else {
        LoggerService.instance.warning('song_abbreviations.json not found');
        _abbreviations = {};
      }
    } catch (e, stack) {
      LoggerService.instance.error('Error loading abbreviations', e, stack);
      _abbreviations = {};
    }
  }

  String _cleanTitle(String title) {
    var cleaned = title;
    for (final pattern in config.cleaningPatterns) {
      cleaned = cleaned.replaceAll(RegExp(pattern.toString()), '');
    }
    return cleaned.trim();
  }

  @override
  Future<List<String>> findSimilarTitles(String query) async {
    await _loadOfficialSongs();
    await _loadAbbreviations();

    LoggerService.instance.debug('Finding similar titles for query: $query');

    final cleanQuery = _cleanTitle(query);
    final queryLower = cleanQuery.toLowerCase();
    
    LoggerService.instance.debug('Cleaned query: $cleanQuery');

    final matches = <String>[];
    final scores = <String, double>{};
    
    // Check abbreviations
    if (_abbreviations!.containsKey(queryLower)) {
      final match = _abbreviations![queryLower]!;
      matches.add(match);
      scores[match] = config.matchWeights.abbreviationMatch;
      LoggerService.instance.debug('Found abbreviation match: $match');
    }

    // Process official songs
    for (final song in _officialSongs!) {
      if (matches.contains(song)) continue;

      final songLower = song.toLowerCase();
      double? score;

      // Exact match
      if (song == cleanQuery) {
        score = config.matchWeights.exactMatch;
      }
      // Case-insensitive match
      else if (songLower == queryLower) {
        score = config.matchWeights.caseInsensitiveMatch;
      }
      // Partial match
      else if (songLower.contains(queryLower) || queryLower.contains(songLower)) {
        if (queryLower.length >= config.minPartialMatchLength) {
          score = config.matchWeights.partialMatch;
          // Apply length difference penalty
          final lengthDiff = (song.length - cleanQuery.length).abs();
          score -= lengthDiff * config.matchWeights.lengthDifferencePenalty;
        }
      }

      if (score != null && score > 0) {
        matches.add(song);
        scores[song] = score;
      }
    }

    // Sort by score
    matches.sort((a, b) => (scores[b] ?? 0).compareTo(scores[a] ?? 0));
    return matches;
  }

  @override
  Future<String?> findMatchingTitle(String title) async {
    LoggerService.instance.debug('Finding matching title for: $title');
    await _loadOfficialSongs();
    await _loadAbbreviations();
    
    final cleanTitle = _cleanTitle(title);
    final lowerTitle = cleanTitle.toLowerCase();
    
    LoggerService.instance.debug('Cleaned title: $cleanTitle');

    // First try exact match
    if (_officialSongs!.contains(cleanTitle)) {
      LoggerService.instance.debug('Found exact match: $cleanTitle');
      return cleanTitle;
    }

    // Check abbreviations
    if (_abbreviations!.containsKey(lowerTitle)) {
      final match = _abbreviations![lowerTitle]!;
      LoggerService.instance.debug('Found abbreviation match: $match');
      return match;
    }

    // Try case-insensitive match
    final caseMatch = _officialSongs!.firstWhere(
      (song) => song.toLowerCase() == lowerTitle,
      orElse: () => '',
    );

    if (caseMatch.isNotEmpty) {
      LoggerService.instance.debug('Found case-insensitive match: $caseMatch');
      return caseMatch;
    }

    // Try partial matches if query is long enough
    if (lowerTitle.length >= config.minPartialMatchLength) {
      LoggerService.instance.debug('Trying partial matches');
      final partialMatches = _officialSongs!.where(
        (song) => song.toLowerCase().contains(lowerTitle) ||
                  lowerTitle.contains(song.toLowerCase())
      ).toList();

      if (partialMatches.isNotEmpty) {
        LoggerService.instance.debug('Found ${partialMatches.length} partial matches');
        
        // Sort by score using the same scoring system as findSimilarTitles
        final scores = <String, double>{};
        for (final match in partialMatches) {
          final lengthDiff = (match.length - cleanTitle.length).abs();
          scores[match] = config.matchWeights.partialMatch -
                         (lengthDiff * config.matchWeights.lengthDifferencePenalty);
        }
        
        partialMatches.sort((a, b) => (scores[b] ?? 0).compareTo(scores[a] ?? 0));
        
        final bestMatch = partialMatches.first;
        LoggerService.instance.debug('Selected best partial match: $bestMatch');
        return bestMatch;
      }
    }

    LoggerService.instance.debug('No match found for: $cleanTitle');
    return null;
  }

  @override
  Future<void> addToOfficialList(String newSong) async {
    await _loadOfficialSongs();
    if (!_officialSongs!.contains(newSong)) {
      _officialSongs!.add(newSong);
      final file = File(path.join(
        Directory.current.path,
        'assets',
        'official_gd_songs.json'
      ));
      await file.writeAsString(jsonEncode(_officialSongs));
    }
  }

  @override
  Future<void> addToAbbreviations(String abbreviation, String officialTitle) async {
    await _loadAbbreviations();
    if (!_abbreviations!.containsKey(abbreviation)) {
      _abbreviations![abbreviation] = officialTitle;
      final file = File(path.join(
        Directory.current.path,
        'assets',
        'song_abbreviations.json'
      ));
      await file.writeAsString(jsonEncode(_abbreviations));
    }
  }
}

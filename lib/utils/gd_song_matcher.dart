// lib/utils/gd_song_matcher.dart

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class GdSongMatcher {
  List<String> _officialSongList = [];
  Map<String, String> _abbreviationMap = {};
  bool _isInitialized = false;

  /// Initializes the song matcher by loading song data
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1) Load the official songs array from assets
    final offJson = await rootBundle.loadString('assets/official_gd_songs.json');
    final List<dynamic> offList = jsonDecode(offJson);
    _officialSongList = offList.map((item) => item.toString()).toList();

    // 2) Load the abbreviation map from assets
    final abbrJson = await rootBundle.loadString('assets/song_abbreviations.json');
    final Map<String, dynamic> abbrMap = jsonDecode(abbrJson);
    _abbreviationMap = abbrMap.map((k, v) => MapEntry(k.toLowerCase(), v.toString()));

    _isInitialized = true;
  }

  /// Finds the matching title from the official song list
  Future<String?> findMatchingTitle(String songTitle) async {
    final matched = await matchSong(songTitle);
    return matched?.normalizedTitle;
  }

  /// Given a song title, tries to match it with an official song
  Future<MatchedSong?> matchSong(String songTitle) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Remove common live recording phrases and location info
    final cleanTitle = songTitle
        .replaceAll(RegExp(r'\s*\(Live.*?\)'), '')
        .replaceAll(RegExp(r'\s*at.*$'), '')
        .replaceAll(RegExp(r'\s*\(.*?\)'), '')  // Remove any parenthetical info
        .replaceAll(RegExp(r',.*$'), '')        // Remove anything after a comma
        .trim();
    
    // Try exact match first
    for (final official in _officialSongList) {
      if (official.toLowerCase() == cleanTitle.toLowerCase()) {
        return MatchedSong(
          originalTitle: songTitle,
          normalizedTitle: official,
          assembledTitle: official,
        );
      }
    }

    // Try without "The" prefix
    final titleWithoutThe = cleanTitle.replaceAll(RegExp(r'^The\s+'), '').toLowerCase();
    for (final official in _officialSongList) {
      final officialWithoutThe = official.replaceAll(RegExp(r'^The\s+'), '').toLowerCase();
      if (officialWithoutThe == titleWithoutThe) {
        return MatchedSong(
          originalTitle: songTitle,
          normalizedTitle: official,
          assembledTitle: official,
        );
      }
    }

    // Try abbreviation match
    if (_abbreviationMap.containsKey(cleanTitle.toLowerCase())) {
      final official = _abbreviationMap[cleanTitle.toLowerCase()]!;
      return MatchedSong(
        originalTitle: songTitle,
        normalizedTitle: official,
        assembledTitle: official,
      );
    }

    return null;
  }

  String _cleanString(String input) {
    return input
        .replaceAll(RegExp(r'[^\w\s]'), '')  // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' ')     // Normalize whitespace
        .trim()
        .toLowerCase();
  }

  double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final len1 = s1.length;
    final len2 = s2.length;
    final maxDist = (len1 + len2) ~/ 2;
    
    var matches = 0;
    var pos1 = 0;
    var pos2 = 0;
    
    for (var i = 0; i < len1; i++) {
      final start = (i - maxDist > 0) ? i - maxDist : 0;
      final end = (i + maxDist < len2) ? i + maxDist : len2 - 1;
      
      for (var j = start; j <= end; j++) {
        if (s1[i] == s2[j]) {
          matches++;
          pos1 += i;
          pos2 += j;
          break;
        }
      }
    }
    
    if (matches == 0) return 0.0;
    
    return matches / maxDist.toDouble();
  }
}

/// Class to hold matched song information
class MatchedSong {
  final String originalTitle;
  final String normalizedTitle;
  final String assembledTitle;

  MatchedSong({
    required this.originalTitle,
    required this.normalizedTitle,
    required this.assembledTitle,
  });
}

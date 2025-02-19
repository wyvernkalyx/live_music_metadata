// File: lib/utils/song_matcher.dart

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class SongMatcher {
  Map<String, String>? _abbreviations;
  
  Future<void> initialize() async {
    if (_abbreviations != null) return;
    
    try {
      final jsonString = await rootBundle.loadString('assets/song_abbreviations.json');
      _abbreviations = Map<String, String>.from(json.decode(jsonString));
      print('Loaded ${_abbreviations!.length} song abbreviations');
    } catch (e) {
      print('Error loading song abbreviations: $e');
      _abbreviations = {};
    }
  }

  String normalizeTitle(String title, {String? date}) {
    if (_abbreviations == null) {
      print('Warning: Song matcher not initialized');
      return title;
    }

    // Remove any existing date in brackets
    title = title.replaceAll(RegExp(r'\s*\[\d{4}-\d{2}-\d{2}\]'), '');
    
    // Remove common suffixes like "Live at..."
    title = title.replaceAll(RegExp(r'\s*\(Live at.*?\)'), '');
    
    // Convert to lowercase for matching
    final searchTitle = title.toLowerCase().trim();
    
    // Try to find a match in the abbreviations
    String normalizedTitle = _abbreviations!.entries.firstWhere(
      (entry) => searchTitle.contains(entry.key),
      orElse: () => MapEntry(searchTitle, title),
    ).value;
    
    return normalizedTitle.trim();
  }

  String assembleTitle(String title, String date, bool transition) {
    final normalized = normalizeTitle(title);
    return transition ? '$normalized -> [$date]' : '$normalized [$date]';
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'logger_service.dart';

class GdSongMatcher {
  List<String>? _officialSongs;
  Map<String, String>? _abbreviations;

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

  Future<List<String>> findSimilarTitles(String query) async {
    await _loadOfficialSongs();
    await _loadAbbreviations();

    LoggerService.instance.debug('Finding similar titles for query: $query');

    // Clean the query similar to findMatchingTitle
    final cleanQuery = query
        .replaceAll(RegExp(r'(?:\s*-+\s*>|\s*>)+\s*$'), '')  // Remove transition markers
        .replaceAll(RegExp(r'\[\d{4}-\d{2}-\d{2}\]'), '')    // Remove dates
        .trim();
    final queryLower = cleanQuery.toLowerCase();
    
    LoggerService.instance.debug('Cleaned query: $cleanQuery');

    // Start with exact matches
    final matches = <String>[];
    
    // Check abbreviations first
    if (_abbreviations!.containsKey(queryLower)) {
      final match = _abbreviations![queryLower]!;
      matches.add(match);
      LoggerService.instance.debug('Found abbreviation match: $match');
    }

    // Add exact matches
    final exactMatches = _officialSongs!.where(
      (song) => song.toLowerCase() == queryLower
    ).toList();
    
    if (exactMatches.isNotEmpty) {
      matches.addAll(exactMatches);
      LoggerService.instance.debug('Found exact matches: $exactMatches');
    }

    // Add partial matches
    final partialMatches = _officialSongs!.where(
      (song) => !matches.contains(song) && (
        song.toLowerCase().contains(queryLower) ||
        queryLower.contains(song.toLowerCase())
      )
    ).toList();
    
    if (partialMatches.isNotEmpty) {
      matches.addAll(partialMatches);
      LoggerService.instance.debug('Found partial matches: $partialMatches');
    }

    // Sort results by relevance
    return matches..sort((a, b) {
      final aLower = a.toLowerCase();
      final bLower = b.toLowerCase();
      
      // Exact matches first
      if (aLower == queryLower) return -1;
      if (bLower == queryLower) return 1;
      
      // Then by length difference
      final aDiff = (a.length - cleanQuery.length).abs();
      final bDiff = (b.length - cleanQuery.length).abs();
      return aDiff.compareTo(bDiff);
    });
  }

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

  Future<String?> findMatchingTitle(String title) async {
    LoggerService.instance.debug('Finding matching title for: $title');
    await _loadOfficialSongs();
    await _loadAbbreviations();
    
    // Remove any transition markers or dates
    final cleanTitle = title
        .replaceAll(RegExp(r'(?:\s*-+\s*>|\s*>)+\s*$'), '')  // Remove transition markers
        .replaceAll(RegExp(r'\[\d{4}-\d{2}-\d{2}\]'), '')    // Remove dates
        .trim();
    
    LoggerService.instance.debug('Cleaned title: $cleanTitle');

    // First try exact match
    if (_officialSongs!.contains(cleanTitle)) {
      LoggerService.instance.debug('Found exact match: $cleanTitle');
      return cleanTitle;
    }

    // Try case-insensitive match
    final lowerTitle = cleanTitle.toLowerCase();
    LoggerService.instance.debug('Trying case-insensitive match for: $lowerTitle');
    
    // Check abbreviations first
    if (_abbreviations!.containsKey(lowerTitle)) {
      final match = _abbreviations![lowerTitle]!;
      LoggerService.instance.debug('Found abbreviation match: $match');
      return match;
    }

    // Try to find in official songs
    final match = _officialSongs!.firstWhere(
      (song) => song.toLowerCase() == lowerTitle,
      orElse: () => '',
    );

    if (match.isNotEmpty) {
      LoggerService.instance.debug('Found case-insensitive match: $match');
      return match;
    }

    // Try partial matches
    LoggerService.instance.debug('Trying partial matches');
    final partialMatches = _officialSongs!.where(
      (song) => song.toLowerCase().contains(lowerTitle) ||
                lowerTitle.contains(song.toLowerCase())
    ).toList();

    if (partialMatches.isNotEmpty) {
      LoggerService.instance.debug('Found ${partialMatches.length} partial matches: $partialMatches');
      
      // Return the closest match by length
      partialMatches.sort((a, b) {
        final aDiff = (a.length - cleanTitle.length).abs();
        final bDiff = (b.length - cleanTitle.length).abs();
        return aDiff.compareTo(bDiff);
      });
      
      final bestMatch = partialMatches.first;
      LoggerService.instance.debug('Selected best partial match: $bestMatch');
      return bestMatch;
    }

    LoggerService.instance.debug('No match found for: $cleanTitle');
    return null;
  }
}

import 'package:flutter/foundation.dart';
import 'song_matcher.dart';
import 'gd_song_matcher.dart';

/// Service for managing and accessing artist-specific song matchers.
class SongMatcherRegistry extends ChangeNotifier {
  static final SongMatcherRegistry instance = SongMatcherRegistry._();
  
  SongMatcherRegistry._() {
    // Register default matchers
    _registerMatcher(GdSongMatcher());
  }

  final Map<String, SongMatcher> _matchers = {};
  
  /// Gets a song matcher for the specified artist ID.
  /// Returns null if no matcher is registered for the artist.
  SongMatcher? getMatcherForArtist(String artistId) {
    return _matchers[artistId];
  }

  /// Gets a song matcher by artist name.
  /// This is a convenience method that searches by display name.
  /// Returns null if no matcher is found.
  SongMatcher? getMatcherByArtistName(String artistName) {
    try {
      return _matchers.values.firstWhere(
        (matcher) => matcher.artistName.toLowerCase() == artistName.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Registers a new song matcher.
  /// If a matcher already exists for the artist, it will be replaced.
  void _registerMatcher(SongMatcher matcher) {
    _matchers[matcher.artistId] = matcher;
    notifyListeners();
  }

  /// Gets all registered matchers.
  List<SongMatcher> get allMatchers => _matchers.values.toList();

  /// Gets all registered artist names.
  List<String> get supportedArtists => 
      _matchers.values.map((m) => m.artistName).toList();

  /// Checks if a matcher exists for the given artist ID.
  bool hasMatcherForArtist(String artistId) => _matchers.containsKey(artistId);

  /// Checks if a matcher exists for the given artist name.
  bool hasMatcherForArtistName(String artistName) => 
      _matchers.values.any((m) => 
          m.artistName.toLowerCase() == artistName.toLowerCase());
}

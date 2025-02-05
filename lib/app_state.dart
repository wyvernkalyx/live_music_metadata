import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:live_music_metadata_manager/core/models/artist_configuration.dart';

class AppState with ChangeNotifier {
  String? _selectedDirectory;
  String? get selectedDirectory => _selectedDirectory;

  bool _isRenaming = false;
  bool get isRenaming => _isRenaming;

  List<ArtistConfiguration> _artistConfigurations = [];
  List<ArtistConfiguration> get artistConfigurations => _artistConfigurations;

  ArtistConfiguration? _selectedArtist;
  ArtistConfiguration? get selectedArtist => _selectedArtist;

  List<(String, String)> _nonNormalizedFolders = [];
  List<(String, String)> get nonNormalizedFolders => _nonNormalizedFolders;

  static const _artistConfigsKey = 'artistConfigs';
  static const _selectedArtistNameKey = 'selectedArtistName';

  AppState() {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Initialize with default Grateful Dead configuration if no configs exist
    if (!prefs.containsKey(_artistConfigsKey)) {
      _artistConfigurations = [
        ArtistConfiguration(
          name: 'Grateful Dead',
          folderPrefix: 'gd',
        )
      ];
      await _saveArtistConfigurations();
      _selectedArtist = _artistConfigurations[0];
      await _saveSelectedArtist();
    } else {
      final artistConfigsJson = prefs.getStringList(_artistConfigsKey);
      if (artistConfigsJson != null) {
        _artistConfigurations = artistConfigsJson
            .map((json) => ArtistConfiguration.fromJson(jsonDecode(json)))
            .toList();
      }
    }

    final selectedArtistName = prefs.getString(_selectedArtistNameKey);
    if (selectedArtistName != null && _artistConfigurations.isNotEmpty) {
      _selectedArtist = _artistConfigurations.firstWhere(
        (artist) => artist.name == selectedArtistName,
        orElse: () => _artistConfigurations[0],
      );
    } else if (_artistConfigurations.isNotEmpty) {
      _selectedArtist = _artistConfigurations[0];
      await _saveSelectedArtist();
    }

    print('Loaded artist configurations: $_artistConfigurations');
    print('Selected artist: ${_selectedArtist?.name}');
    notifyListeners();
  }

  void addArtistConfiguration(ArtistConfiguration artistConfig) {
    _artistConfigurations.add(artistConfig);
    _saveArtistConfigurations();
    notifyListeners();
  }

  void updateArtistConfiguration(ArtistConfiguration updatedArtistConfig) {
    final index = _artistConfigurations
        .indexWhere((artist) => artist.name == updatedArtistConfig.name);
    if (index != -1) {
      _artistConfigurations[index] = updatedArtistConfig;
      _saveArtistConfigurations();
      notifyListeners();
    }
  }

  void removeArtistConfiguration(String artistName) {
    _artistConfigurations.removeWhere((artist) => artist.name == artistName);
    if (_selectedArtist?.name == artistName) {
      _selectedArtist = _artistConfigurations.isNotEmpty ? _artistConfigurations[0] : null;
    }
    _saveArtistConfigurations();
    notifyListeners();
  }

  void setSelectedArtist(ArtistConfiguration? artist) {
    _selectedArtist = artist;
    _saveSelectedArtist();
    print('Selected artist changed to: ${artist?.name}');
    notifyListeners();
  }

  Future<void> _saveArtistConfigurations() async {
    final prefs = await SharedPreferences.getInstance();
    final artistConfigsJson =
        _artistConfigurations.map((artist) => jsonEncode(artist.toJson())).toList();
    await prefs.setStringList(_artistConfigsKey, artistConfigsJson);
  }

  Future<void> _saveSelectedArtist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedArtist != null) {
      await prefs.setString(_selectedArtistNameKey, _selectedArtist!.name);
    } else {
      await prefs.remove(_selectedArtistNameKey);
    }
  }

  void setSelectedDirectory(String? directory) {
    _selectedDirectory = directory;
    print('Selected directory: $directory');
    print('Current artist: ${_selectedArtist?.name}');
    notifyListeners();
  }

  void startRenaming() {
    _isRenaming = true;
    notifyListeners();
  }

  void stopRenaming() {
    _isRenaming = false;
    notifyListeners();
  }

  void setNonNormalizedFolders(List<(String, String)> folders) {
    _nonNormalizedFolders = folders;
    print('Non-normalized folders updated: $folders');
    notifyListeners();
  }
}
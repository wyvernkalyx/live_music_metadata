// File: lib/services/preferences_service.dart

import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:convert';

class PreferencesService {
  static const String _prefsFileName = 'preferences.json';
  static PreferencesService? _instance;
  late final String _prefsFilePath;
  Map<String, dynamic> _preferences = {};

  PreferencesService._internal() {
    _prefsFilePath = path.join(
      path.dirname(Platform.resolvedExecutable),
      'data',
      _prefsFileName,
    );
    _loadPreferences();
  }

  static PreferencesService get instance {
    _instance ??= PreferencesService._internal();
    return _instance!;
  }

  Future<void> _loadPreferences() async {
    try {
      final file = File(_prefsFilePath);
      if (await file.exists()) {
        final contents = await file.readAsString();
        _preferences = json.decode(contents) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error loading preferences: $e');
      _preferences = {};
    }
  }

  Future<void> _savePreferences() async {
    try {
      final file = File(_prefsFilePath);
      await file.parent.create(recursive: true);
      await file.writeAsString(json.encode(_preferences));
    } catch (e) {
      print('Error saving preferences: $e');
    }
  }

  Future<String?> getDefaultMediaFolder() async {
    return _preferences['defaultMediaFolder'] as String?;
  }

  Future<void> setDefaultMediaFolder(String path) async {
    _preferences['defaultMediaFolder'] = path;
    await _savePreferences();
  }
}

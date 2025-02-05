// lib/core/preferences.dart
import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static const String backupFolderKey = 'backup_folder';

  static Future<String?> getBackupFolder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(backupFolderKey);
  }

  static Future<void> setBackupFolder(String folder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(backupFolderKey, folder);
  }
}

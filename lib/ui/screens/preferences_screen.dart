// lib/ui/screens/preferences_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({Key? key}) : super(key: key);

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  String? backupFolder;

  @override
  void initState() {
    super.initState();
    _loadBackupFolder();
  }

  Future<void> _loadBackupFolder() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      backupFolder = prefs.getString('backup_folder');
    });
  }

  Future<void> _selectBackupFolder() async {
  // Let the user pick a folder
  String? folder = await FilePicker.platform.getDirectoryPath(
    dialogTitle: 'Select Backup Folder',
  );
  if (folder != null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backup_folder', folder);
    setState(() {
      backupFolder = folder;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preferences')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Backup Folder'),
            subtitle: Text(backupFolder ?? 'Not set'),
            trailing: ElevatedButton(
              onPressed: _selectBackupFolder,
              child: const Text('Select'),
            ),
          ),
          // You can add more preference items here if needed.
        ],
      ),
    );
  }
}

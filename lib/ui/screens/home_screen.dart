// lib/ui/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:live_music_metadata_manager/ui/routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Music Metadata Manager'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Live Music Tools',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Folder Standardization'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.pushNamed(context, Routes.folderStandardization);
              },
            ),
            ListTile(
              leading: const Icon(Icons.music_note),
              title: const Text('Media Conversion'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.pushNamed(context, Routes.mediaConversion);
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.folder),
              label: const Text('Folder Standardization'),
              onPressed: () {
                Navigator.pushNamed(context, Routes.folderStandardization);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.music_note),
              label: const Text('Media Conversion'),
              onPressed: () {
                Navigator.pushNamed(context, Routes.mediaConversion);
              },
            ),
          ],
        ),
      ),
    );
  }
}
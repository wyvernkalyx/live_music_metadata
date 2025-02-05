// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Where is your AppState file?
import 'package:live_music_metadata_manager/app_state.dart';
// or maybe 'package:live_music_metadata_manager/core/app_state.dart';
import 'package:live_music_metadata_manager/ui/screens/preferences_screen.dart';

import 'package:live_music_metadata_manager/ui/screens/folder_normalization_screen.dart';
import 'package:live_music_metadata_manager/ui/screens/media_conversion_screen.dart';

import 'package:live_music_metadata_manager/core/models/artist_configuration.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Music Metadata Manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  ArtistConfiguration get defaultArtistConfig => ArtistConfiguration(
        name: 'Grateful Dead',
        folderPrefix: 'gd',
      );

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
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Live Music Tools',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Folder Normalization'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FolderNormalizationScreen(
                      artistConfig: defaultArtistConfig,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.music_note),
              title: const Text('Convert Media to FLAC'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MediaConversionScreen(
                      artistConfig: defaultArtistConfig,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Preferences'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PreferencesScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Welcome! Choose a feature below:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // You can still have buttons here if desired.
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FolderNormalizationScreen(
                      artistConfig: defaultArtistConfig,
                    ),
                  ),
                );
              },
              child: const Text('Folder Normalization'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MediaConversionScreen(
                      artistConfig: defaultArtistConfig,
                    ),
                  ),
                );
              },
              child: const Text('Convert Media to FLAC'),
            ),
          ],
        ),
      ),
    );
  }
}

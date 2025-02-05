// lib/ui/routes.dart
import 'package:flutter/material.dart';
import 'package:live_music_metadata_manager/ui/screens/folder_normalization_screen.dart';
import 'package:live_music_metadata_manager/ui/screens/home_screen.dart';
import 'package:live_music_metadata_manager/ui/screens/media_conversion_screen.dart';
import 'package:live_music_metadata_manager/ui/screens/preferences_screen.dart';

class Routes {
  static const String home = '/';
  static const String preferences = '/preferences';
  static const String folderNormalization = '/folder-standardization';
  static const String mediaConversion = '/media-conversion';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case preferences:
        return MaterialPageRoute(builder: (_) => const PreferencesScreen());
      case folderNormalization:
        return MaterialPageRoute(builder: (_) => const FolderNormalizationScreen());
      case mediaConversion:
        return MaterialPageRoute(builder: (_) => const MediaConversionScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
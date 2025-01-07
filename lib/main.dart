import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:live_music_metadata_manager/core/app_state.dart';
import 'package:live_music_metadata_manager/ui/routes.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Music Metadata Manager',
      theme: ThemeData.dark(), // Set dark theme
      initialRoute: Routes.home,
      onGenerateRoute: Routes.generateRoute,
    );
  }
}
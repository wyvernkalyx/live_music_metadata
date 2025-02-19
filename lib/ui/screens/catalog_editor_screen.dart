// File: lib/ui/screens/catalog_editor_screen.dart

import 'package:flutter/material.dart';
import 'package:live_music_metadata_manager/core/models/concert_release.dart';
import 'package:live_music_metadata_manager/utils/catalog_storage.dart';
import 'package:live_music_metadata_manager/utils/metadata_computation.dart';
import 'package:live_music_metadata_manager/services/logger_service.dart';

class CatalogEditorScreen extends StatefulWidget {
  const CatalogEditorScreen({super.key});

  @override
  _CatalogEditorScreenState createState() => _CatalogEditorScreenState();
}

class _CatalogEditorScreenState extends State<CatalogEditorScreen> {
  bool _isLoading = true;
  List<ConcertRelease> _releases = [];

  @override
  void initState() {
    super.initState();
    _loadReleases();
  }

  Future<List<ConcertRelease>> loadCatalog() async {
    LoggerService.instance.info('Loading catalog...');
    return await CatalogStorage.loadCatalog();
  }

  Future<void> _loadReleases() async {
    try {
      final loaded = await loadCatalog();
      setState(() {
        _releases = loaded;
        _isLoading = false;
      });
      LoggerService.instance.info('Loaded ${loaded.length} releases');
    } catch (e, stackTrace) {
      LoggerService.instance.error('Error loading releases', e, stackTrace);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog Editor'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _releases.length,
              itemBuilder: (context, index) {
                final r = _releases[index];
                return ListTile(
                  title: Text(r.albumTitle, style: TextStyle(color: Colors.white)),
                  subtitle: Text('${r.concertDate} – ${r.venueName}', style: TextStyle(color: Colors.grey)),
                  trailing: r.locked ? const Icon(Icons.lock, color: Colors.red) : const Icon(Icons.edit, color: Colors.green),
                  onTap: () {
                    // Possibly navigate to a detail screen.
                  },
                );
              },
            ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/models/concert_release.dart';
import '../../services/logger_service.dart';
import '../../services/file_operations_service.dart';
import '../../services/metadata_operations_service.dart';
import '../../services/preferences_service.dart';
import '../../services/flac_utils.dart';
import '../widgets/album_art_widget.dart';
import '../widgets/album_info_widget.dart';
import '../widgets/batch_operations_widget.dart';
import '../widgets/song_grid_widget.dart';

class MetadataEditorScreen extends StatefulWidget {
  const MetadataEditorScreen({super.key});

  @override
  State<MetadataEditorScreen> createState() => _MetadataEditorScreenState();
}

class _MetadataEditorScreenState extends State<MetadataEditorScreen> {
  String? mediaFolderPath;
  String? errorMessage;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  ConcertRelease? catalogRelease;
  String _currentArtist = "Grateful Dead"; // Default artist

  @override
  void initState() {
    super.initState();
    _loadDefaultFolder();
  }

  Future<void> _loadDefaultFolder() async {
    final defaultFolder = await PreferencesService.instance.getDefaultMediaFolder();
    if (defaultFolder != null && defaultFolder.isNotEmpty) {
      setState(() {
        mediaFolderPath = defaultFolder;
      });
      await _loadMediaFiles();
    }
  }

  Future<void> _selectFolder() async {
    setState(() => _isLoading = true);
    try {
      final selectedDirectory = await FileOperationsService.instance.selectMediaFolder();
      if (selectedDirectory == null) {
        setState(() => _isLoading = false);
        return;
      }
      setState(() {
        mediaFolderPath = selectedDirectory;
        errorMessage = null;
      });
      await _loadMediaFiles();
    } catch (e) {
      setState(() {
        errorMessage = 'Error selecting folder: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMediaFiles() async {
    if (mediaFolderPath == null) return;
    setState(() {
      _isLoading = true;
      errorMessage = null;
    });
    try {
      final files = await FlacUtils.instance.findFlacFiles(mediaFolderPath!);
      if (files.isEmpty) {
        setState(() {
          errorMessage = 'No FLAC files found in the selected directory';
          _isLoading = false;
        });
        return;
      }
      final release = await MetadataOperationsService.instance.createReleaseFromFiles(
        files,
        mediaFolderPath!,
        _currentArtist,
      );
      setState(() {
        catalogRelease = release;
        _isLoading = false;
        _hasUnsavedChanges = true;
      });
    } catch (e, stack) {
      LoggerService.instance.error('Error loading media files', e, stack);
      setState(() {
        errorMessage = 'Error loading files: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCatalog() async {
    try {
      final loadedRelease = await FileOperationsService.instance.loadCatalog();
      if (loadedRelease != null) {
        setState(() {
          catalogRelease = loadedRelease;
          _hasUnsavedChanges = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catalog loaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading catalog: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveCatalog() async {
    if (catalogRelease == null) return;
    setState(() => _isSaving = true);
    try {
      // Overwrite album title with the assembled title (including notes)
      final updatedRelease = catalogRelease!.copyWith(
        albumTitle: catalogRelease!.generateAlbumTitle(includeNotes: true),
      );
      await FileOperationsService.instance.saveCatalog(updatedRelease, _currentArtist);
      setState(() {
        catalogRelease = updatedRelease;
        _hasUnsavedChanges = false;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catalog saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Error saving catalog: $e';
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving catalog: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveToMedia() async {
    if (catalogRelease == null) return;
    try {
      if (catalogRelease?.mediaFolderPath != null) {
        await MetadataOperationsService.instance.saveMetadata(
          release: catalogRelease!,
          mediaFolderPath: catalogRelease!.mediaFolderPath!,
          artistName: _currentArtist,
        );
      } else {
        throw Exception('Media folder path is missing');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully saved changes to media files'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving to media: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _selectFolder,
            icon: const Icon(Icons.folder_open),
            label: const Text('Select Media Folder'),
          ),
          ElevatedButton.icon(
            onPressed: _loadCatalog,
            icon: const Icon(Icons.file_open),
            label: const Text('Load Catalog'),
          ),
          ElevatedButton.icon(
            onPressed: _saveCatalog,
            icon: const Icon(Icons.save),
            label: const Text('Save to Catalog'),
          ),
          ElevatedButton.icon(
            onPressed: _saveToMedia,
            icon: const Icon(Icons.save_alt),
            label: const Text('Save to Media Files'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Album Metadata'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      bottomNavigationBar: _buildActionBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (mediaFolderPath != null) ...[
                    Text(
                      'Media Folder: $mediaFolderPath',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (catalogRelease != null) ...[
                    // Album Art Widget
                    AlbumArtWidget(
                      albumArtPath: catalogRelease!.albumArtPath,
                      artist: catalogRelease!.artist,
                      date: catalogRelease!.date,
                      release: catalogRelease!,
                      onArtSelected: (path) {
                        setState(() {
                          catalogRelease = catalogRelease!.copyWith(
                            albumArtPath: path,
                            useStockArt: false,
                            stockArtFileName: null,
                          );
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Album Info Widget (ensure this widget no longer displays album art)
                    AlbumInfoWidget(
                      mediaRelease: catalogRelease!,
                      catalogRelease: catalogRelease,
                      onCatalogChanged: (release) {
                        // Ensure album title includes notes when updating
                        final updatedRelease = release.copyWith(
                          albumTitle: release.generateAlbumTitle(includeNotes: true),
                        );
                        setState(() {
                          catalogRelease = updatedRelease;
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Batch Operations Widget
                    BatchOperationsWidget(
                      release: catalogRelease!,
                      onReleaseChanged: (release) {
                        // Ensure album title includes notes when updating from batch operations
                        final updatedRelease = release.copyWith(
                          albumTitle: release.generateAlbumTitle(includeNotes: true),
                        );
                        setState(() {
                          catalogRelease = updatedRelease;
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Song Grid Widget
                    SongGridWidget(
                      release: catalogRelease!,
                      onReleaseChanged: (release) {
                        // Ensure album title includes notes when updating from song grid
                        final updatedRelease = release.copyWith(
                          albumTitle: release.generateAlbumTitle(includeNotes: true),
                        );
                        setState(() {
                          catalogRelease = updatedRelease;
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

// Lines 1-8: Imports
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io'; // Needed for File operations
import 'package:live_music_metadata_manager/core/models/media_models.dart';
import 'package:live_music_metadata_manager/core/services/media_file_service.dart';
import 'package:live_music_metadata_manager/core/models/artist_configuration.dart';
import 'package:live_music_metadata_manager/core/models/conversion_metadata.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import the dialog we just created
import 'folder_metadata_edit_dialog.dart';

// Line 14: MediaConversionScreen Widget Declaration
class MediaConversionScreen extends StatefulWidget {
  final ArtistConfiguration? artistConfig;

  const MediaConversionScreen({Key? key, this.artistConfig}) : super(key: key);

  @override
  State<MediaConversionScreen> createState() => _MediaConversionScreenState();
}

// Line 22: State class starts
class _MediaConversionScreenState extends State<MediaConversionScreen> {
  String? selectedDirectory;
  List<FolderWithMedia> foldersWithMedia = [];
  bool isScanning = false;
  bool isConverting = false;

  // For each folder, store folder-level metadata (folderPath -> FolderLevelMetadata)
  final Map<String, FolderLevelMetadata> folderMetadataMap = {};

  // Line ~32: _pickDirectory method
  Future<void> _pickDirectory() async {
    final folder = await FilePicker.platform.getDirectoryPath();
    if (folder == null) return;

    setState(() {
      selectedDirectory = folder;
      isScanning = true;
      foldersWithMedia.clear();
      folderMetadataMap.clear();
    });

    try {
      final service = MediaFileService(folder);
      final found = service.findNonFlacFolders();
      setState(() {
        foldersWithMedia = found;
      });

      // Initialize default metadata for each folder
      for (final f in found) {
        folderMetadataMap[f.folderPath] = FolderLevelMetadata(
          artist: widget.artistConfig?.name ?? '',
          venue: '',
          source: '',
          taper: '',
          createBackup: true,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning directory: $e')),
      );
    } finally {
      setState(() {
        isScanning = false;
      });
    }
  }

  // Line ~55: _toggleFolderSelection
  void _toggleFolderSelection(FolderWithMedia folder, bool? selected) {
    setState(() {
      if (selected == true) {
        for (final file in folder.mediaFiles) {
          file.isSelected = true;
        }
      } else {
        for (final file in folder.mediaFiles) {
          file.isSelected = false;
        }
      }
    });
  }

  // Line ~65: _isFolderSelected
  bool _isFolderSelected(FolderWithMedia folder) {
    return folder.mediaFiles.every((f) => f.isSelected);
  }

  // Line ~70: _editFolderMetadata
  Future<void> _editFolderMetadata(FolderWithMedia folder) async {
    final currentMeta = folderMetadataMap[folder.folderPath];
    if (currentMeta == null) return;

    final updated = await showDialog<FolderLevelMetadata>(
      context: context,
      builder: (_) => FolderMetadataEditDialog(
        initialMetadata: currentMeta,
        folderName: folder.folderName,
      ),
    );

    if (updated != null) {
      setState(() {
        folderMetadataMap[folder.folderPath] = updated;
      });
    }
  }

  // Line ~80: _startConversion method
  Future<void> _startConversion() async {
    if (foldersWithMedia.isEmpty || selectedDirectory == null) return;

    final allSelectedFiles = <MediaFile>[];
    for (final folder in foldersWithMedia) {
      final selectedFiles = folder.mediaFiles.where((f) => f.isSelected).toList();
      allSelectedFiles.addAll(selectedFiles);
    }

    if (allSelectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No files selected for conversion.')),
      );
      return;
    }

    setState(() {
      isConverting = true;
    });

    try {
      // Process each folder that has selected files...
      for (final folder in foldersWithMedia) {
        final selectedFiles = folder.mediaFiles.where((f) => f.isSelected).toList();
        if (selectedFiles.isEmpty) continue;
        final meta = folderMetadataMap[folder.folderPath];
        if (meta == null) continue;

        // Backup folder selection logic (Line ~95)
        String? folderBackupPath;
        if (meta.createBackup) {
          final prefs = await SharedPreferences.getInstance();
          folderBackupPath = prefs.getString('backup_folder');
          if (folderBackupPath?.isEmpty ?? true) {
            folderBackupPath = await _pickBackupDirectory(folder.folderPath);
          }
        }

        // Build final metadata (cMeta) for this folder (Line ~105)
        final cMeta = ConversionMetadata(
          artist: meta.artist,
          date: DateTime.now().toString(),
          venue: meta.venue,
          source: meta.source,
          taper: meta.taper,
          createBackup: meta.createBackup,
          backupPath: folderBackupPath,
        );

        // Create a new MediaFileService instance for the current folder. (Line ~112)
        final folderService = MediaFileService(folder.folderPath);

        // If backup is enabled, back up only this folder.
        if (cMeta.createBackup && cMeta.backupPath != null && cMeta.backupPath!.isNotEmpty) {
          await folderService.createBackup(folder.folderPath, cMeta.backupPath!);
        }

        // Then, convert each file individually (Line ~119)
        for (final file in selectedFiles) {
          try {
            final outputPath = file.path.replaceAll(file.extension, '.flac');
            // Use a public conversion method; ensure this is defined in MediaFileService.
            await folderService.convertFile(file.path, outputPath, cMeta);
            // Delete the original file after successful conversion.
            await File(file.path).delete();
          } catch (e) {
            print('Error converting ${file.fileName}: $e');
            rethrow;
          }
        }
      }

      // Re-scan after conversion.
      final newFolders = MediaFileService(selectedDirectory!).findNonFlacFolders();
      setState(() {
        foldersWithMedia = newFolders;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversion completed successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during conversion: $e')),
      );
    } finally {
      setState(() {
        isConverting = false;
      });
    }
  }

  // Line ~135: _pickBackupDirectory
  Future<String?> _pickBackupDirectory(String folderPath) async {
    return FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pick Backup Folder for $folderPath',
    );
  }

  // Line ~140: build() method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Conversion'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: Text(isScanning ? 'Scanning...' : 'Select Folder'),
              onPressed: isScanning ? null : _pickDirectory,
            ),
          ),
          if (selectedDirectory != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text('Selected: $selectedDirectory'),
            ),
          if (isScanning) const LinearProgressIndicator(),
          if (!isScanning && foldersWithMedia.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: foldersWithMedia.length,
                itemBuilder: (context, index) {
                  final folder = foldersWithMedia[index];
                  final folderSelected = _isFolderSelected(folder);
                  return Card(
                    child: ExpansionTile(
                      leading: Checkbox(
                        value: folderSelected,
                        onChanged: (val) => _toggleFolderSelection(folder, val),
                      ),
                      title: Text(folder.folderName),
                      subtitle: Text('${folder.mediaFiles.length} files'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editFolderMetadata(folder),
                      ),
                      children: folder.mediaFiles.map((file) {
                        return CheckboxListTile(
                          title: Text(file.fileName),
                          value: file.isSelected,
                          onChanged: (val) {
                            setState(() {
                              file.isSelected = val ?? false;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          if (!isScanning && foldersWithMedia.isEmpty && selectedDirectory != null)
            const Expanded(
              child: Center(child: Text('No non-FLAC files found.')),
            ),
          if (!isScanning && foldersWithMedia.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                icon: Icon(isConverting ? Icons.hourglass_empty : Icons.music_note),
                label: Text(isConverting ? 'Converting...' : 'Convert Selected to FLAC'),
                onPressed: isConverting ? null : _startConversion,
              ),
            ),
          if (isConverting) const LinearProgressIndicator(),
        ],
      ),
    );
  }
} // End of _MediaConversionScreenState class

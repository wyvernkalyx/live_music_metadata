// lib/ui/screens/media_conversion_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:live_music_metadata_manager/core/services/media_file_service.dart';
import 'package:live_music_metadata_manager/core/models/media_models.dart';

class MediaConversionScreen extends StatefulWidget {
  const MediaConversionScreen({Key? key}) : super(key: key);

  @override
  State<MediaConversionScreen> createState() => _MediaConversionScreenState();
}

class _MediaConversionScreenState extends State<MediaConversionScreen> {
  List<FolderWithMedia> foldersWithMedia = [];
  bool isScanning = false;
  bool isConverting = false;
  String? selectedDirectory;
  Set<String> selectedFolders = {};

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 32), // Checkbox space
          Expanded(
            flex: 4,
            child: Text(
              'Folder Name',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Files',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Types',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _getUniqueFileTypes(List<MediaFile> files) {
    final types = files.map((f) => f.extension.replaceFirst('.', '')).toSet();
    return types.join(', ');
  }

  String _removeExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot != -1) {
      return fileName.substring(0, lastDot);
    }
    return fileName;
  }

  bool _isFolderSelected(String folderPath) {
    return selectedFolders.contains(folderPath);
  }

  void _toggleFolderSelection(FolderWithMedia folder, bool? selected) {
    setState(() {
      if (selected ?? false) {
        selectedFolders.add(folder.folderPath);
        // Select all files in the folder
        for (var file in folder.mediaFiles) {
          file.isSelected = true;
        }
      } else {
        selectedFolders.remove(folder.folderPath);
        // Deselect all files in the folder
        for (var file in folder.mediaFiles) {
          file.isSelected = false;
        }
      }
    });
  }

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
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isScanning ? null : () async {
                      String? directory = await FilePicker.platform.getDirectoryPath();
                      if (directory != null) {
                        setState(() {
                          isScanning = true;
                          selectedDirectory = directory;
                          selectedFolders.clear(); // Clear selections when new folder is picked
                        });

                        try {
                          final service = MediaFileService(directory);
                          final folders = service.findNonFlacFolders();
                          setState(() {
                            foldersWithMedia = folders;
                          });
                        } finally {
                          setState(() {
                            isScanning = false;
                          });
                        }
                      }
                    },
                    icon: const Icon(Icons.folder_open),
                    label: Text(isScanning ? 'Scanning...' : 'Select Folder'),
                  ),
                ),
              ],
            ),
          ),
          if (selectedDirectory != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text(
                'Selected: $selectedDirectory',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (isScanning) const LinearProgressIndicator(),
          if (!isScanning && foldersWithMedia.isEmpty && selectedDirectory != null)
            const Expanded(
              child: Center(
                child: Text('No convertible media files found'),
              ),
            ),
          if (!isScanning && foldersWithMedia.isNotEmpty) ...[
            _buildHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: foldersWithMedia.length,
                itemBuilder: (context, index) {
                  final folder = foldersWithMedia[index];
                  return ExpansionTile(
                    leading: Checkbox(
                      value: _isFolderSelected(folder.folderPath),
                      onChanged: (bool? value) {
                        _toggleFolderSelection(folder, value);
                      },
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(folder.folderName),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${folder.mediaFiles.length}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            _getUniqueFileTypes(folder.mediaFiles),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            ...folder.mediaFiles.map((file) => CheckboxListTile(
                              dense: true,
                              title: Text(file.fileName),
                              value: file.isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  file.isSelected = value ?? false;
                                  // Update folder selection state if needed
                                  if (!file.isSelected) {
                                    selectedFolders.remove(folder.folderPath);
                                  }
                                });
                              },
                            )),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
          if (!isScanning && foldersWithMedia.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isConverting
                          ? null
                          : () async {
                              setState(() {
                                isConverting = true;
                              });

                              try {
                                if (foldersWithMedia.isNotEmpty) {
                                  final service = MediaFileService(foldersWithMedia.first.folderPath);
                                  final allSelectedFiles = foldersWithMedia
                                      .expand((folder) => folder.mediaFiles)
                                      .where((file) => file.isSelected)
                                      .toList();

                                  if (allSelectedFiles.isEmpty) {
                                    throw Exception('No files selected for conversion');
                                  }

                                  await service.convertToFlac(allSelectedFiles);
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error during conversion: $e')),
                                );
                              } finally {
                                setState(() {
                                  isConverting = false;
                                });
                              }
                            },
                      icon: Icon(isConverting ? Icons.hourglass_empty : Icons.music_note),
                      label: Text(isConverting ? 'Converting...' : 'Convert Selected to FLAC'),
                    ),
                  ),
                ],
              ),
            ),
          if (isConverting) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
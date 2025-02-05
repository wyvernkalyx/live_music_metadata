// lib/ui/screens/folder_normalization_screen.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:live_music_metadata_manager/core/services/folder_normalization_service.dart';
import 'package:live_music_metadata_manager/core/models/artist_configuration.dart';

class FolderNormalizationScreen extends StatefulWidget {
  final ArtistConfiguration? artistConfig;

  const FolderNormalizationScreen({Key? key, this.artistConfig}) : super(key: key);

  @override
  State<FolderNormalizationScreen> createState() => _FolderNormalizationScreenState();
}

class _FolderNormalizationScreenState extends State<FolderNormalizationScreen> {
  String? selectedDirectory;
  List<(String, String)> invalidFolders = [];
  bool isScanning = false;
  bool isNormalizing = false;

  Future<void> _pickDirectory() async {
    final folder = await FilePicker.platform.getDirectoryPath();
    if (folder == null) return;

    setState(() {
      selectedDirectory = folder;
      invalidFolders.clear();
      isScanning = true;
    });

    await _scanFolders();

    setState(() {
      isScanning = false;
    });
  }

  Future<void> _scanFolders() async {
    if (selectedDirectory == null) return;

    final service = FolderNormalizationService(selectedDirectory!, widget.artistConfig);
    final nonNormalized = service.getNonNormalizedFolders();
    setState(() {
      invalidFolders = nonNormalized;
    });
  }

  Future<void> _normalizeFolders() async {
    if (selectedDirectory == null) return;
    setState(() {
      isNormalizing = true;
    });

    try {
      final service = FolderNormalizationService(selectedDirectory!, widget.artistConfig);
      await service.normalizeFolderNames();
      await _scanFolders(); // re-scan

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Folders normalized successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error normalizing folders: $e')),
      );
    } finally {
      setState(() {
        isNormalizing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folder Normalization'),
      ),
      body: Column(
        children: [
          // Pick directory
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: Text(isScanning ? 'Scanning...' : 'Select Folder'),
              onPressed: isScanning ? null : _pickDirectory,
            ),
          ),

          if (selectedDirectory != null && !isScanning)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Selected: $selectedDirectory'),
            ),

          if (isScanning) const LinearProgressIndicator(),

          // Show invalid (non-normalized) folders
          if (!isScanning && invalidFolders.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: invalidFolders.length,
                itemBuilder: (context, index) {
                  final (orig, suggest) = invalidFolders[index];
                  return ListTile(
                    title: Text('Original: $orig'),
                    subtitle: Text('Suggested: $suggest'),
                  );
                },
              ),
            ),

          if (!isScanning && invalidFolders.isEmpty && selectedDirectory != null)
            const Expanded(
              child: Center(child: Text('No folders to normalize.')),
            ),

          // Normalize button
          if (selectedDirectory != null && invalidFolders.isNotEmpty && !isScanning)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                icon: Icon(isNormalizing ? Icons.hourglass_empty : Icons.build),
                label: Text(isNormalizing ? 'Normalizing...' : 'Normalize Folders'),
                onPressed: isNormalizing ? null : _normalizeFolders,
              ),
            ),

          if (isNormalizing) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}

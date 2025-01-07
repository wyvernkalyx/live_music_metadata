// lib/ui/dialogs/conversion_confirmation_dialog.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:live_music_metadata_manager/core/models/media_models.dart';

class ConversionMetadata {
  String artist;
  String date;
  String venue;
  String source;
  String taper;
  bool createBackup;
  String? backupPath;

  ConversionMetadata({
    required this.artist,
    required this.date,
    this.venue = '',
    this.source = '',
    this.taper = '',
    this.createBackup = true,
    this.backupPath,
  });
}

class ConversionConfirmationDialog extends StatefulWidget {
  final List<MediaFile> filesToConvert;
  final String sourceFolder;

  const ConversionConfirmationDialog({
    Key? key,
    required this.filesToConvert,
    required this.sourceFolder,
  }) : super(key: key);

  @override
  State<ConversionConfirmationDialog> createState() => _ConversionConfirmationDialogState();
}

class _ConversionConfirmationDialogState extends State<ConversionConfirmationDialog> {
  late ConversionMetadata metadata;
  bool isLoadingBackupPath = false;

  @override
  void initState() {
    super.initState();
    metadata = _extractInitialMetadata();
  }

  ConversionMetadata _extractInitialMetadata() {
    // Extract metadata from folder name if it matches the pattern
    final folderName = path.basename(widget.sourceFolder);
    final gdMatch = RegExp(r'Grateful Dead - (\d{4})-(\d{2})-(\d{2})').firstMatch(folderName);
    
    if (gdMatch != null) {
      final date = '${gdMatch[1]}-${gdMatch[2]}-${gdMatch[3]}';
      return ConversionMetadata(
        artist: 'Grateful Dead',
        date: date,
        backupPath: path.join(path.dirname(widget.sourceFolder), 'backup'),
      );
    }

    return ConversionMetadata(
      artist: '',
      date: '',
      backupPath: path.join(path.dirname(widget.sourceFolder), 'backup'),
    );
  }

  Future<void> _selectBackupFolder() async {
    setState(() {
      isLoadingBackupPath = true;
    });

    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Backup Location',
      );

      if (selectedDirectory != null) {
        setState(() {
          metadata.backupPath = selectedDirectory;
        });
      }
    } finally {
      setState(() {
        isLoadingBackupPath = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Conversion'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.filesToConvert.length} files selected for conversion:'),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 100),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.filesToConvert.length,
                itemBuilder: (context, index) {
                  return Text(
                    widget.filesToConvert[index].fileName,
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
              ),
            ),
            const Divider(),
            const Text('Metadata for FLAC files:'),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Artist'),
              controller: TextEditingController(text: metadata.artist),
              onChanged: (value) => metadata.artist = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
              controller: TextEditingController(text: metadata.date),
              onChanged: (value) => metadata.date = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Venue'),
              controller: TextEditingController(text: metadata.venue),
              onChanged: (value) => metadata.venue = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Source'),
              controller: TextEditingController(text: metadata.source),
              onChanged: (value) => metadata.source = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Taper'),
              controller: TextEditingController(text: metadata.taper),
              onChanged: (value) => metadata.taper = value,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Create Backup'),
              value: metadata.createBackup,
              onChanged: (bool? value) {
                setState(() {
                  metadata.createBackup = value ?? true;
                });
              },
            ),
            if (metadata.createBackup) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Backup location: ${metadata.backupPath ?? "Not selected"}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: isLoadingBackupPath ? null : _selectBackupFolder,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Validate inputs
            if (metadata.artist.isEmpty || metadata.date.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Artist and Date are required'),
                ),
              );
              return;
            }

            if (metadata.createBackup && (metadata.backupPath?.isEmpty ?? true)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select a backup location'),
                ),
              );
              return;
            }

            Navigator.of(context).pop(metadata);
          },
          child: const Text('Start Conversion'),
        ),
      ],
    );
  }
}
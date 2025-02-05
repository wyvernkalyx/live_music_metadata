// lib/ui/screens/folder_metadata_edit_dialog.dart

import 'package:flutter/material.dart';

/// A simple class that holds folder-level metadata (artist, venue, etc.)
class FolderLevelMetadata {
  String artist;
  String venue;
  String source;
  String taper;
  bool createBackup;

  FolderLevelMetadata({
    required this.artist,
    required this.venue,
    required this.source,
    required this.taper,
    required this.createBackup,
  });
}

class FolderMetadataEditDialog extends StatefulWidget {
  final FolderLevelMetadata initialMetadata;
  final String folderName;

  const FolderMetadataEditDialog({
    Key? key,
    required this.initialMetadata,
    required this.folderName,
  }) : super(key: key);

  @override
  State<FolderMetadataEditDialog> createState() =>
      _FolderMetadataEditDialogState();
}

class _FolderMetadataEditDialogState extends State<FolderMetadataEditDialog> {
  late TextEditingController _artistController;
  late TextEditingController _venueController;
  late TextEditingController _sourceController;
  late TextEditingController _taperController;
  bool _createBackup = false;

  @override
  void initState() {
    super.initState();
    _artistController = TextEditingController(text: widget.initialMetadata.artist);
    _venueController = TextEditingController(text: widget.initialMetadata.venue);
    _sourceController = TextEditingController(text: widget.initialMetadata.source);
    _taperController = TextEditingController(text: widget.initialMetadata.taper);
    _createBackup = widget.initialMetadata.createBackup;
  }

  @override
  void dispose() {
    _artistController.dispose();
    _venueController.dispose();
    _sourceController.dispose();
    _taperController.dispose();
    super.dispose();
  }

  void _onSave() {
    final updated = FolderLevelMetadata(
      artist: _artistController.text.trim(),
      venue: _venueController.text.trim(),
      source: _sourceController.text.trim(),
      taper: _taperController.text.trim(),
      createBackup: _createBackup,
    );
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Metadata for Folder: ${widget.folderName}'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _artistController,
              decoration: const InputDecoration(labelText: 'Artist'),
            ),
            TextField(
              controller: _venueController,
              decoration: const InputDecoration(labelText: 'Venue'),
            ),
            TextField(
              controller: _sourceController,
              decoration: const InputDecoration(labelText: 'Source'),
            ),
            TextField(
              controller: _taperController,
              decoration: const InputDecoration(labelText: 'Taper'),
            ),
            Row(
              children: [
                Checkbox(
                  value: _createBackup,
                  onChanged: (val) => setState(() => _createBackup = val ?? false),
                ),
                const Text('Create Backup'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _onSave,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

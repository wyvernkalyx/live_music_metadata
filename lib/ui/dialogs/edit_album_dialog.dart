import 'package:flutter/material.dart';
import 'package:live_music_metadata_manager/core/models/concert_release.dart';
import '../widgets/album_art_widget.dart';

class EditAlbumDialog extends StatefulWidget {
  final ConcertRelease release;

  const EditAlbumDialog({super.key, required this.release});

  @override
  State<EditAlbumDialog> createState() => _EditAlbumDialogState();
}

class _EditAlbumDialogState extends State<EditAlbumDialog> {
  late TextEditingController _dateController;
  late TextEditingController _venueController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _collectionController;
  late TextEditingController _volumeController;
  late TextEditingController _notesController;
  late ConcertRelease _release;

  @override
  void initState() {
    super.initState();
    _release = widget.release;
    _dateController = TextEditingController(text: _release.date);
    _venueController = TextEditingController(text: _release.venueName);
    _cityController = TextEditingController(text: _release.city);
    _stateController = TextEditingController(text: _release.state);
    _collectionController = TextEditingController(text: _release.collection);
    _volumeController = TextEditingController(text: _release.volume);
    _notesController = TextEditingController(text: _release.notes);

    // Add listeners to update title when fields change
    _dateController.addListener(_updateTitle);
    _venueController.addListener(_updateTitle);
    _cityController.addListener(_updateTitle);
    _stateController.addListener(_updateTitle);
    _collectionController.addListener(_updateTitle);
    _volumeController.addListener(_updateTitle);
  }

  void _updateTitle() {
    setState(() {
      _release = _release.copyWith(
        date: _dateController.text,
        venueName: _venueController.text,
        city: _cityController.text,
        state: _stateController.text.toUpperCase(),
        collection: _collectionController.text,
        volume: _volumeController.text,
        notes: _notesController.text,
        albumTitle: _release.generateAlbumTitle(),
      );
    });
  }

  @override
  void dispose() {
    // Remove listeners
    _dateController.removeListener(_updateTitle);
    _venueController.removeListener(_updateTitle);
    _cityController.removeListener(_updateTitle);
    _stateController.removeListener(_updateTitle);
    _collectionController.removeListener(_updateTitle);
    _volumeController.removeListener(_updateTitle);

    // Dispose controllers
    _dateController.dispose();
    _venueController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _collectionController.dispose();
    _volumeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Album Metadata'),
      content: SizedBox(
        width: 600,  // Set a fixed width for the dialog
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Album Art Section
              AlbumArtWidget(
                albumArtPath: _release.albumArtPath,
                artist: _release.artist,
                date: _release.date,
                release: _release,
                onArtSelected: (path) {
                  setState(() {
                    _release = _release.copyWith(
                      albumArtPath: path,
                      useStockArt: false,
                      stockArtFileName: null,
                    );
                  });
                },
              ),
              const SizedBox(height: 16),
              // Album Info Section
              // Two columns for metadata fields
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: _dateController,
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            helperText: 'Format: YYYY-MM-DD',
                          ),
                        ),
                        TextField(
                          controller: _venueController,
                          decoration: const InputDecoration(labelText: 'Venue'),
                        ),
                        TextField(
                          controller: _cityController,
                          decoration: const InputDecoration(labelText: 'City'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right column
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: _stateController,
                          decoration: const InputDecoration(
                            labelText: 'State',
                            helperText: 'Two-letter code (e.g., CA)',
                          ),
                          onChanged: (value) {
                            final state = value.toUpperCase();
                            if (state.length == 2) {
                              _stateController.text = state;
                              _stateController.selection = TextSelection.fromPosition(
                                TextPosition(offset: state.length),
                              );
                            }
                          },
                        ),
                        TextField(
                          controller: _collectionController,
                          decoration: const InputDecoration(labelText: 'Collection'),
                        ),
                        TextField(
                          controller: _volumeController,
                          decoration: const InputDecoration(labelText: 'Volume'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Notes field spans both columns
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final updatedRelease = _release.copyWith(
              date: _dateController.text,
              venueName: _venueController.text,
              city: _cityController.text,
              state: _stateController.text.toUpperCase(),
              collection: _collectionController.text,
              volume: _volumeController.text,
              notes: _notesController.text,
              isModified: true,
            );
            Navigator.of(context).pop(updatedRelease);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

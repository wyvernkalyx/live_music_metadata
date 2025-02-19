// File: lib/ui/dialogs/edit_song_dialog.dart

import 'package:flutter/material.dart';
import 'package:live_music_metadata_manager/core/models/song.dart';

class EditSongDialog extends StatefulWidget {
  final Song song;
  final Song? mediaSong;
  final String date;

  const EditSongDialog({
    Key? key,
    required this.song,
    required this.date,
    this.mediaSong,
  }) : super(key: key);

  @override
  State<EditSongDialog> createState() => _EditSongDialogState();
}

class _EditSongDialogState extends State<EditSongDialog> {
  late TextEditingController _titleController;
  late TextEditingController _trackController;
  late TextEditingController _dateController;
  late bool _transition;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song.title);
    _trackController = TextEditingController(text: widget.song.trackNumber.toString());
    _dateController = TextEditingController(text: widget.date);
    _transition = widget.song.transition;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _trackController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Song'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _trackController,
              decoration: const InputDecoration(labelText: 'Track Number'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Date (YYYY-MM-DD)',
                hintText: 'Optional',
              ),
            ),
            CheckboxListTile(
              title: const Text('Transition'),
              value: _transition,
              onChanged: (bool? value) {
                setState(() {
                  _transition = value ?? false;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop({
              'trackNumber': int.tryParse(_trackController.text) ?? widget.song.trackNumber,
              'title': _titleController.text,
              'date': _dateController.text.isNotEmpty ? _dateController.text : null,
              'transition': _transition,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

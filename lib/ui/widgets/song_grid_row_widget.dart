import 'package:flutter/material.dart';
import '../../core/models/song.dart';

class SongGridRowWidget extends StatelessWidget {
  final Song song;
  final Song? mediaSong;
  final String concertDate;
  final ValueChanged<int> onTrackNumberChanged;
  final ValueChanged<String> onNormalizedTitleChanged;
  final VoidCallback onLookupTitle;
  final ValueChanged<String> onDateChanged;
  final ValueChanged<bool?> onTransitionChanged;
  final VoidCallback onSaveToMedia;

  const SongGridRowWidget({
    super.key,
    required this.song,
    this.mediaSong,
    required this.concertDate,
    required this.onTrackNumberChanged,
    required this.onNormalizedTitleChanged,
    required this.onLookupTitle,
    required this.onDateChanged,
    required this.onTransitionChanged,
    required this.onSaveToMedia,
  });

  String _getMatchStatusMessage() {
    final List<String> mismatches = [];
    
    if (song.mediaTitle != null && song.mediaTitle != song.title) {
      mismatches.add('Title mismatch:\nMedia: ${song.mediaTitle}\nCatalog: ${song.title}');
    }
    
    if (song.mediaTrackNumber != null && song.mediaTrackNumber != song.trackNumber.toString()) {
      mismatches.add('Track number mismatch:\nMedia: ${song.mediaTrackNumber}\nCatalog: ${song.trackNumber}');
    }
    
    if (song.mediaDate != null && song.mediaDate != song.date) {
      mismatches.add('Date mismatch:\nMedia: ${song.mediaDate}\nCatalog: ${song.date}');
    }
    
    if (!song.isMatched!) {
      mismatches.add('Title not found in official song list');
    }
    
    return mismatches.isEmpty ? 'No mismatches found' : mismatches.join('\n\n');
  }

  Color _getMatchColor() {
    return song.isMatched == true
        ? Colors.green
        : song.hasMediaChanges
            ? Colors.orange
            : Colors.red;
  }

  List<DataCell> _buildCells() {
    return [
      // Track Number
      DataCell(
        TextFormField(
          initialValue: song.trackNumber.toString(),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          onFieldSubmitted: (value) {
            final number = int.tryParse(value);
            if (number != null) {
              onTrackNumberChanged(number);
            }
          },
        ),
      ),
      // Original Title
      DataCell(Text(song.originalTitle ?? song.title)),
      // Normalized Title
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: TextFormField(
                initialValue: song.normalizedTitle ?? song.title,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onFieldSubmitted: onNormalizedTitleChanged,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Find matching song',
              onPressed: onLookupTitle,
            ),
          ],
        ),
      ),
      // Date
      DataCell(
        TextFormField(
          initialValue: song.date ?? concertDate,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          onChanged: onDateChanged,
        ),
      ),
      // Length
      DataCell(Text(song.length?.isNotEmpty == true ? song.length! :
                    mediaSong?.mediaMetadata?['LENGTH']?.toString() ??
                    mediaSong?.mediaMetadata?['DURATION']?.toString() ??
                    '0:00')),
      // Match Status
      DataCell(
        Tooltip(
          message: _getMatchStatusMessage(),
          child: Icon(Icons.circle, color: _getMatchColor(), size: 16),
        ),
      ),
      // Transition
      DataCell(Checkbox(
        value: song.transition,
        onChanged: onTransitionChanged,
      )),
      // Assembled Title
      DataCell(Text(song.assembledTitle(song.date ?? concertDate))),
      // Actions
      DataCell(
        IconButton(
          icon: const Icon(Icons.save),
          tooltip: 'Save changes to media file',
          onPressed: onSaveToMedia,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Track #')),
          DataColumn(label: Text('Original Title')),
          DataColumn(label: Text('Normalized Title')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Length')),
          DataColumn(label: Text('Match Status')),
          DataColumn(label: Text('Transition')),
          DataColumn(label: Text('Assembled Title')),
          DataColumn(label: Text('Actions')),
        ],
        rows: [
          DataRow(cells: _buildCells()),
        ],
      ),
    );
  }
}
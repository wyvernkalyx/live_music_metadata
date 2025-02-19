import 'package:flutter/material.dart';
import '../../core/models/concert_release.dart';
import '../../core/models/concert_set.dart';
import '../../core/models/song.dart';
import '../../services/gd_song_matcher.dart';
import '../dialogs/song_lookup_dialog.dart';
import '../../services/logger_service.dart';

class SongGridWidget extends StatefulWidget {
  final ConcertRelease release;
  final Function(ConcertRelease) onReleaseChanged;

  const SongGridWidget({
    Key? key,
    required this.release,
    required this.onReleaseChanged,
  }) : super(key: key);

  @override
  State<SongGridWidget> createState() => _SongGridWidgetState();
}

class _SongGridWidgetState extends State<SongGridWidget> {
  int? _sortColumnIndex;
  bool _sortAscending = true;

  void _renumberTracks() {
    // Create a new list of sets to modify
    final updatedSets = List<ConcertSet>.from(widget.release.setlist);
    
    // Update track numbers
    for (var setIndex = 0; setIndex < updatedSets.length; setIndex++) {
      final set = updatedSets[setIndex];
      final updatedSongs = List<Song>.from(set.songs);
      
      for (var songIndex = 0; songIndex < updatedSongs.length; songIndex++) {
        final newTrackNumber = (setIndex + 1) * 100 + songIndex + 1;
        updatedSongs[songIndex] = updatedSongs[songIndex].copyWith(
          trackNumber: newTrackNumber,
          hasMediaChanges: true,
        );
      }
      
      updatedSets[setIndex] = set.copyWith(songs: updatedSongs);
    }
    
    // Update the release with new track numbers
    final updatedRelease = widget.release.copyWith(setlist: updatedSets);
    
    setState(() {
      // Update UI and notify parent
      widget.onReleaseChanged(updatedRelease);
      
      // Set sorting to track number ascending
      _sortColumnIndex = 0;
      _sortAscending = true;
    });
  }

  void _sort<T>(Comparable<T> Function(Song s) getField, int columnIndex, bool ascending) {
    for (var set in widget.release.setlist) {
      set.songs.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);
        return ascending ? Comparable.compare(aValue, bValue) : Comparable.compare(bValue, aValue);
      });
    }
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
    widget.onReleaseChanged(widget.release);
  }

  String _getMatchStatusMessage(Song song) {
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

  Color _getMatchColor(Song song) {
    return song.isMatched == true
        ? Colors.green
        : song.hasMediaChanges
            ? Colors.orange
            : Colors.red;
  }

  void _updateSong(int setIndex, int songIndex, Song updatedSong) {
    final updatedSets = List<ConcertSet>.from(widget.release.setlist);
    updatedSets[setIndex] = updatedSets[setIndex].copyWith(
      songs: List<Song>.from(updatedSets[setIndex].songs)
        ..[songIndex] = updatedSong,
    );
    widget.onReleaseChanged(widget.release.copyWith(setlist: updatedSets));
  }

  Future<void> _lookupTitle(BuildContext context, int setIndex, int songIndex) async {
    final song = widget.release.setlist[setIndex].songs[songIndex];
    final currentTitle = song.originalTitle ?? song.title;
    
    // Clean the title by removing the date
    final cleanTitle = currentTitle
        .replaceAll(RegExp(r'\[\d{4}-\d{2}-\d{2}\]'), '')
        .trim();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SongLookupDialog(
        currentTitle: cleanTitle,
        onSearch: (query) => GdSongMatcher().findSimilarTitles(query),
        onAddToOfficialList: GdSongMatcher().addToOfficialList,
        onAddToAbbreviations: GdSongMatcher().addToAbbreviations,
      ),
    );

    if (result != null) {
      // Clean any dates from the result
      final cleanResult = result.replaceAll(RegExp(r'\[\d{4}-\d{2}-\d{2}\]'), '').trim();
      
      // Update both the normalized title and the title to ensure they match
      final updatedSong = song.copyWith(
        normalizedTitle: cleanResult,
        title: cleanResult,
        isMatched: true,
        originalTitle: song.title, // Preserve the original title
      );

      setState(() {
        _updateSong(setIndex, songIndex, updatedSong);
      });
    }
  }

  DataRow _buildSongRow(BuildContext context, int setIndex, int songIndex) {
    final song = widget.release.setlist[setIndex].songs[songIndex];

    return DataRow(
      cells: [
        // Track Number
        DataCell(
          TextFormField(
            initialValue: song.trackNumber.toString().padLeft(3, '0'),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            onChanged: (value) {
              final number = int.tryParse(value);
              if (number != null) {
                setState(() {
                  _updateSong(setIndex, songIndex, song.copyWith(trackNumber: number));
                });
                // Re-sort if we're currently sorting by track number
                if (_sortColumnIndex == 0) {
                  _sort<num>((s) => s.trackNumber, 0, _sortAscending);
                }
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
                  key: ValueKey('${song.normalizedTitle}_${song.title}'),
                  initialValue: (song.normalizedTitle ?? song.title)
                      .replaceAll(RegExp(r'\[\d{4}-\d{2}-\d{2}\]'), '')
                      .trim(),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onFieldSubmitted: (value) async {
                    // Clean any dates from the input
                    final cleanValue = value.replaceAll(RegExp(r'\[\d{4}-\d{2}-\d{2}\]'), '').trim();
                    final normalizedTitle = await GdSongMatcher().findMatchingTitle(cleanValue);
                    
                    if (normalizedTitle != null) {
                      // Clean any dates from the matched title
                      final cleanNormalizedTitle = normalizedTitle.replaceAll(RegExp(r'\[\d{4}-\d{2}-\d{2}\]'), '').trim();
                      _updateSong(
                        setIndex,
                        songIndex,
                        song.copyWith(
                          normalizedTitle: cleanNormalizedTitle,
                          title: cleanNormalizedTitle, // Update title to match
                          isMatched: true,
                        ),
                      );
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Find matching song',
                onPressed: () => _lookupTitle(context, setIndex, songIndex),
              ),
            ],
          ),
        ),
        // Date
        DataCell(
          TextFormField(
            initialValue: _cleanDate(song.date ?? widget.release.date),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            onChanged: (value) {
              final cleanDate = _cleanDate(value);
              if (_isValidDate(cleanDate)) {
                _updateSong(
                  setIndex,
                  songIndex,
                  song.copyWith(date: cleanDate),
                );
              }
            },
          ),
        ),
        // Length
        DataCell(Text(song.length ?? '0:00')),
        // Match Status
        DataCell(
          Tooltip(
            message: _getMatchStatusMessage(song),
            child: Icon(Icons.circle, color: _getMatchColor(song), size: 16),
          ),
        ),
        // Transition
        DataCell(
          Checkbox(
            value: song.transition,
            onChanged: (value) {
              _updateSong(
                setIndex,
                songIndex,
                song.copyWith(
                  transition: value ?? false,
                  isTransitionManuallySet: true,
                ),
              );
            },
          ),
        ),
        // Assembled Title
        DataCell(Text(song.assembledTitle(song.date ?? widget.release.date))),
      ],
    );
  }

  String _cleanDate(String date) {
    // Extract just the date portion using regex
    final match = RegExp(r'\b\d{4}-\d{2}-\d{2}\b').firstMatch(date);
    return match?.group(0) ?? date;
  }

  bool _isValidDate(String date) {
    return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.minWidth),
              child: DataTable(
                columnSpacing: 8,  // Minimal spacing
                horizontalMargin: 8,  // Minimal margin
                dataRowMinHeight: 48,  // Compact rows
                dataRowMaxHeight: 64,  // Limit max height
                columns: [
                  DataColumn(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 40, child: Text('#')),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.refresh, size: 16),
                          tooltip: 'Renumber Tracks (Start at 101)',
                          onPressed: _renumberTracks,
                        ),
                      ],
                    ),
                    onSort: (columnIndex, ascending) {
                      _sort<num>((s) => s.trackNumber, columnIndex, ascending);
                    },
                  ),
                  DataColumn(
                    label: const SizedBox(width: 120, child: Text('Original')),
                    onSort: (columnIndex, ascending) {
                      _sort<String>((s) => s.originalTitle ?? s.title, columnIndex, ascending);
                    },
                  ),
                  DataColumn(
                    label: const SizedBox(width: 120, child: Text('Normalized')),
                    onSort: (columnIndex, ascending) {
                      _sort<String>((s) => s.normalizedTitle ?? s.title, columnIndex, ascending);
                    },
                  ),
                  DataColumn(
                    label: const SizedBox(width: 100, child: Text('Date')),
                    onSort: (columnIndex, ascending) {
                      _sort<String>((s) => s.date ?? widget.release.date, columnIndex, ascending);
                    },
                  ),
                  const DataColumn(label: SizedBox(width: 50, child: Text('Len'))),
                  const DataColumn(label: SizedBox(width: 40, child: Text('✓'))),
                  const DataColumn(label: SizedBox(width: 40, child: Text('→'))),
                  const DataColumn(label: SizedBox(width: 150, child: Text('Title'))),
                ],
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                rows: [
                  for (var setIndex = 0; setIndex < widget.release.setlist.length; setIndex++)
                    for (var songIndex = 0; songIndex < widget.release.setlist[setIndex].songs.length; songIndex++)
                      _buildSongRow(context, setIndex, songIndex),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

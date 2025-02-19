import 'package:flutter/material.dart';
import '../../core/models/concert_release.dart';
import '../../core/models/concert_set.dart';
import '../../core/models/song.dart';

class BatchOperationsWidget extends StatelessWidget {
  final ConcertRelease release;
  final Function(ConcertRelease) onReleaseChanged;
  final VoidCallback onSaveCatalog;
  final VoidCallback onSaveToMedia;

  const BatchOperationsWidget({
    Key? key,
    required this.release,
    required this.onReleaseChanged,
    required this.onSaveCatalog,
    required this.onSaveToMedia,
  }) : super(key: key);

  void _sortByTrack() {
    final updatedSets = release.setlist.map((set) {
      final sortedSongs = List<Song>.from(set.songs)
        ..sort((a, b) => a.trackNumber.compareTo(b.trackNumber));
      return ConcertSet(
        setNumber: set.setNumber,
        songs: sortedSongs,
      );
    }).toList();

    onReleaseChanged(release.copyWith(
      setlist: updatedSets,
    ));
    
    // Save changes
    onSaveCatalog();
    onSaveToMedia();
  }

  void _renumberTracks() {
    final updatedSets = <ConcertSet>[];
    
    // If there's only one set, treat all songs as part of set 1
    if (release.setlist.length == 1) {
      final set = release.setlist[0];
      final updatedSongs = <Song>[];
      for (var i = 0; i < set.songs.length; i++) {
        updatedSongs.add(set.songs[i].copyWith(
          trackNumber: 101 + i,
        ));
      }
      updatedSets.add(ConcertSet(
        setNumber: set.setNumber,
        songs: updatedSongs,
      ));
    } else {
      // If there are multiple sets, number them accordingly
      for (var set in release.setlist) {
        final baseNumber = set.setNumber * 100;
        final updatedSongs = <Song>[];
        for (var i = 0; i < set.songs.length; i++) {
          updatedSongs.add(set.songs[i].copyWith(
            trackNumber: baseNumber + i + 1,
          ));
        }
        updatedSets.add(ConcertSet(
          setNumber: set.setNumber,
          songs: updatedSongs,
        ));
      }
    }

    onReleaseChanged(release.copyWith(
      setlist: updatedSets,
    ));

    // Save changes
    onSaveCatalog();
    onSaveToMedia();
  }

  void _createSets() {
    // Get all songs
    final allSongs = release.setlist
        .expand((set) => set.songs)
        .toList();
    
    // Group songs by set number
    final songsBySet = <int, List<Song>>{};
    for (final song in allSongs) {
      final setNumber = song.trackNumber < 100 ? 1 : (song.trackNumber ~/ 100);
      songsBySet.putIfAbsent(setNumber, () => []).add(song);
    }
    
    // Create new sets
    final newSets = songsBySet.entries.map((entry) {
      final setNumber = entry.key;
      final songs = entry.value;
      songs.sort((a, b) => a.trackNumber.compareTo(b.trackNumber));
      return ConcertSet(
        setNumber: setNumber,
        songs: songs,
      );
    }).toList()
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
    
    onReleaseChanged(release.copyWith(
      setlist: newSets,
      numberOfSets: newSets.length,
    ));

    // Save changes
    onSaveCatalog();
    onSaveToMedia();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Batch Operations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Track Operations',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Tooltip(
                      message: 'Sort songs by track number within each set',
                      child: ElevatedButton.icon(
                        onPressed: _sortByTrack,
                        icon: const Icon(Icons.sort),
                        label: const Text('Sort by Track'),
                      ),
                    ),
                    Tooltip(
                      message: 'Renumber tracks sequentially within each set',
                      child: ElevatedButton.icon(
                        onPressed: _renumberTracks,
                        icon: const Icon(Icons.numbers),
                        label: const Text('Renumber Tracks'),
                      ),
                    ),
                    Tooltip(
                      message: 'Create sets based on track numbers',
                      child: ElevatedButton.icon(
                        onPressed: _createSets,
                        icon: const Icon(Icons.playlist_add),
                        label: const Text('Create Sets'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Save Operations',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Tooltip(
                      message: 'Save changes to catalog file (assets/catalog/Grateful Dead - DATE.json)',
                      child: ElevatedButton.icon(
                        onPressed: onSaveCatalog,
                        icon: const Icon(Icons.save),
                        label: const Text('Save to Catalog'),
                      ),
                    ),
                    Tooltip(
                      message: 'Update metadata in all media files (FLAC tags)',
                      child: ElevatedButton.icon(
                        onPressed: onSaveToMedia,
                        icon: const Icon(Icons.music_note),
                        label: const Text('Save All to Media Files'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
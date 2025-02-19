import 'package:flutter/material.dart';
import '../../core/models/concert_release.dart';
import '../../core/models/concert_set.dart';
import '../../core/models/song.dart';

class BatchOperationsWidget extends StatelessWidget {
  final ConcertRelease release;
  final ValueChanged<ConcertRelease> onReleaseChanged;

  const BatchOperationsWidget({
    Key? key,
    required this.release,
    required this.onReleaseChanged,
  }) : super(key: key);

  /// Sorts all songs by track number and groups them into sets.
  void _sortTracks() {
    // Flatten all songs from existing sets
    final allSongs = release.setlist.expand((set) => set.songs).toList();
    allSongs.sort((a, b) => a.trackNumber.compareTo(b.trackNumber));

    // Group songs into sets based on track number ranges
    final Map<int, List<Song>> newSets = {};
    for (final song in allSongs) {
      int setNumber = 1;
      if (song.trackNumber >= 200 && song.trackNumber < 300) {
        setNumber = 2;
      } else if (song.trackNumber >= 300 && song.trackNumber < 400) {
        setNumber = 3;
      }
      newSets.putIfAbsent(setNumber, () => []).add(song);
    }

    final newSetlist = newSets.entries.map((entry) {
      return ConcertSet(
        setNumber: entry.key,
        songs: List<Song>.from(entry.value),
      );
    }).toList()
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));

    onReleaseChanged(release.copyWith(setlist: newSetlist));
  }

  /// Renumbers tracks sequentially starting at 101.
  void _renumberTracks() {
    int newTrackNumber = 101;
    
    // If no sets exist, create Set 1 with all songs
    if (release.setlist.isEmpty) {
      final allSongs = release.setlist.expand((set) => set.songs).toList()
        ..sort((a, b) => a.trackNumber.compareTo(b.trackNumber));
      
      final renumberedSongs = allSongs.map((song) {
        final updatedSong = song.copyWith(trackNumber: newTrackNumber);
        newTrackNumber++;
        return updatedSong;
      }).toList();

      final newSetlist = [
        ConcertSet(setNumber: 1, songs: renumberedSongs),
      ];
      onReleaseChanged(release.copyWith(setlist: newSetlist));
      return;
    }

    // Renumber existing sets
    final newSetlist = release.setlist.map((set) {
      final renumberedSongs = set.songs.map((song) {
        final updatedSong = song.copyWith(trackNumber: newTrackNumber);
        newTrackNumber++;
        return updatedSong;
      }).toList();
      return set.copyWith(songs: renumberedSongs);
    }).toList();

    onReleaseChanged(release.copyWith(setlist: newSetlist));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Track Operations',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _sortTracks,
              child: const Text('Sort by Track'),
            ),
            ElevatedButton(
              onPressed: _renumberTracks,
              child: const Text('Renumber Tracks'),
            ),
          ],
        ),
      ],
    );
  }
}

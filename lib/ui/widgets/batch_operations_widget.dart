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

  /// Sorts songs by their current track number and groups them into sets.
  void _sortTracks() {
    // Flatten all songs from existing sets.
    List<Song> allSongs = release.setlist.expand((set) => set.songs).toList();
    allSongs.sort((a, b) => a.trackNumber.compareTo(b.trackNumber));

    // Group songs by track number range.
    // If track number is less than 200, assign to set 1,
    // between 200 and 299 assign to set 2,
    // between 300 and 399 assign to set 3, etc.
    Map<int, List<Song>> groups = {};
    for (Song song in allSongs) {
      int setNumber;
      if (song.trackNumber < 200) {
        setNumber = 1;
      } else if (song.trackNumber < 300) {
        setNumber = 2;
      } else if (song.trackNumber < 400) {
        setNumber = 3;
      } else {
        setNumber = song.trackNumber ~/ 100;
      }
      groups.putIfAbsent(setNumber, () => []).add(song);
    }

    // Create a new setlist from these groups.
    List<ConcertSet> newSetlist = groups.entries.map((entry) {
      entry.value.sort((a, b) => a.trackNumber.compareTo(b.trackNumber));
      return ConcertSet(setNumber: entry.key, songs: entry.value);
    }).toList();
    newSetlist.sort((a, b) => a.setNumber.compareTo(b.setNumber));

    onReleaseChanged(release.copyWith(setlist: newSetlist));
  }

  /// Renumbers all tracks sequentially starting at 101 and reassigns sets.
  void _renumberTracks() {
    // Flatten and sort songs.
    List<Song> allSongs = release.setlist.expand((set) => set.songs).toList();
    allSongs.sort((a, b) => a.trackNumber.compareTo(b.trackNumber));

    int newTrack = 101;
    List<Song> updatedSongs = allSongs.map((song) {
      return song.copyWith(trackNumber: newTrack++);
    }).toList();

    // Group songs based on their new track numbers.
    Map<int, List<Song>> groups = {};
    for (Song song in updatedSongs) {
      int setNumber;
      if (song.trackNumber < 200) {
        setNumber = 1;
      } else if (song.trackNumber < 300) {
        setNumber = 2;
      } else if (song.trackNumber < 400) {
        setNumber = 3;
      } else {
        setNumber = song.trackNumber ~/ 100;
      }
      groups.putIfAbsent(setNumber, () => []).add(song);
    }

    List<ConcertSet> newSetlist = groups.entries.map((entry) {
      entry.value.sort((a, b) => a.trackNumber.compareTo(b.trackNumber));
      return ConcertSet(setNumber: entry.key, songs: entry.value);
    }).toList();
    newSetlist.sort((a, b) => a.setNumber.compareTo(b.setNumber));

    onReleaseChanged(release.copyWith(setlist: newSetlist));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          mainAxisAlignment: MainAxisAlignment.start, // left-justify buttons
          children: [
            ElevatedButton(
              onPressed: _sortTracks,
              child: const Text('Sort by Track'),
            ),
            const SizedBox(width: 16),
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

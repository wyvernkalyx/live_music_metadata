// lib/core/models/concert.dart
import 'package:live_music_metadata_manager/core/models/track.dart'; // Add this import

class Concert {
  final String artist;
  final DateTime date;
  final String venue;
  final List<Track> tracks;
  final String? albumArtworkPath; // Path to artwork

  Concert({
    required this.artist,
    required this.date,
    required this.venue,
    required this.tracks,
    this.albumArtworkPath,
  });
}
// File: lib/utils/metadata_computation.dart

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:live_music_metadata_manager/core/models/concert_release.dart';
import 'package:live_music_metadata_manager/core/models/concert_set.dart';
import 'package:live_music_metadata_manager/core/models/song.dart';

import 'package:live_music_metadata_manager/utils/gd_song_matcher.dart';
import 'package:live_music_metadata_manager/services/flac_utils.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:crypto/crypto.dart';

/// The set of file extensions we handle.
const List<String> supportedExtensions = [
  '.mp3', '.wav', '.aif', '.aiff', '.m4a', '.wma', '.shn', '.flac'
];

/// Compute an MD5 checksum for the file.
Future<String> computeChecksum(String filePath) async {
  final bytes = await File(filePath).readAsBytes();
  return md5.convert(bytes).toString();
}

/// Collapses multiple spaces into one.
String _normalizeTitle(String raw) {
  final trimmed = raw.trim();
  return trimmed.replaceAll(RegExp(r'\s+'), ' ');
}

/// Converts a number of seconds into a formatted duration string (hh:mm:ss or mm:ss).
String _formatDuration(int seconds) {
  final duration = Duration(seconds: seconds);
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  if (duration.inHours > 0) {
    return '${duration.inHours}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}';
  } else {
    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}';
  }
}

/// Uses 'readFlacTags' for FLAC files and also uses flutter_media_metadata to extract duration.
/// For other file types, uses flutter_media_metadata.
Future<Map<String, String>> extractMetadataSmart(String filePath) async {
  final ext = p.extension(filePath).toLowerCase();
  if (ext == '.flac') {
    final flacTags = await FlacUtils.instance.readFlacTags(filePath);
    // Use flutter_media_metadata to extract duration
    final file = File(filePath);
    final metadata = await MetadataRetriever.fromFile(file);
    final durationMs = metadata.trackDuration ?? 0;
    final durationSec = (durationMs / 1000).round();
    final formattedDuration = _formatDuration(durationSec);
    final result = <String, String>{};
    final title = flacTags['TITLE'] ?? p.basenameWithoutExtension(filePath);
    final date = flacTags['DATE'] ?? '';
    final album = flacTags['ALBUM'] ?? '';
    final artist = flacTags['ARTIST'] ?? '';
    result['title'] = title;
    result['date'] = date;
    result['album'] = album;
    result['artist'] = artist;
    result['duration'] = formattedDuration;
    return result;
  } else {
    // For non-FLAC files.
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception("File does not exist: $filePath");
    }
    final metadata = await MetadataRetriever.fromFile(file);
    final durationMs = metadata.trackDuration ?? 0;
    final durationSec = (durationMs / 1000).round();
    final formattedDuration = _formatDuration(durationSec);
    final result = <String, String>{};
    result['album'] = metadata.albumName ?? '';
    result['artist'] = metadata.albumArtistName ?? '';
    result['title'] =
        metadata.trackName ?? p.basenameWithoutExtension(filePath);
    result['date'] = metadata.year?.toString() ?? '';
    result['duration'] = formattedDuration;
    return result;
  }
}

/// The main function that scans a folder, unifies titles, and returns a ConcertRelease.
Future<ConcertRelease> computeMetadataFromMedia(String folderPath) async {
  final directory = Directory(folderPath);
  if (!await directory.exists()) {
    throw Exception('Directory does not exist: $folderPath');
  }
  final allFiles =
      directory.listSync(recursive: false).whereType<File>().toList();
  final mediaFiles = allFiles.where((file) {
    final ext = p.extension(file.path).toLowerCase();
    return supportedExtensions.contains(ext);
  }).toList();
  if (mediaFiles.isEmpty) {
    throw Exception('No supported media files found in $folderPath');
  }
  List<Song> songs = [];
  int trackNumber = 101;
  for (final file in mediaFiles) {
    try {
      final metadataMap = await extractMetadataSmart(file.path);
      // EXACT tag as "Original Title".
      final actualTagTitle =
          metadataMap['title'] ?? p.basenameWithoutExtension(file.path);
      // Parse date either from the metadata or from a bracket in the title.
      String rawDate = metadataMap['date'] ?? '';
      String titleNoDate = actualTagTitle;
      if (rawDate.isEmpty || rawDate.toLowerCase() == 'unknown') {
        final bracketMatch =
            RegExp(r'\[(\d{4}-\d{2}-\d{2})\]').firstMatch(titleNoDate);
        if (bracketMatch != null) {
          rawDate = bracketMatch.group(1)!;
          titleNoDate =
              titleNoDate.replaceAll(bracketMatch.group(0)!, '').trim();
        } else {
          rawDate = 'unknown';
        }
      } else {
        while (true) {
          final bracketAgain =
              RegExp(r'\[\d{4}-\d{2}-\d{2}\]').firstMatch(titleNoDate);
          if (bracketAgain == null) break;
          titleNoDate =
              titleNoDate.replaceAll(bracketAgain.group(0)!, '').trim();
        }
      }
      // Use GdSongMatcher to get the official song name
      final matcher = GdSongMatcher();
      final unifiedTitle = await matcher.findMatchingTitle(titleNoDate) ?? titleNoDate;
      final normalizedTitle = _normalizeTitle(unifiedTitle);
      final duration = metadataMap['duration'] ?? '0';
      
      final song = Song(
        filePath: file.path,
        title: unifiedTitle,
        normalizedTitle: normalizedTitle,
        originalTitle: actualTagTitle,
        length: duration,
        trackNumber: trackNumber,
        date: rawDate,
        isMatched: await matcher.findMatchingTitle(titleNoDate) != null,
        mediaMetadata: metadataMap,
        hasMediaChanges: false,
        mediaTrackNumber: metadataMap['TRACKNUMBER'],
        mediaTitle: metadataMap['TITLE'],
        mediaDate: metadataMap['DATE'],
      );
      songs.add(song);
      trackNumber++;
    } catch (e) {
      print('Error processing ${file.path}: $e');
    }
  }
  // For album-level metadata, use the first file.
  final firstMap = await extractMetadataSmart(mediaFiles.first.path);
  final rawAlbumField = firstMap['album'] ?? '';
  final parsed = parseAlbumField(rawAlbumField);
  String albumTitle =
      '${parsed['concertDate']} - ${parsed['venueName']} - ${parsed['city']} - ${parsed['state']}';
  if ((parsed['collection'] as String).isNotEmpty) {
    albumTitle += ' - ${parsed['collection']}';
  }
  if ((parsed['volume'] as String).isNotEmpty) {
    albumTitle += ' - ${parsed['volume']}';
  }
  final set = ConcertSet(setNumber: 1, songs: songs);
  return ConcertRelease(
    albumTitle: albumTitle,
    date: parsed['concertDate'] ?? '',
    venueName: parsed['venueName'] ?? '',
    city: parsed['city'] ?? '',
    state: parsed['state'] ?? '',
    type: 'concert',
    collection: (parsed['collection'] as String).isEmpty ? '' : parsed['collection'],
    volume: (parsed['volume'] as String).isEmpty ? '' : parsed['volume'],
    notes: '',
    setlist: [set],
    isOfficialRelease: parsed['officialRelease'] ?? false,
    artist: firstMap['artist'] ?? 'Grateful Dead',
    locked: false,
    mediaFolderPath: folderPath,
  );
}

/// Parses an album field into its constituent parts.
/// Example: "1968-02-14 - The Carousel - SF - CA - Road Trips Vol. 2 No. 2"
Map<String, dynamic> parseAlbumField(String albumField) {
  final parts = albumField.split(' - ');
  if (parts.length < 4) {
    return {
      'concertDate': '',
      'venueName': '',
      'city': '',
      'state': '',
      'collection': '',
      'volume': '',
      'officialRelease': false,
    };
  }
  final concertDate = parts[0].trim();
  final venueName = parts[1].trim();
  final city = parts[2].trim();
  final state = parts[3].trim();
  String collection = '';
  String volume = '';
  bool officialRelease = false;
  if (parts.length > 4) {
    final remainder = parts.sublist(4).join(' - ').trim();
    if (remainder.isNotEmpty) {
      final regex = RegExp(r'^(.*?)(\s+Vol\..+)?$');
      final match = regex.firstMatch(remainder);
      if (match != null) {
        collection = match.group(1)?.trim() ?? '';
        volume = match.group(2)?.trim() ?? '';
        officialRelease = collection.isNotEmpty;
      }
    }
  }
  return {
    'concertDate': concertDate,
    'venueName': venueName,
    'city': city,
    'state': state,
    'collection': collection,
    'volume': volume,
    'officialRelease': officialRelease,
  };
}

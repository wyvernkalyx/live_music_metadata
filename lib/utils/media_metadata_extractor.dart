// File: lib/utils/media_metadata_extractor.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:path/path.dart' as p;

/// Extracts metadata from the specified media file using flutter_media_metadata.
/// Returns a Map with the metadata values.
Future<Map<String, dynamic>> extractMetadata(String filePath) async {
  final file = File(filePath);
  if (!await file.exists()) {
    throw Exception("File does not exist: $filePath");
  }

  // Use the static method to extract metadata.
  final metadata = await MetadataRetriever.fromFile(file);

  // We can also store the base name if we want:
  final baseName = p.basename(filePath);

  // Create a Map<String, dynamic> explicitly:
  Map<String, dynamic> result = {
    'album': metadata.albumName,            // could be null if not present
    'artist': metadata.albumArtistName,     // using albumArtistName as requested
    'title': metadata.trackName,            // using trackName as the title
    'date': metadata.year?.toString() ?? '',
    'duration': metadata.trackDuration?.toString() ?? '',
    'filePath': filePath,
    'fileName': baseName,
    // If album art is available (as a byte array), encode it to Base64.
    'artwork': metadata.albumArt != null ? base64Encode(metadata.albumArt!) : null,
  };
  return result;
}

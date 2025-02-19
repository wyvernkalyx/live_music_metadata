// lib/utils/metadata_storage.dart

import 'dart:io';
import 'dart:convert';
import 'package:live_music_metadata_manager/core/models/concert_release.dart';
import 'package:live_music_metadata_manager/utils/metadata_computation.dart';
import 'package:live_music_metadata_manager/core/preferences.dart';
import 'package:path/path.dart' as p;

/// Loads a ConcertRelease JSON file from the catalog directory based on the media folder’s metadata.
/// The expected file name is "Artist Name - yyyy-MM-dd.json".
/// If the file does not exist or fails to decode, returns null.
Future<ConcertRelease?> loadConcertMetadata(String mediaFolderPath) async {
  // Compute the media metadata so we can determine the expected file name.
  final computed = await computeMetadataFromMedia(mediaFolderPath);

  // Get the catalog directory from preferences.
  String? catalogDir = await Preferences.getCatalogDirectory();
  if (catalogDir == null || catalogDir.isEmpty) {
    // If no catalog directory is set, return null.
    return null;
  }

  // Sanitize artist and date strings to remove any characters not allowed in file names.
  final sanitizedArtist = computed.artist.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
  final sanitizedDate = computed.concertDate.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');

  // Build the expected file name.
  final fileName = '$sanitizedArtist - $sanitizedDate.json';
  final filePath = p.join(catalogDir, fileName);
  final file = File(filePath);

  // Check if the file exists.
  if (await file.exists()) {
    try {
      final jsonStr = await file.readAsString();
      final Map<String, dynamic> jsonData = jsonDecode(jsonStr);
      return ConcertRelease.fromJson(jsonData);
    } catch (e) {
      print('Error reading or decoding catalog file $filePath: $e');
      return null;
    }
  } else {
    // No catalog file exists.
    return null;
  }
}

/// Saves the given ConcertRelease object as a JSON file in the catalog directory.
/// The file name is determined by the pattern "Artist Name - yyyy-MM-dd.json".
Future<void> saveConcertMetadata(String mediaFolderPath, ConcertRelease updated) async {
  // Get the catalog directory from preferences.
  final String? catalogDir = await Preferences.getCatalogDirectory();
  if (catalogDir == null || catalogDir.isEmpty) {
    throw Exception('Catalog directory is not set in preferences.');
  }

  // Sanitize the artist and concertDate strings to remove characters not allowed in file names.
  final sanitizedArtist = updated.artist.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
  final sanitizedDate = updated.concertDate.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');

  // Construct the expected file name.
  final fileName = '$sanitizedArtist - $sanitizedDate.json';
  final filePath = p.join(catalogDir, fileName);

  // Convert the ConcertRelease object to JSON.
  final jsonString = jsonEncode(updated.toJson());

  // Write the JSON string to the file.
  final file = File(filePath);
  await file.writeAsString(jsonString);
}

// File: lib/utils/metadata_flac_utils.dart

import 'dart:io';
import 'package:path/path.dart' as path;

class MetadataFlacUtils {
  Future<bool> isMetaflacAvailable() async {
    try {
      final result = await Process.run('metaflac', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<List<File>> findFlacFiles(String directoryPath) async {
    final directory = Directory(directoryPath);
    final files = <File>[];
    
    try {
      print('Searching for FLAC files in: $directoryPath');
      
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.flac')) {
          print('Found FLAC file: ${entity.path}');
          files.add(entity);
        }
      }
      
      if (files.isEmpty) {
        print('No FLAC files found in directory');
      } else {
        print('Found ${files.length} FLAC files');
      }
      
      // Sort files by track number if present in filename, otherwise by name
      files.sort((a, b) {
        final aTrack = _extractTrackNumber(a.path);
        final bTrack = _extractTrackNumber(b.path);
        
        if (aTrack != null && bTrack != null) {
          return aTrack.compareTo(bTrack);
        }
        return a.path.compareTo(b.path);
      });
      
      return files;
    } catch (e, stackTrace) {
      print('Error finding FLAC files: $e\n$stackTrace');
      rethrow;
    }
  }

  int? _extractTrackNumber(String filePath) {
    final fileName = path.basenameWithoutExtension(filePath);
    final match = RegExp(r'^(\d+)[\s-]+').firstMatch(fileName);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  /// Reads FLAC tags using metaflac
  Future<Map<String, String>> readFlacTags(String filePath) async {
    try {
      print('Reading tags from: $filePath');
      
      // Check if metaflac is available
      if (!await isMetaflacAvailable()) {
        print('metaflac is not available on the system');
        return {};
      }

      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        print('File does not exist: $filePath');
        return {};
      }

      // Get basic tags
      final result = await Process.run('metaflac', ['--export-tags-to=-', filePath]);
      if (result.exitCode != 0) {
        print('Error reading FLAC tags: ${result.stderr}');
        return {};
      }

      final tags = <String, String>{};
      final lines = (result.stdout as String).split('\n');
      for (final line in lines) {
        final parts = line.split('=');
        if (parts.length == 2) {
          final key = parts[0].trim().toUpperCase();
          final value = parts[1].trim();
          tags[key] = value;
          print('Found tag: $key = $value');
        }
      }

      // Get song length
      final infoResult = await Process.run('metaflac', ['--show-total-samples', '--show-sample-rate', filePath]);
      if (infoResult.exitCode == 0) {
        final infoLines = (infoResult.stdout as String).trim().split('\n');
        if (infoLines.length == 2) {
          final totalSamples = int.tryParse(infoLines[0]) ?? 0;
          final sampleRate = int.tryParse(infoLines[1]) ?? 44100;
          if (sampleRate > 0) {
            final totalSeconds = totalSamples ~/ sampleRate;
            final minutes = totalSeconds ~/ 60;
            final seconds = totalSeconds % 60;
            tags['LENGTH'] = '$minutes:${seconds.toString().padLeft(2, '0')}';
            print('Calculated length: ${tags['LENGTH']}');
          }
        }
      }

      // Add filename-based metadata
      final fileName = path.basenameWithoutExtension(filePath);
      final fileMetadata = extractMetadataFromFilename(filePath);
      tags.addAll(fileMetadata);

      return tags;
    } catch (e, stackTrace) {
      print('Error reading FLAC tags: $e\n$stackTrace');
      return {};
    }
  }

  Map<String, String> extractMetadataFromFilename(String filePath) {
    final fileName = path.basenameWithoutExtension(filePath);
    final metadata = <String, String>{};
    
    print('Extracting metadata from filename: $fileName');
    
    // Try to extract track number
    final trackMatch = RegExp(r'^(\d+)[\s-]+').firstMatch(fileName);
    if (trackMatch != null) {
      metadata['TRACKNUMBER'] = trackMatch.group(1)!;
      print('Found track number: ${metadata['TRACKNUMBER']}');
    }
    
    // Extract title (remove track number if present)
    var title = fileName;
    if (trackMatch != null) {
      title = title.substring(trackMatch.group(0)!.length);
    }
    metadata['TITLE'] = title.trim();
    print('Extracted title: ${metadata['TITLE']}');
    
    return metadata;
  }

  /// Reads metadata from a FLAC file
  Future<FlacMetadata> readMetadata(String filePath) async {
    if (!await isMetaflacAvailable()) {
      throw Exception('metaflac is not installed. Please install it to read FLAC metadata.');
    }

    // Try to read Vorbis comments first
    final tags = await readFlacTags(filePath);
    
    // If no Vorbis comments found, try to extract from filename
    if (tags.isEmpty) {
      final filenameTags = extractMetadataFromFilename(filePath);
      tags.addAll(filenameTags);
    }

    return FlacMetadata(
      path: filePath,
      album: tags['ALBUM'],
      artist: tags['ARTIST'],
      title: tags['TITLE'],
      date: tags['DATE'],
      venue: tags['VENUE'],
      city: tags['CITY'],
      state: tags['STATE'],
      collection: tags['COLLECTION'],
      volume: tags['VOLUME'],
      notes: tags['NOTES'],
      trackNumber: int.tryParse(tags['TRACKNUMBER'] ?? ''),
      duration: tags['DURATION'],
      officialRelease: tags['OFFICIALRELEASE']?.toLowerCase() == 'true',
    );
  }

  /// Writes FLAC tags using metaflac
  Future<void> writeFlacTags({required String filePath, required Map<String, String> tags}) async {
    if (!await isMetaflacAvailable()) {
      throw Exception('metaflac is not installed. Please install it to write FLAC metadata.');
    }

    if (!File(filePath).existsSync()) {
      throw Exception('File not found: $filePath');
    }

    if (!filePath.toLowerCase().endsWith('.flac')) {
      throw Exception('Not a FLAC file: $filePath');
    }

    // Remove existing tags
    var result = await Process.run('metaflac', [
      '--remove-all-tags',
      filePath,
    ]);

    if (result.exitCode != 0) {
      throw Exception('Error removing existing tags: ${result.stderr}');
    }

    // Add new tags
    for (final entry in tags.entries) {
      if (entry.value.isEmpty) continue;
      
      result = await Process.run('metaflac', [
        '--set-tag=${entry.key}=${entry.value}',
        filePath,
      ]);

      if (result.exitCode != 0) {
        throw Exception('Error setting tag ${entry.key}: ${result.stderr}');
      }
    }
  }
}

/// Class to hold FLAC metadata
class FlacMetadata {
  final String path;
  final String? album;
  final String? artist;
  final String? title;
  final String? date;
  final String? venue;
  final String? city;
  final String? state;
  final String? collection;
  final String? volume;
  final String? notes;
  final int? trackNumber;
  final String? duration;
  final bool officialRelease;

  FlacMetadata({
    required this.path,
    this.album,
    this.artist,
    this.title,
    this.date,
    this.venue,
    this.city,
    this.state,
    this.collection,
    this.volume,
    this.notes,
    this.trackNumber,
    this.duration,
    this.officialRelease = false,
  });
}

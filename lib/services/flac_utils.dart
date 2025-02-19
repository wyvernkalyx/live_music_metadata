import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

class FlacUtils {
  static final FlacUtils instance = FlacUtils._();
  
  FlacUtils._();

  Future<String> computeChecksum(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  Future<List<File>> findFlacFiles(String directoryPath) async {
    final directory = Directory(directoryPath);
    final List<File> flacFiles = [];

    if (await directory.exists()) {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File && path.extension(entity.path).toLowerCase() == '.flac') {
          flacFiles.add(entity);
        }
      }
    }

    return flacFiles;
  }

  Future<Map<String, String>> readFlacTags(String filePath) async {
    try {
      // Read metadata tags
      final tagsResult = await Process.run('metaflac', ['--export-tags-to=-', filePath]);
      
      if (tagsResult.exitCode != 0) {
        print('Error reading FLAC tags: ${tagsResult.stderr}');
        return {};
      }

      final Map<String, String> tags = {};
      final lines = (tagsResult.stdout as String).split('\n');
      
      for (var line in lines) {
        final parts = line.split('=');
        if (parts.length >= 2) {
          final key = parts[0].trim().toUpperCase();
          final value = parts.sublist(1).join('=').trim();
          tags[key] = value;
          
          // Parse album field for additional metadata
          if (key == 'ALBUM') {
            final albumParts = value.split(' - ');
            if (albumParts.length >= 1) {
              // Extract date
              final dateMatch = RegExp(r'(\d{4}-\d{2}-\d{2})').firstMatch(albumParts[0]);
              if (dateMatch != null) {
                tags['DATE'] = dateMatch.group(1)!;
              }
            }
            if (albumParts.length >= 2) {
              // Extract venue
              tags['VENUE'] = albumParts[1].trim();
            }
            if (albumParts.length >= 3) {
              // Extract city and state
              final locationParts = albumParts[2].split(',');
              if (locationParts.length >= 1) {
                tags['CITY'] = locationParts[0].trim();
              }
              if (locationParts.length >= 2) {
                tags['STATE'] = locationParts[1].trim();
              }
            }
          }
        }
      }

      // Get total samples
      final samplesResult = await Process.run('metaflac', ['--show-total-samples', filePath]);
      final sampleRateResult = await Process.run('metaflac', ['--show-sample-rate', filePath]);
      
      if (samplesResult.exitCode == 0 && sampleRateResult.exitCode == 0) {
        try {
          final totalSamples = int.parse((samplesResult.stdout as String).trim());
          final sampleRate = int.parse((sampleRateResult.stdout as String).trim());
          
          if (sampleRate > 0) {
            final totalSeconds = totalSamples ~/ sampleRate;
            final minutes = totalSeconds ~/ 60;
            final seconds = totalSeconds % 60;
            tags['LENGTH'] = '$minutes:${seconds.toString().padLeft(2, '0')}';
          }
        } catch (e) {
          print('Error calculating duration: $e');
        }
      }

      // Extract album art
      final tempArtFile = '${filePath}_cover.jpg';
      final artResult = await Process.run('metaflac', ['--export-picture-to=$tempArtFile', filePath]);
      
      if (artResult.exitCode == 0) {
        try {
          final artFile = File(tempArtFile);
          if (await artFile.exists()) {
            final bytes = await artFile.readAsBytes();
            final base64Art = base64Encode(bytes);
            tags['METADATA_BLOCK_PICTURE'] = base64Art;
            await artFile.delete(); // Clean up temp file
          }
        } catch (e) {
          print('Error extracting album art: $e');
        }
      }

      // Extract track number from filename if not in tags
      if (!tags.containsKey('TRACKNUMBER')) {
        final filename = path.basename(filePath);
        final match = RegExp(r'^(\d+)').firstMatch(filename);
        if (match != null) {
          tags['TRACKNUMBER'] = match.group(1)!;
        }
      }

      return tags;
    } catch (e) {
      print('Exception reading FLAC tags: $e');
      return {};
    }
  }

  Future<bool> writeFlacTags({
    required String filePath,
    required Map<String, String> tags,
  }) async {
    try {
      // First remove all existing tags
      var result = await Process.run('metaflac', ['--remove-all-tags', filePath]);
      if (result.exitCode != 0) {
        print('Error removing existing tags: ${result.stderr}');
        return false;
      }

      // Then remove pictures
      result = await Process.run('metaflac', ['--remove', '--block-type=PICTURE', filePath]);
      if (result.exitCode != 0) {
        print('Error removing existing metadata: ${result.stderr}');
        return false;
      }

      // Write new tags (excluding METADATA_BLOCK_PICTURE which is handled separately)
      final tagArgs = tags.entries
          .where((e) => e.key != 'METADATA_BLOCK_PICTURE')
          .expand((e) => ['--set-tag=${e.key}=${e.value}'])
          .toList();
      
      if (tagArgs.isNotEmpty) {
        result = await Process.run('metaflac', [...tagArgs, filePath]);
        if (result.exitCode != 0) {
          print('Error writing FLAC tags: ${result.stderr}');
          return false;
        }
      }

      // Write album art if present
      if (tags.containsKey('METADATA_BLOCK_PICTURE')) {
        try {
          final tempArtFile = '${filePath}_cover.jpg';
          final artBytes = base64Decode(tags['METADATA_BLOCK_PICTURE']!);
          await File(tempArtFile).writeAsBytes(artBytes);

          result = await Process.run('metaflac', ['--import-picture-from=$tempArtFile', filePath]);
          await File(tempArtFile).delete(); // Clean up temp file

          if (result.exitCode != 0) {
            print('Error writing album art: ${result.stderr}');
            return false;
          }
        } catch (e) {
          print('Error processing album art: $e');
          return false;
        }
      }
      
      return true;
    } catch (e) {
      print('Exception writing FLAC tags: $e');
      return false;
    }
  }
}

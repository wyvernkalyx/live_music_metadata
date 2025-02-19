import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import '../core/models/concert_release.dart';
import 'logger_service.dart';
import 'album_art_service.dart';

class FileOperationsService {
  static final FileOperationsService instance = FileOperationsService._();
  FileOperationsService._();

  Future<String?> selectMediaFolder() async {
    LoggerService.instance.info('Selecting folder...');
    try {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Media Folder',
      );
      LoggerService.instance.info('Selected directory: $selectedDirectory');
      return selectedDirectory;
    } catch (e) {
      LoggerService.instance.error('Error selecting folder', e);
      rethrow;
    }
  }

  Future<void> saveCatalog(ConcertRelease release, String artistName) async {
    try {
      // Save to media folder if available
      if (release.mediaFolderPath != null) {
        final mediaJsonPath = path.join(release.mediaFolderPath!, 'concert.json');
        await File(mediaJsonPath).writeAsString(jsonEncode(release.toJson()));
        LoggerService.instance.info('Saved concert.json to media folder: $mediaJsonPath');
      }

      // Build catalog file path (using the release date)
      final catalogPath = path.join(
        'assets',
        'catalog',
        '$artistName - ${release.date}.json'
      );
      LoggerService.instance.info('Saving to catalog path: $catalogPath');

      // Create catalog directory if it doesn't exist
      final catalogDir = Directory(path.join('assets', 'catalog'));
      if (!await catalogDir.exists()) {
        await catalogDir.create(recursive: true);
        LoggerService.instance.info('Created directory: ${catalogDir.path}');
      }

      LoggerService.instance.info('Saving catalog to: $catalogPath');

      // Save catalog file using the release's JSON
      final file = File(catalogPath);
      await file.writeAsString(JsonEncoder.withIndent('  ').convert(release.toJson()));
      LoggerService.instance.info('Successfully saved catalog file');
    } catch (e, stack) {
      LoggerService.instance.error('Error saving catalog', e, stack);
      rethrow;
    }
  }

  Future<ConcertRelease?> loadCatalog() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select Catalog File',
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final jsonContent = await file.readAsString();
        final jsonData = jsonDecode(jsonContent) as Map<String, dynamic>;
        final release = ConcertRelease.fromJson(jsonData);

        // Check if album art exists in persistent storage
        if (release.albumArtPath != null) {
          final exists = await AlbumArtService.instance.artExists(
            artist: release.artist,
            date: release.date,
          );
          if (exists) {
            final artPath = await AlbumArtService.instance.getArtPath(
              artist: release.artist,
              date: release.date,
            );
            LoggerService.instance.info('Found album art: $artPath');
            return release.copyWith(albumArtPath: artPath);
          }
        }
        return release;
      }
      return null;
    } catch (e) {
      LoggerService.instance.error('Error loading catalog', e);
      rethrow;
    }
  }

  Future<String?> selectAlbumArt() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      return result.files.first.path;
    }
    return null;
  }
}

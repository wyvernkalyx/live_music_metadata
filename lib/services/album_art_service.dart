import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../services/logger_service.dart';

class AlbumArtService {
  static final AlbumArtService instance = AlbumArtService._();
  AlbumArtService._();

  /// Sanitizes a string for use in a filename by removing invalid characters
  String _sanitizeForFilename(String input) {
    return input.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }

  /// Generates the album art filename based on artist and date
  String _generateArtFilename(String artist, String date) {
    final sanitizedArtist = _sanitizeForFilename(artist);
    final sanitizedDate = date.replaceAll(RegExp(r'[^\d-]'), '');
    return '${sanitizedArtist}_${sanitizedDate}_cover.png';
  }

  /// Gets the album art directory path for custom art
  Future<String> _getAlbumArtDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    return path.join(docsDir.path, 'album_art');
  }

  /// Gets the path to stock art in the assets directory
  String _getStockArtPath(String fileName) {
    return path.join('assets', 'stock_art', fileName);
  }

  /// Saves base64-encoded album art to a persistent directory
  Future<String?> saveAlbumArt({
    required String base64Art,
    required String artist,
    required String date,
  }) async {
    try {
      // Get and create the album_art directory if it doesn't exist
      final artDirPath = await _getAlbumArtDir();
      final artDir = Directory(artDirPath);
      if (!await artDir.exists()) {
        await artDir.create(recursive: true);
      }

      // Generate filename and path
      final filename = _generateArtFilename(artist, date);
      final artPath = path.join(artDir.path, filename);

      // Decode and save the base64 art
      final bytes = base64Decode(base64Art);
      await File(artPath).writeAsBytes(bytes);

      LoggerService.instance.info('Saved album art to: $artPath');
      return artPath;
    } catch (e, stack) {
      LoggerService.instance.error('Error saving album art', e, stack);
      return null;
    }
  }

  /// Copies a custom art file to a persistent directory
  Future<String?> saveCustomArt({
    required String sourcePath,
    required String artist,
    required String date,
  }) async {
    try {
      // Get and create the album_art directory if it doesn't exist
      final artDirPath = await _getAlbumArtDir();
      final artDir = Directory(artDirPath);
      if (!await artDir.exists()) {
        await artDir.create(recursive: true);
      }

      // Generate filename and path
      final filename = _generateArtFilename(artist, date);
      final artPath = path.join(artDir.path, filename);

      // Copy the file
      await File(sourcePath).copy(artPath);

      LoggerService.instance.info('Saved custom art to: $artPath');
      return artPath;
    } catch (e, stack) {
      LoggerService.instance.error('Error saving custom art', e, stack);
      return null;
    }
  }

  /// Extracts and saves album art from FLAC metadata
  Future<String?> extractAndSaveArt({
    required Map<String, String> metadata,
    required String artist,
    required String date,
  }) async {
    try {
      final base64Art = metadata['METADATA_BLOCK_PICTURE'];
      if (base64Art == null || base64Art.isEmpty) {
        LoggerService.instance.debug('No album art found in metadata');
        return null;
      }

      return await saveAlbumArt(
        base64Art: base64Art,
        artist: artist,
        date: date,
      );
    } catch (e, stack) {
      LoggerService.instance.error('Error extracting and saving art', e, stack);
      return null;
    }
  }

  /// Gets the path to album art, handling both custom and stock art
  Future<String> getArtPath({
    required String artist,
    required String date,
    bool useStockArt = false,
    String? stockArtFileName,
  }) async {
    if (useStockArt && stockArtFileName != null) {
      return _getStockArtPath(stockArtFileName);
    }
    final artDirPath = await _getAlbumArtDir();
    final filename = _generateArtFilename(artist, date);
    return path.join(artDirPath, filename);
  }

  /// Checks if album art exists, checking both custom and stock locations
  Future<bool> artExists({
    required String artist,
    required String date,
    bool useStockArt = false,
    String? stockArtFileName,
  }) async {
    if (useStockArt && stockArtFileName != null) {
      final stockPath = _getStockArtPath(stockArtFileName);
      return File(stockPath).existsSync();
    }
    final artPath = await getArtPath(artist: artist, date: date);
    return await File(artPath).exists();
  }
}

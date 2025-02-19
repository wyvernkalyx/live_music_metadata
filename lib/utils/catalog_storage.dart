// File: lib/utils/catalog_storage.dart

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:live_music_metadata_manager/core/models/concert_release.dart';
import 'package:live_music_metadata_manager/services/logger_service.dart';
import 'package:live_music_metadata_manager/services/flac_utils.dart';

class CatalogStorage {
  final String _catalogBasePath;
  
  CatalogStorage(this._catalogBasePath);

  /// Gets the catalog directory for a specific collection
  String getCatalogPath(String collection) {
    // Sanitize collection name for file system
    final safeCollection = collection.replaceAll(RegExp(r'[<>:"/\\|?*]'), '').trim();
    return path.join(_catalogBasePath, safeCollection);
  }

  /// Gets the JSON file path for a concert
  String getConcertFilePath(ConcertRelease concert) {
    final catalogPath = path.join('assets', 'catalog');
    final filename = '${concert.artist.replaceAll(RegExp(r'[<>:"/\\|?*]'), '')}-${concert.date}.json';
    return path.join(catalogPath, filename);
  }

  /// Loads a concert from its JSON file
  Future<ConcertRelease?> loadConcert(String concertPath) async {
    try {
      final jsonFile = File(concertPath);
      if (!await jsonFile.exists()) {
        return null;
      }

      final jsonString = await jsonFile.readAsString();
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return ConcertRelease.fromJson(jsonMap);
    } catch (e) {
      LoggerService.instance.error('Error loading concert metadata', e);
      return null;
    }
  }

  /// Saves a concert to its JSON file
  Future<void> saveConcertMetadata(ConcertRelease concert) async {
    try {
      final jsonPath = getConcertFilePath(concert);
      final catalogDir = Directory(path.dirname(jsonPath));
      
      // Create catalog directory if it doesn't exist
      if (!await catalogDir.exists()) {
        await catalogDir.create(recursive: true);
      }

      // Compute checksums for all songs if not already present
      for (var set in concert.setlist) {
        for (var song in set.songs) {
          if (song.checksum == null && song.filePath != null) {
            final checksum = await FlacUtils.instance.computeChecksum(song.filePath!);
            song = song.copyWith(checksum: checksum);
          }
        }
      }

      // Write the JSON file
      final file = File(jsonPath);
      final jsonString = json.encode(concert.toJson());
      await file.writeAsString(jsonString, flush: true);
      LoggerService.instance.info('Saved concert metadata to: ${file.path}');
    } catch (e) {
      LoggerService.instance.error('Error saving concert metadata', e);
      rethrow;
    }
  }

  /// Lists all concerts in a collection
  Future<List<ConcertRelease>> listConcertsInCollection(String collection) async {
    try {
      final catalogPath = getCatalogPath(collection);
      final catalogDir = Directory(catalogPath);
      if (!await catalogDir.exists()) {
        return [];
      }

      final concerts = <ConcertRelease>[];
      await for (final entity in catalogDir.list(recursive: false)) {
        if (entity is File && path.extension(entity.path).toLowerCase() == '.json') {
          try {
            final concert = await loadConcert(entity.path);
            if (concert != null) {
              concerts.add(concert);
            }
          } catch (e) {
            LoggerService.instance.error('Error loading concert from ${entity.path}', e);
            continue;
          }
        }
      }

      return concerts;
    } catch (e) {
      LoggerService.instance.error('Error listing concerts', e);
      return [];
    }
  }

  /// Loads all concerts from the catalog directory
  static Future<List<ConcertRelease>> loadCatalog() async {
    try {
      final catalogPath = path.join('assets', 'catalog');
      final catalogDir = Directory(catalogPath);
      if (!await catalogDir.exists()) {
        return [];
      }

      final concerts = <ConcertRelease>[];
      await for (final entity in catalogDir.list(recursive: false)) {
        if (entity is File && path.extension(entity.path).toLowerCase() == '.json') {
          try {
            final jsonString = await entity.readAsString();
            final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
            concerts.add(ConcertRelease.fromJson(jsonMap));
          } catch (e) {
            LoggerService.instance.error('Error loading concert from ${entity.path}', e);
            continue;
          }
        }
      }

      return concerts;
    } catch (e) {
      LoggerService.instance.error('Error loading catalog', e);
      return [];
    }
  }

  /// Lists all collections in the catalog
  Future<List<String>> listCollections() async {
    try {
      final baseDir = Directory(_catalogBasePath);
      if (!await baseDir.exists()) {
        return [];
      }

      final collections = <String>[];
      await for (final entity in baseDir.list(recursive: false)) {
        if (entity is Directory) {
          collections.add(path.basename(entity.path));
        }
      }

      return collections..sort();
    } catch (e) {
      print('Error listing collections: $e');
      return [];
    }
  }
}

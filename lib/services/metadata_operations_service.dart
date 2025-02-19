import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../core/models/concert_release.dart';
import '../core/models/concert_set.dart';
import '../core/models/song.dart';
import 'logger_service.dart';
import 'flac_utils.dart';
import '../utils/metadata_parser.dart';
import 'album_art_service.dart';
import '../core/Services/song_matcher.dart';
import '../core/Services/song_matcher_registry.dart';

class MetadataOperationsService {
  static final MetadataOperationsService instance = MetadataOperationsService._();
  
  final SongMatcherRegistry _matcherRegistry;
  
  MetadataOperationsService._() : _matcherRegistry = SongMatcherRegistry.instance;

  /// Gets the appropriate song matcher for an artist
  SongMatcher? _getMatcherForArtist(String artistName) {
    final matcher = _matcherRegistry.getMatcherByArtistName(artistName);
    if (matcher == null) {
      LoggerService.instance.warning('No song matcher found for artist: $artistName');
    }
    return matcher;
  }

  Future<Map<String, String>> extractMetadata(String folderPath, List<File> files) async {
    // Get metadata from directory name
    final dirMetadata = MetadataParser.parseMetadataFromPath(folderPath);
    LoggerService.instance.debug('Directory metadata: $dirMetadata');

    if (files.isEmpty) {
      return dirMetadata;
    }

    // Get metadata from first FLAC file
    final firstFileMetadata = await FlacUtils.instance.readFlacTags(files[0].path);
    LoggerService.instance.debug('FLAC metadata: $firstFileMetadata');

    // Create merged metadata, preferring FLAC metadata over directory metadata
    final metadata = <String, String>{
      'DATE': firstFileMetadata['DATE'] ?? dirMetadata['DATE'] ?? '',
      'VENUE': firstFileMetadata['VENUE'] ?? dirMetadata['VENUE'] ?? '',
      'CITY': firstFileMetadata['CITY'] ?? dirMetadata['CITY'] ?? '',
      'STATE': firstFileMetadata['STATE'] ?? dirMetadata['STATE'] ?? '',
      'COLLECTION': firstFileMetadata['COLLECTION'] ?? dirMetadata['COLLECTION'] ?? '',
      'VOLUME': firstFileMetadata['VOLUME'] ?? dirMetadata['VOLUME'] ?? '',
      'NOTES': firstFileMetadata['NOTES'] ?? dirMetadata['NOTES'] ?? '',
    };

    LoggerService.instance.debug('Merged metadata: $metadata');
    return metadata;
  }

  Future<ConcertRelease> createReleaseFromFiles(
    List<File> files,
    String mediaFolderPath,
    String artistName,
  ) async {
    if (files.isEmpty) {
      throw Exception('No FLAC files found in the selected directory');
    }

    // Extract metadata from directory and FLAC files
    final metadata = await extractMetadata(mediaFolderPath, files);

    // Read metadata from each file and create songs
    final songs = <Song>[];
    for (final file in files) {
      LoggerService.instance.debug('Reading metadata from: ${file.path}');
      final metadata = await FlacUtils.instance.readFlacTags(file.path);
      
      // Get track number from metadata or default to 0
      var trackNumber = 0;
      if (metadata.containsKey('TRACKNUMBER')) {
        trackNumber = int.tryParse(metadata['TRACKNUMBER']!) ?? 0;
      }

      final title = metadata['TITLE'] ?? path.basenameWithoutExtension(file.path);
      
      // Check for transition pattern in title (e.g., "Song -> [date]" or "Song ->" or "Song->")
      final transitionMatch = RegExp(r'(.*?)\s*(?:->|>|-\s*>)\s*(?:\[.*?\])?$').firstMatch(title);
      final isTransition = transitionMatch != null;
      final baseTitle = isTransition ? transitionMatch.group(1)!.trim() : title;
      
      // Get the appropriate matcher and try to match the title
      final matcher = _getMatcherForArtist(artistName);
      String? normalizedTitle;
      if (matcher != null) {
        final cleanTitle = baseTitle.replaceAll(RegExp(r'\[\d{4}-\d{2}-\d{2}\]'), '').trim();
        normalizedTitle = await matcher.findMatchingTitle(cleanTitle);
      }
      
      LoggerService.instance.debug('Title parsing: original="$title", base="$baseTitle", transition=$isTransition');
      
      // Compute checksum for the file
      final checksum = await FlacUtils.instance.computeChecksum(file.path);
      
      final song = Song(
        filePath: file.path,
        title: normalizedTitle ?? baseTitle,
        originalTitle: title,
        normalizedTitle: normalizedTitle,
        length: metadata['LENGTH'] ?? metadata['DURATION'] ?? '0:00',
        trackNumber: trackNumber,
        date: metadata['DATE'] ?? '',
        transition: isTransition,
        isTransitionManuallySet: false,
        isMatched: normalizedTitle != null,
        checksum: checksum,
        mediaMetadata: metadata,
        hasMediaChanges: false,
        mediaTrackNumber: metadata['TRACKNUMBER'],
        mediaTitle: metadata['TITLE'],
        mediaDate: metadata['DATE'],
      );
      songs.add(song);
    }

    // Sort songs by track number
    songs.sort((a, b) => a.trackNumber.compareTo(b.trackNumber));

    // Create sets based on track numbers
    final setlist = <ConcertSet>[];
    final songsBySet = <int, List<Song>>{};

    // Group songs by their set number (based on track number ranges)
    for (final song in songs) {
      final setNumber = song.trackNumber < 100 ? 1 : (song.trackNumber ~/ 100).clamp(1, 9);
      songsBySet.putIfAbsent(setNumber, () => []).add(song);
    }

    // Create sets in order
    final sortedSetNumbers = songsBySet.keys.toList()..sort();
    for (final setNumber in sortedSetNumbers) {
      final setSongs = songsBySet[setNumber]!;
      setSongs.sort((a, b) => a.trackNumber.compareTo(b.trackNumber));
      setlist.add(ConcertSet(
        setNumber: setNumber,
        songs: setSongs,
      ));
    }

    // Try to extract and save album art from metadata
    String? albumArtPath;
    final firstFileMetadata = await FlacUtils.instance.readFlacTags(files[0].path);
    if (firstFileMetadata.containsKey('METADATA_BLOCK_PICTURE')) {
      LoggerService.instance.info('Found album art in FLAC metadata');
      albumArtPath = await AlbumArtService.instance.extractAndSaveArt(
        metadata: firstFileMetadata,
        artist: artistName,
        date: metadata['DATE'] ?? '',
      );
      if (albumArtPath != null) {
        LoggerService.instance.info('Successfully saved album art from metadata');
      }
    }

    // If no art in metadata, look for cover art files in the media folder
    if (albumArtPath == null) {
      LoggerService.instance.info('Looking for cover art files in media folder');
      final possibleArtFiles = ['cover.jpg', 'cover.png', 'folder.jpg', 'folder.png'];
      for (final artFile in possibleArtFiles) {
        final artPath = path.join(mediaFolderPath, artFile);
        if (await File(artPath).exists()) {
          LoggerService.instance.info('Found cover art file: $artFile');
          albumArtPath = await AlbumArtService.instance.saveCustomArt(
            sourcePath: artPath,
            artist: artistName,
            date: metadata['DATE'] ?? '',
          );
          if (albumArtPath != null) {
            LoggerService.instance.info('Successfully saved cover art from file');
            break;
          }
        }
      }
    }

    final release = ConcertRelease(
      albumTitle: '',  // Will be generated
      date: metadata['DATE'] ?? '',
      venueName: metadata['VENUE'] ?? '',
      city: metadata['CITY'] ?? '',
      state: metadata['STATE'] ?? '',
      collection: metadata['COLLECTION'] ?? '',
      volume: metadata['VOLUME'] ?? '',
      type: 'concert',
      setlist: setlist,
      numberOfSets: setlist.length,
      isOfficialRelease: false,
      notes: metadata['NOTES'] ?? '',
      mediaFolderPath: mediaFolderPath,
      albumArtPath: albumArtPath,
      useStockArt: false,
      artist: artistName,
    );

    // Generate and set the album title (including notes)
    final albumTitle = release.generateAlbumTitle(includeNotes: true);
    return release.copyWith(albumTitle: albumTitle);
  }

  Future<void> saveToMediaFiles(ConcertRelease release) async {
    LoggerService.instance.info('Starting to save metadata to media files');
    
    // Update release with assembled title (including notes)
    final updatedRelease = release.copyWith(
      albumTitle: release.generateAlbumTitle(includeNotes: true),
    );

    for (var set in updatedRelease.setlist) {
      for (var song in set.songs) {
        if (song.filePath == null || song.filePath!.isEmpty) {
          LoggerService.instance.warning('Skipping song with no file path');
          continue;
        }

        final file = File(song.filePath!);
        if (!await file.exists()) {
          LoggerService.instance.warning('File not found: ${song.filePath}');
          continue;
        }

        // Assemble title with proper transition format
        final assembledTitle = song.assembledTitle(updatedRelease.date);

        final tags = {
          'TITLE': assembledTitle,
          'TRACKNUMBER': song.trackNumber.toString().padLeft(3, '0'),  // Ensure 3 digits
          'DATE': song.date ?? updatedRelease.date,
          'ALBUM': updatedRelease.albumTitle,  // Use assembled album title
          'ARTIST': updatedRelease.artist,
          'VENUE': updatedRelease.venueName,
          'CITY': updatedRelease.city,
          'STATE': updatedRelease.state,
          'COLLECTION': updatedRelease.collection.trim(),
          'VOLUME': updatedRelease.volume.trim(),
          'NOTES': updatedRelease.notes.trim(),
        };

        LoggerService.instance.info('Saving metadata for ${song.filePath}:');
        LoggerService.instance.info('  Track: ${tags['TRACKNUMBER']}');
        LoggerService.instance.info('  Title: ${tags['TITLE']}');
        LoggerService.instance.info('  Date: ${tags['DATE']}');

        // Update FLAC metadata
        final success = await FlacUtils.instance.writeFlacTags(
          filePath: file.path,
          tags: tags,
        );

        if (!success) {
          LoggerService.instance.error('Failed to save metadata for ${song.filePath}');
        }
      }
    }
  }

  /// Saves metadata to both media files and catalog JSON
  Future<void> saveMetadata({
    required ConcertRelease release,
    required String mediaFolderPath,
    required String artistName,
  }) async {
    // Update the release with assembled title (including notes)
    final updatedRelease = release.copyWith(
      albumTitle: release.generateAlbumTitle(includeNotes: true),
    );

    // Save to media files
    await saveToMediaFiles(updatedRelease);

    // Save to media folder as concert.json
    final mediaJsonPath = path.join(mediaFolderPath, 'concert.json');
    await File(mediaJsonPath).writeAsString(jsonEncode(updatedRelease.toJson()));
    LoggerService.instance.info('Saved concert.json to media folder: $mediaJsonPath');

    // Extract yyyy-MM-dd portion of the date
    final RegExp dateRegex = RegExp(r'^(\d{4}-\d{2}-\d{2})');
    final match = dateRegex.firstMatch(updatedRelease.date);
    final sanitizedDate = match != null ? match.group(1)! : updatedRelease.date;

    // Build catalog file path
    final catalogPath = path.join(
      'assets',
      'catalog',
      '$artistName - $sanitizedDate.json',
    );

    // Create catalog directory if needed
    final catalogDir = Directory(path.dirname(catalogPath));
    if (!await catalogDir.exists()) {
      await catalogDir.create(recursive: true);
    }

    // Save to catalog using the clean format
    await File(catalogPath).writeAsString(
      JsonEncoder.withIndent('  ').convert(updatedRelease.toCatalogJson())
    );
    LoggerService.instance.info('Saved catalog file with clean format: $catalogPath');
  }
}

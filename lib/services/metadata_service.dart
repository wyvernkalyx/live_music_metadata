import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

import '../core/models/concert_release.dart';
import '../core/models/concert_set.dart';
import '../core/models/song.dart';
import '../services/flac_utils.dart';
import '../services/logger_service.dart';
import '../utils/metadata_parser.dart';
import '../core/Services/media_file_service.dart';
import '../core/Services/song_matcher.dart';
import '../core/Services/song_matcher_registry.dart';

class MetadataService {
  final FlacUtils _flacUtils;
  final MediaFileService _mediaFileService;
  final SongMatcherRegistry _matcherRegistry;

  MetadataService({
    required FlacUtils flacUtils,
    required MediaFileService mediaFileService,
    SongMatcherRegistry? matcherRegistry,
  })  : _flacUtils = flacUtils,
        _mediaFileService = mediaFileService,
        _matcherRegistry = matcherRegistry ?? SongMatcherRegistry.instance;

  /// Gets the appropriate song matcher for an artist
  SongMatcher? _getMatcherForArtist(String artistName) {
    final matcher = _matcherRegistry.getMatcherByArtistName(artistName);
    if (matcher == null) {
      LoggerService.instance.warning('No song matcher found for artist: $artistName');
    }
    return matcher;
  }

  /// Extracts metadata from both directory name and FLAC files
  Future<Map<String, String>> extractMetadata(String folderPath, List<File> files) async {
    // Get metadata from directory name
    final dirMetadata = MetadataParser.parseMetadataFromPath(folderPath);
    LoggerService.instance.debug('Directory metadata: $dirMetadata');

    if (files.isEmpty) {
      return dirMetadata;
    }

    // Get metadata from first FLAC file
    final firstFileMetadata = await _flacUtils.readFlacTags(files[0].path);
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

  /// Creates a ConcertRelease from FLAC files and metadata
  Future<ConcertRelease> createConcertRelease(
    List<File> files,
    Map<String, String> metadata,
    String artistName,
  ) async {
    final matcher = _getMatcherForArtist(artistName);
    if (matcher == null) {
      throw Exception('Cannot create concert release: No song matcher available for $artistName');
    }
    final songs = <Song>[];
    
    // Process each FLAC file
    for (final file in files) {
      final songMetadata = await _flacUtils.readFlacTags(file.path);
      final title = songMetadata['TITLE'] ?? path.basenameWithoutExtension(file.path);
      final normalizedTitle = await matcher.findMatchingTitle(title);
      
      var trackNumber = 0;
      if (songMetadata.containsKey('TRACKNUMBER')) {
        trackNumber = int.tryParse(songMetadata['TRACKNUMBER']!) ?? 0;
      }

      final song = Song(
        filePath: file.path,
        title: title,
        normalizedTitle: normalizedTitle,
        originalTitle: title,
        length: songMetadata['LENGTH'] ?? songMetadata['DURATION'] ?? '0:00',
        trackNumber: trackNumber,
        date: songMetadata['DATE'] ?? metadata['DATE'] ?? '',
        isMatched: normalizedTitle != null,
        mediaMetadata: songMetadata,
        hasMediaChanges: false,
        mediaTrackNumber: songMetadata['TRACKNUMBER'],
        mediaTitle: songMetadata['TITLE'],
        mediaDate: songMetadata['DATE'],
      );
      songs.add(song);
    }

    // Sort and group songs into sets
    songs.sort((a, b) => a.trackNumber.compareTo(b.trackNumber));
    final setlist = createSetsFromSongs(songs);

    // Get the media folder path from the first file
    final mediaFolderPath = path.dirname(files.first.path);
    
    // Look for album art
    final albumArtPath = await _mediaFileService.getAlbumArtPath(mediaFolderPath);
    LoggerService.instance.debug('Found album art: $albumArtPath');

    // Create the release
    return ConcertRelease(
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
    );
  }

  /// Creates sets from a list of songs based on track numbers
  List<ConcertSet> createSetsFromSongs(List<Song> songs) {
    final songsBySet = <int, List<Song>>{};
    
    // Group songs by set number
    for (final song in songs) {
      final setNumber = song.trackNumber < 100 ? 1 : (song.trackNumber ~/ 100).clamp(1, 9);
      songsBySet.putIfAbsent(setNumber, () => []).add(song);
    }

    // Create and sort sets
    final setlist = songsBySet.entries.map((entry) {
      final songs = entry.value..sort((a, b) => a.trackNumber.compareTo(b.trackNumber));
      return ConcertSet(
        setNumber: entry.key,
        songs: songs,
      );
    }).toList()
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));

    return setlist;
  }

  /// Saves metadata to both catalog and media files
  Future<void> saveMetadata({
    required ConcertRelease release,
    required String mediaFolderPath,
    required String artistName,
  }) async {
    // Save to media folder
    final mediaJsonPath = path.join(mediaFolderPath, 'concert.json');
    await File(mediaJsonPath).writeAsString(jsonEncode(release.toJson()));
    LoggerService.instance.info('Saved concert.json to media folder: $mediaJsonPath');

    // Save to catalog folder
    final catalogPath = path.join(
      Directory.current.path,
      'assets',
      'catalog',
      '$artistName - ${release.date}.json'
    );

    // Create catalog directory if needed
    final catalogDir = Directory(path.dirname(catalogPath));
    if (!await catalogDir.exists()) {
      await catalogDir.create(recursive: true);
    }

    // Save catalog file
    await File(catalogPath).writeAsString(jsonEncode(release.toJson()));
    LoggerService.instance.info('Saved catalog file: $catalogPath');
  }

  /// Updates metadata in FLAC files
  Future<void> updateFlacMetadata(ConcertRelease release) async {
    for (var set in release.setlist) {
      for (var song in set.songs) {
        if (song.filePath == null || song.filePath!.isEmpty) continue;

        final file = File(song.filePath!);
        if (!await file.exists()) {
          LoggerService.instance.warning('File not found: ${song.filePath}');
          continue;
        }

        final cleanDate = MetadataParser.cleanDate(song.date ?? release.date);
        if (!MetadataParser.isValidDate(cleanDate)) {
          LoggerService.instance.warning('Invalid date format: ${song.date ?? release.date}');
          continue;
        }

        await _flacUtils.writeFlacTags(
          filePath: file.path,
          tags: {
            'TITLE': song.assembledTitle(cleanDate),
            'TRACKNUMBER': song.trackNumber.toString(),
            'DATE': cleanDate,
            'ALBUM': release.albumTitle,
            'VENUE': release.venueName,
            'CITY': release.city,
            'STATE': release.state,
            'COLLECTION': release.collection.trim(),
            'VOLUME': release.volume.trim(),
            'NOTES': release.notes.trim(),
          },
        );
      }
    }
  }
}

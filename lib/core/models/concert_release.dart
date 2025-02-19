// File: lib/core/models/concert_release.dart

import 'concert_set.dart';

class ConcertRelease {
  String albumTitle;
  String date;
  String venueName;
  String city;
  String state;
  String type;
  bool isModified;
  bool isOfficialRelease;
  String collection;
  String volume;
  String notes;
  int numberOfSets;
  List<ConcertSet> setlist;
  String? albumArtPath;        // Path to album art file
  bool useStockArt;            // Whether to use stock art from assets
  String? stockArtFileName;    // Filename of stock art in assets folder
  String artist;               // Artist name (e.g., "Grateful Dead")
  bool locked;                 // Whether the release is locked for editing
  bool isVerified;             // Whether the metadata is verified correct
  String? mediaFolderPath;     // Path to the media folder containing FLAC files
  
  String get concertDate => date;  // Alias for compatibility

  ConcertRelease({
    required this.albumTitle,
    required this.date,
    required this.venueName,
    required this.city,
    required this.state,
    required this.type,
    required this.collection,
    required this.volume,
    required this.notes,
    required this.setlist,
    this.isModified = false,
    this.isOfficialRelease = false,
    this.numberOfSets = 1,
    this.albumArtPath,
    this.useStockArt = false,
    this.stockArtFileName,
    this.artist = 'Grateful Dead',
    this.locked = false,
    this.isVerified = false,
    this.mediaFolderPath,
  });

  factory ConcertRelease.fromJson(Map<String, dynamic> json) {
    return ConcertRelease(
      albumTitle: json['AlbumTitle'] as String? ?? '',
      date: json['Date'] as String? ?? '',
      venueName: json['VenueName'] as String? ?? '',
      city: json['City'] as String? ?? '',
      state: json['State'] as String? ?? '',
      type: json['Type'] as String? ?? '',
      collection: json['Collection'] as String? ?? '',
      volume: json['Volume'] as String? ?? '',
      notes: json['Notes'] as String? ?? '',
      isOfficialRelease: json['IsOfficialRelease'] as bool? ?? false,
      isModified: json['IsModified'] as bool? ?? false,
      isVerified: json['IsVerified'] as bool? ?? false,
      numberOfSets: json['numberOfSets'] as int? ?? 1,
      setlist: (json['Setlist'] as List<dynamic>?)
          ?.map((e) => ConcertSet.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      albumArtPath: json['AlbumArtPath'] as String?,
      useStockArt: json['UseStockArt'] as bool? ?? false,
      stockArtFileName: json['StockArtFileName'] as String?,
      artist: json['Artist'] as String? ?? 'Grateful Dead',
      locked: json['Locked'] as bool? ?? false,
      mediaFolderPath: json['MediaFolderPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Save the assembled album title (without the artist) for media files.
      'AlbumTitle': generateAlbumTitle(),
      'Date': date,
      'VenueName': venueName,
      'City': city,
      'State': state,
      'Type': type,
      'IsModified': isModified,
      'Collection': collection,
      'Volume': volume,
      'Notes': notes,
      'IsOfficialRelease': isOfficialRelease,
      'IsVerified': isVerified,
      'numberOfSets': numberOfSets,
      'AlbumArtPath': albumArtPath,
      'UseStockArt': useStockArt,
      'StockArtFileName': stockArtFileName,
      'Artist': artist,
      'Locked': locked,
      'MediaFolderPath': mediaFolderPath,
      'Setlist': setlist.map((set) => {
        'SetNumber': set.setNumber,
        'Songs': set.songs.map((song) => {
          'FilePath': song.filePath,
          'Title': song.title,
          'NormalizedTitle': song.normalizedTitle,
          'OriginalTitle': song.originalTitle,
          'AssembledTitle': song.assembledTitle(date),
          'Transition': song.transition,
          'Length': song.length,
          'TrackNumber': song.trackNumber.toString().padLeft(3, '0'),
          'ConcertDate': song.date ?? date,
          'IsTransitionManuallySet': song.isTransitionManuallySet,
          'IsMatched': song.isMatched,
          'Checksum': song.checksum,
        }).toList(),
      }).toList(),
    };
  }

  /// Generates an assembled album title.
  /// By default, the artist is NOT included.
  /// If includeNotes is true, appends the notes field.
  String generateAlbumTitle({bool includeArtist = false, bool includeNotes = false}) {
    final parts = <String>[];
    
    if (includeArtist && artist.isNotEmpty) {
      parts.add(artist);
    }
    if (date.isNotEmpty) {
      parts.add(date);
    }
    if (venueName.isNotEmpty) {
      parts.add(venueName);
    }
    if (city.isNotEmpty && state.isNotEmpty) {
      parts.add('$city, $state');
    }
    if (collection.isNotEmpty) {
      var collectionPart = collection;
      if (volume.isNotEmpty) {
        collectionPart += ' Vol. $volume';
      }
      parts.add(collectionPart);
    }
    if (includeNotes && notes.trim().isNotEmpty) {
      parts.add(notes.trim());
    }
    return parts.join(' - ');
  }

  /// Returns a JSON representation of the album information in the catalog format.
  Map<String, dynamic> toCatalogJson() {
    final RegExp dateRegex = RegExp(r'^(\d{4}-\d{2}-\d{2})');
    final dateMatch = dateRegex.firstMatch(date);
    final sanitizedDate = dateMatch != null ? dateMatch.group(1)! : date;

    final albumTitleParts = <String>[];
    if (sanitizedDate.isNotEmpty) albumTitleParts.add(sanitizedDate);
    if (venueName.isNotEmpty) albumTitleParts.add(venueName);
    if (city.isNotEmpty && state.isNotEmpty) albumTitleParts.add('$city, $state');
    if (collection.isNotEmpty) {
      var collectionPart = collection;
      if (volume.isNotEmpty) {
        collectionPart += ' Volume $volume';
      }
      albumTitleParts.add(collectionPart);
    }
    // In catalog JSON, the "Notes" field is stored separately.
    return {
      "AlbumTitle": albumTitleParts.join(" - "),
      "Artist": artist,
      "Date": sanitizedDate,
      "VenueName": venueName,
      "City": city,
      "State": state,
      "Collection": collection,
      "Volume": volume.isNotEmpty ? "Volume $volume" : "",
      "Notes": notes,
      "AlbumArtPath": albumArtPath,
      "UseStockArt": useStockArt,
      "StockArtFileName": stockArtFileName,
    };
  }

  ConcertRelease copyWith({
    String? albumTitle,
    String? date,
    String? venueName,
    String? city,
    String? state,
    String? type,
    String? collection,
    String? volume,
    String? notes,
    List<ConcertSet>? setlist,
    bool? isModified,
    bool? isOfficialRelease,
    bool? isVerified,
    int? numberOfSets,
    String? albumArtPath,
    bool? useStockArt,
    String? stockArtFileName,
    String? artist,
    bool? locked,
    String? mediaFolderPath,
  }) {
    return ConcertRelease(
      albumTitle: albumTitle ?? this.albumTitle,
      date: date ?? this.date,
      venueName: venueName ?? this.venueName,
      city: city ?? this.city,
      state: state ?? this.state,
      type: type ?? this.type,
      collection: collection ?? this.collection,
      volume: volume ?? this.volume,
      notes: notes ?? this.notes,
      setlist: setlist ?? this.setlist,
      isModified: isModified ?? this.isModified,
      isOfficialRelease: isOfficialRelease ?? this.isOfficialRelease,
      isVerified: isVerified ?? this.isVerified,
      numberOfSets: numberOfSets ?? this.numberOfSets,
      albumArtPath: albumArtPath ?? this.albumArtPath,
      useStockArt: useStockArt ?? this.useStockArt,
      stockArtFileName: stockArtFileName ?? this.stockArtFileName,
      artist: artist ?? this.artist,
      locked: locked ?? this.locked,
      mediaFolderPath: mediaFolderPath ?? this.mediaFolderPath,
    );
  }
}

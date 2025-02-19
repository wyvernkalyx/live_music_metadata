// File: lib/core/models/song.dart

import 'package:uuid/uuid.dart';
import '../../utils/song_matcher.dart';
import '../../utils/metadata_parser.dart';

class Song {
  final String? filePath;
  final String title;
  final String? _normalizedTitle;
  final String? _originalTitle;
  final bool transition;
  final String? length;
  final int trackNumber;
  final String? date;
  final bool isTransitionManuallySet;
  final bool? isMatched;
  final String? checksum;  // File checksum for matching
  
  // Media file metadata
  final Map<String, String>? mediaMetadata;  // Raw metadata from media file
  final bool hasMediaChanges;                // Whether catalog differs from media
  final String? mediaTrackNumber;            // Original track number from media
  final String? mediaTitle;                  // Original title from media
  final String? mediaDate;                   // Original date from media

  static final SongMatcher _matcher = SongMatcher();
  static bool _initialized = false;

  Song({
    this.filePath,
    required this.title,
    String? normalizedTitle,
    String? originalTitle,
    this.transition = false,
    this.length,
    required this.trackNumber,
    this.date,
    this.isTransitionManuallySet = false,
    this.isMatched,
    this.checksum,
    this.mediaMetadata,
    this.hasMediaChanges = false,
    this.mediaTrackNumber,
    this.mediaTitle,
    this.mediaDate,
  }) :
    _normalizedTitle = normalizedTitle,
    _originalTitle = originalTitle;

  static Future<void> initialize() async {
    if (!_initialized) {
      await _matcher.initialize();
      _initialized = true;
    }
  }

  String? get normalizedTitle => _normalizedTitle;
  String? get originalTitle => _originalTitle;

  String assembledTitle(String concertDate) {
    // Start with the original title if available, otherwise use current title
    String baseTitle = _originalTitle ?? title;
    
    // Remove any existing dates and transitions
    baseTitle = baseTitle
        .replaceAll(RegExp(r'\[\d{4}-\d{2}-\d{2}\]'), '')
        .replaceAll(RegExp(r'\s*(?:->|>|-\s*>)\s*$'), '')
        .trim();

    // Add transition marker if needed
    if (transition) {
      baseTitle = '$baseTitle ->';
    }
    
    // Add date if it differs from concert date
    final songDate = date ?? concertDate;
    if (songDate != concertDate) {
      baseTitle = '$baseTitle [$songDate]';
    }
    
    return baseTitle;
  }

  void clearAssembledTitle() {
    // This method is intentionally empty as we're not caching assembled titles anymore
    // They are now generated on-demand in assembledTitle()
  }

  Song copyWith({
    String? filePath,
    String? title,
    String? normalizedTitle,
    String? originalTitle,
    bool? transition,
    String? length,
    int? trackNumber,
    String? date,
    bool? isTransitionManuallySet,
    bool? isMatched,
    String? checksum,
    Map<String, String>? mediaMetadata,
    bool? hasMediaChanges,
    String? mediaTrackNumber,
    String? mediaTitle,
    String? mediaDate,
  }) {
    return Song(
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      normalizedTitle: normalizedTitle ?? _normalizedTitle,
      originalTitle: originalTitle ?? _originalTitle,
      transition: transition ?? this.transition,
      length: length ?? this.length,
      trackNumber: trackNumber ?? this.trackNumber,
      date: date ?? this.date,  // Preserve existing date unless explicitly changed
      isTransitionManuallySet: isTransitionManuallySet ?? this.isTransitionManuallySet,
      isMatched: isMatched ?? this.isMatched,
      checksum: checksum ?? this.checksum,
      mediaMetadata: mediaMetadata ?? this.mediaMetadata,
      hasMediaChanges: hasMediaChanges ?? this.hasMediaChanges,
      mediaTrackNumber: mediaTrackNumber ?? this.mediaTrackNumber,
      mediaTitle: mediaTitle ?? this.mediaTitle,
      mediaDate: mediaDate ?? this.mediaDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'title': title,
      'normalizedTitle': _normalizedTitle,
      'originalTitle': _originalTitle,
      'transition': transition,
      'length': length,
      'trackNumber': trackNumber.toString().padLeft(3, '0'),  // Ensure 3-digit format
      'date': date,
      'isTransitionManuallySet': isTransitionManuallySet,
      'isMatched': isMatched,
      'checksum': checksum,
      'mediaMetadata': mediaMetadata,
      'hasMediaChanges': hasMediaChanges,
      'mediaTrackNumber': mediaTrackNumber,
      'mediaTitle': mediaTitle,
      'mediaDate': mediaDate,
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    // Handle track number that might be string or int
    int parseTrackNumber(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Song(
      filePath: json['filePath'] as String?,
      title: json['title'] as String? ?? '',
      normalizedTitle: json['normalizedTitle'] as String?,
      originalTitle: json['originalTitle'] as String?,
      transition: json['transition'] as bool? ?? false,
      length: json['length'] as String?,
      trackNumber: parseTrackNumber(json['trackNumber']),
      date: json['date'] as String?,
      isTransitionManuallySet: json['isTransitionManuallySet'] as bool? ?? false,
      isMatched: json['isMatched'] as bool?,
      checksum: json['checksum'] as String?,
      mediaMetadata: (json['mediaMetadata'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value as String),
      ),
      hasMediaChanges: json['hasMediaChanges'] as bool? ?? false,
      mediaTrackNumber: json['mediaTrackNumber'] as String?,
      mediaTitle: json['mediaTitle'] as String?,
      mediaDate: json['mediaDate'] as String?,
    );
  }
}

// File: lib/core/models/concert_release_version.dart

class ConcertReleaseVersion {
  final String albumTitle;
  final bool officialRelease;
  final String? collection;
  final String? volume;
  final String? notes;
  final DateTime dateModified;

  ConcertReleaseVersion({
    required this.albumTitle,
    required this.officialRelease,
    this.collection,
    this.volume,
    this.notes,
    DateTime? dateModified,
  }) : dateModified = dateModified ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'albumTitle': albumTitle,
      'officialRelease': officialRelease,
      'collection': collection,
      'volume': volume,
      'notes': notes,
      'dateModified': dateModified.toIso8601String(),
    };
  }

  factory ConcertReleaseVersion.fromJson(Map<String, dynamic> json) {
    return ConcertReleaseVersion(
      albumTitle: json['albumTitle'],
      officialRelease: json['officialRelease'],
      collection: json['collection'],
      volume: json['volume'],
      notes: json['notes'],
      dateModified: DateTime.parse(json['dateModified']),
    );
  }

  ConcertReleaseVersion copyWith({
    String? albumTitle,
    bool? officialRelease,
    String? collection,
    String? volume,
    String? notes,
    DateTime? dateModified,
  }) {
    return ConcertReleaseVersion(
      albumTitle: albumTitle ?? this.albumTitle,
      officialRelease: officialRelease ?? this.officialRelease,
      collection: collection ?? this.collection,
      volume: volume ?? this.volume,
      notes: notes ?? this.notes,
      dateModified: dateModified ?? this.dateModified,
    );
  }
}

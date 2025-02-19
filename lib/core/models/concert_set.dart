// File: lib/core/models/concert_set.dart

import 'song.dart';

class ConcertSet {
  final int setNumber;
  final List<Song> songs;

  ConcertSet({
    required this.setNumber,
    required this.songs,
  });

  factory ConcertSet.fromJson(Map<String, dynamic> json) {
    return ConcertSet(
      setNumber: json['SetNumber'] as int,
      songs: (json['Songs'] as List<dynamic>)
          .map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SetNumber': setNumber,
      'Songs': songs.map((song) => song.toJson()).toList(),
    };
  }

  ConcertSet copyWith({
    int? setNumber,
    List<Song>? songs,
  }) {
    return ConcertSet(
      setNumber: setNumber ?? this.setNumber,
      songs: songs ?? this.songs,
    );
  }

  void renumberTracks() {
    final baseNumber = setNumber * 100;
    for (var i = 0; i < songs.length; i++) {
      songs[i] = songs[i].copyWith(
        trackNumber: baseNumber + i + 1,
      );
    }
  }
}

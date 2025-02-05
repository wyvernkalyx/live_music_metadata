// lib/core/models/conversion_metadata.dart

class ConversionMetadata {
  String artist;
  String date;  // store date/time as a string or DateTime
  String venue;
  String source;
  String taper;
  bool createBackup;
  String? backupPath;

  ConversionMetadata({
    required this.artist,
    required this.date,
    required this.venue,
    required this.source,
    required this.taper,
    required this.createBackup,
    this.backupPath,
  });
}


class Track {
  final String title;
  final String filePath;
  final String? flacChecksum; // Optional checksum

  Track({
    required this.title,
    required this.filePath,
    this.flacChecksum,
  });
}
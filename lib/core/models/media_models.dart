// lib/core/models/media_models.dart
class MediaFile {
  final String path;
  final String fileName;
  final String extension;
  bool isSelected;

  MediaFile({
    required this.path,
    required this.fileName,
    required this.extension,
    this.isSelected = false,
  });
}

class FolderWithMedia {
  final String folderPath;
  final String folderName;
  final List<MediaFile> mediaFiles;

  FolderWithMedia({
    required this.folderPath,
    required this.folderName,
    required this.mediaFiles,
  });
}
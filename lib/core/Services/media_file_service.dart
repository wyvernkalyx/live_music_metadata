// lib/core/services/media_file_service.dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:live_music_metadata_manager/core/models/media_models.dart';
import 'package:live_music_metadata_manager/core/models/conversion_metadata.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MediaFileService {
  final String baseFolder;
  
  MediaFileService(this.baseFolder);

  static const supportedExtensions = {
    '.mp3',
    '.wav',
    '.aif',
    '.aiff',
    '.m4a',
    '.wma',
    '.shn'
  };

  String _getToolPath(String toolName) {
    final executablePath = Platform.resolvedExecutable;
    final appDir = path.dirname(executablePath);
    final toolsDir = path.join(appDir, 'tools');
    if (toolName == 'ffmpeg') {
      return path.join(toolsDir, 'ffmpeg.exe');
    }
    return path.join(toolsDir, toolName + (Platform.isWindows ? '.exe' : ''));
  }

  List<FolderWithMedia> findNonFlacFolders() {
    final folders = <FolderWithMedia>[];
    final folderPaths = Directory(baseFolder).listSync().whereType<Directory>();
    for (final folderPath in folderPaths) {
      final mediaFiles = _findNonFlacFiles(folderPath.path);
      if (mediaFiles.isNotEmpty) {
        folders.add(FolderWithMedia(
          folderPath: folderPath.path,
          folderName: path.basename(folderPath.path),
          mediaFiles: mediaFiles,
        ));
      }
    }
    return folders;
  }

  List<MediaFile> _findNonFlacFiles(String folderPath) {
    final mediaFiles = <MediaFile>[];
    try {
      final files = Directory(folderPath).listSync(recursive: true).whereType<File>();
      for (final file in files) {
        final extension = path.extension(file.path).toLowerCase();
        if (supportedExtensions.contains(extension)) {
          mediaFiles.add(MediaFile(
            path: file.path,
            fileName: path.basename(file.path),
            extension: extension,
          ));
        }
      }
    } catch (e) {
      print('Error scanning folder $folderPath: $e');
    }
    return mediaFiles;
  }

  Future<void> createBackup(String sourcePath, String backupPath) async {
  final sourceDir = Directory(sourcePath);
  // Get the name of the source folder
  final sourceFolderName = path.basename(sourcePath);
  // Create a target root that includes the source folder name
  final targetRoot = path.join(backupPath, sourceFolderName);
  final backupDir = Directory(targetRoot);

  if (!await backupDir.exists()) {
    await backupDir.create(recursive: true);
    print('Created backup directory: $targetRoot');
  }

  // Copy the entire directory structure
  await for (final entity in sourceDir.list(recursive: true)) {
    // Get the relative path from the source folder
    final relativePath = path.relative(entity.path, from: sourcePath);
    // Build the target path by joining the target root and the relative path
    final targetPath = path.join(targetRoot, relativePath);
    
    if (entity is File) {
      final targetFile = File(targetPath);
      await targetFile.create(recursive: true);
      await entity.copy(targetPath);
      print('Copied file ${entity.path} to $targetPath');
    } else if (entity is Directory) {
      final targetDir = Directory(targetPath);
      await targetDir.create(recursive: true);
      print('Created directory $targetPath');
    }
  }
}


  Future<bool> _checkToolsExist() async {
    final ffmpegPath = _getToolPath('ffmpeg');
    if (!await File(ffmpegPath).exists()) {
      throw Exception('Required tool not found: ffmpeg at $ffmpegPath');
    }
    return true;
  }

  Future<void> _convertToFlac(String inputPath, String outputPath, ConversionMetadata metadata) async {
    final ffmpeg = _getToolPath('ffmpeg');
    final List<String> args = [
      '-i', inputPath,
      '-map_metadata', '0',
      '-compression_level', '12',
      outputPath,
    ];
    final result = await Process.run(ffmpeg, args);
    if (result.exitCode != 0) {
      throw Exception('FFmpeg conversion failed: ${result.stderr}');
    }
  }

  // Public method for converting a single file.
  Future<void> convertFile(String inputPath, String outputPath, ConversionMetadata metadata) async {
    await _convertToFlac(inputPath, outputPath, metadata);
  }

  /// Convert the selected files using FFmpeg.
  Future<void> convertToFlac(List<MediaFile> files, ConversionMetadata metadata) async {
    await _checkToolsExist();

    if (metadata.createBackup) {
      if (metadata.backupPath == null || metadata.backupPath!.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        String? storedBackupFolder = prefs.getString('backup_folder');
        if (storedBackupFolder == null || storedBackupFolder.isEmpty) {
          throw Exception('Backup folder is not set. Please set a backup folder in Preferences.');
        }
        metadata.backupPath = storedBackupFolder;
      }
      await createBackup(baseFolder, metadata.backupPath!);
    }

    for (final file in files) {
      if (file.isSelected) {
        try {
          final outputPath = file.path.replaceAll(file.extension, '.flac');
          await _convertToFlac(file.path, outputPath, metadata);
        } catch (e) {
          print('Error converting ${file.fileName}: $e');
          rethrow;
        }
      }
    }
  }
}

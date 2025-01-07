// lib/core/services/media_file_service.dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:live_music_metadata_manager/core/models/media_models.dart';
import 'package:live_music_metadata_manager/ui/dialogs/conversion_confirmation_dialog.dart';

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

  // Get path to bundled tool
  String _getToolPath(String toolName) {
    final executablePath = Platform.resolvedExecutable;
    final appDir = path.dirname(executablePath);
    final toolsDir = path.join(appDir, 'tools');
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
    final backupDir = Directory(backupPath);

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    // Copy the entire directory structure
    await for (final entity in sourceDir.list(recursive: true)) {
      final targetPath = entity.path.replaceFirst(sourcePath, backupPath);
      if (entity is File) {
        final targetFile = File(targetPath);
        await targetFile.create(recursive: true);
        await entity.copy(targetPath);
      } else if (entity is Directory) {
        final targetDir = Directory(targetPath);
        await targetDir.create(recursive: true);
      }
    }
  }

  Future<bool> _checkToolsExist() async {
    final tools = ['flac', 'shntool', 'metaflac'];
    for (final tool in tools) {
      final toolPath = _getToolPath(tool);
      if (!await File(toolPath).exists()) {
        throw Exception('Required tool not found: $tool at $toolPath');
      }
    }
    return true;
  }

  Future<void> _convertShnToWav(String inputPath, String wavPath) async {
    final shntool = _getToolPath('shntool');
    final result = await Process.run(shntool, ['fix', inputPath, '-o', 'wav', '-O', 'always', wavPath]);
    
    if (result.exitCode != 0) {
      throw Exception('Failed to convert SHN to WAV: ${result.stderr}');
    }
  }

  Future<void> _convertToFlac(String inputPath, String outputPath, ConversionMetadata metadata) async {
    final flac = _getToolPath('flac');
    final metaflac = _getToolPath('metaflac');

    // Convert to FLAC
    final result = await Process.run(flac, [
      '--best',  // Best compression
      '--verify', // Verify the output
      '-f',      // Force overwrite
      '-o', outputPath,
      inputPath
    ]);

    if (result.exitCode != 0) {
      throw Exception('FLAC conversion failed: ${result.stderr}');
    }

    // Add metadata tags
    final tags = [
      '--set-tag=ARTIST=${metadata.artist}',
      '--set-tag=DATE=${metadata.date}',
      if (metadata.venue.isNotEmpty) '--set-tag=VENUE=${metadata.venue}',
      if (metadata.source.isNotEmpty) '--set-tag=SOURCE=${metadata.source}',
      if (metadata.taper.isNotEmpty) '--set-tag=TAPER=${metadata.taper}',
    ];

    final metadataResult = await Process.run(metaflac, [...tags, outputPath]);
    if (metadataResult.exitCode != 0) {
      throw Exception('Failed to add metadata: ${metadataResult.stderr}');
    }
  }

  Future<void> convertToFlac(List<MediaFile> files, ConversionMetadata metadata) async {
    // Verify tools exist
    await _checkToolsExist();

    // Create backup if requested
    if (metadata.createBackup && metadata.backupPath != null) {
      await createBackup(baseFolder, metadata.backupPath!);
    }

    // Convert files
    for (final file in files) {
      if (file.isSelected) {
        try {
          final outputPath = file.path.replaceAll(file.extension, '.flac');
          
          if (file.extension.toLowerCase() == '.shn') {
            // For SHN files, we need to convert to WAV first
            final tempWavPath = file.path.replaceAll(file.extension, '.wav');
            await _convertShnToWav(file.path, tempWavPath);
            
            // Convert WAV to FLAC
            await _convertToFlac(tempWavPath, outputPath, metadata);
            
            // Clean up temporary WAV file
            await File(tempWavPath).delete();
          } else {
            // Direct conversion to FLAC for other formats
            await _convertToFlac(file.path, outputPath, metadata);
          }
        } catch (e) {
          print('Error converting ${file.fileName}: $e');
          rethrow;
        }
      }
    }
  }
}
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:live_music_metadata_manager/core/models/artist_configuration.dart';



class FolderNormalizationService {
  final String baseFolder;
  final ArtistConfiguration? artistConfig;

  FolderNormalizationService(this.baseFolder, this.artistConfig);

  List<(String, String)> getNonNormalizedFolders() {
    final invalidFolders = <(String, String)>[];
    final folderPaths = Directory(baseFolder).listSync().whereType<Directory>();

    for (final folderPath in folderPaths) {
      final folderName = path.basename(folderPath.path);
      if (!isNormalized(folderName)) {
        final normalizedName = normalizeFolderName(folderName);
        invalidFolders.add((folderName, normalizedName));
      }
    }

    return invalidFolders;
  }

  Future<void> normalizeFolderNames() async {
    final folderPaths = Directory(baseFolder).listSync().whereType<Directory>();
    for (final folderPath in folderPaths) {
      final folderName = path.basename(folderPath.path);
      if (!isNormalized(folderName)) {
        final normalizedName = normalizeFolderName(folderName);
        if (normalizedName != 'Unable to normalize') {
          final newFolderPath = path.join(baseFolder, normalizedName);
          try {
            await Directory(folderPath.path).rename(newFolderPath);
          } catch (e) {
            print('Error renaming folder $folderName: $e');
          }
        }
      }
    }
  }

  String normalizeFolderName(String originalName) {
    if (artistConfig?.name == "Grateful Dead") {
      var xxMatch = RegExp(r'gd(\d{2})-(\d{2})-xx(.*)').firstMatch(originalName);
      if (xxMatch != null) {
        var year = '19${xxMatch.group(1)}';
        var month = xxMatch.group(2);
        var extra = xxMatch.group(3) ?? '';
        return '${artistConfig!.name} - $year-$month-xx$extra';
      }

      var match = RegExp(r'gd(\d{2})-(\d{2})-(\d{2})(.*)').firstMatch(originalName);
      if (match != null) {
        var year = '19${match.group(1)}';
        var month = match.group(2);
        var day = match.group(3);
        var extra = match.group(4) ?? '';
        return '${artistConfig!.name} - $year-$month-$day$extra';
      }
    }
    return 'Unable to normalize';
  }

  bool isNormalized(String folderName) {
    if (artistConfig?.name == "Grateful Dead") {
      return RegExp(r'^Grateful Dead - \d{4}-\d{2}(-\d{2}|-xx)').hasMatch(folderName);
    }
    return false;
  }
}
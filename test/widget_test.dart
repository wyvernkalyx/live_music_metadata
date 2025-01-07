import 'package:flutter_test/flutter_test.dart';
import 'package:live_music_metadata_manager/core/models/artist_configuration.dart';
import 'package:live_music_metadata_manager/core/services/folder_normalization_service.dart';

void main() {
  group('FolderNormalizationService', () {
    late FolderNormalizationService service;

    setUp(() {
      final artistConfig = ArtistConfiguration(
        name: 'Grateful Dead',
        folderPrefix: 'gd',
      );
      service = FolderNormalizationService('test_path', artistConfig);
    });

    test('normalizes standard folder name', () {
      expect(
        service.normalizeFolderName('gd65-11-03.9044c.flac16'),
        equals('Grateful Dead - 1965-11-03.9044c.flac16')
      );
    });

    test('normalizes folder name with xx date', () {
      expect(
        service.normalizeFolderName('gd66-01-xx.18846c.flac16'),
        equals('Grateful Dead - 1966-01-xx.18846c.flac16')
      );
    });

    test('normalizes folder name with additional metadata', () {
      expect(
        service.normalizeFolderName('gd66-03-19.sbd.scotton.81951.sbeok.flac16'),
        equals('Grateful Dead - 1966-03-19.sbd.scotton.81951.sbeok.flac16')
      );
    });
  });
}
import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/logger_service.dart';
import '../../services/album_art_service.dart';
import '../dialogs/custom_art_dialog.dart';
import '../../core/models/concert_release.dart';

class AlbumArtWidget extends StatefulWidget {
  final String? albumArtPath;
  final String artist;
  final String date;
  final ValueChanged<String> onArtSelected;
  final ConcertRelease release;

  const AlbumArtWidget({
    Key? key,
    this.albumArtPath,
    required this.artist,
    required this.date,
    required this.onArtSelected,
    required this.release,
  }) : super(key: key);

  @override
  State<AlbumArtWidget> createState() => _AlbumArtWidgetState();
}

class _AlbumArtWidgetState extends State<AlbumArtWidget> {
  Future<bool>? _artExistsFuture;

  @override
  void initState() {
    super.initState();
    _updateArtExistsFuture();
  }

  @override
  void didUpdateWidget(AlbumArtWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.albumArtPath != widget.albumArtPath ||
        oldWidget.artist != widget.artist ||
        oldWidget.date != widget.date ||
        oldWidget.release.useStockArt != widget.release.useStockArt ||
        oldWidget.release.stockArtFileName != widget.release.stockArtFileName) {
      _updateArtExistsFuture();
    }
  }

  void _updateArtExistsFuture() {
    if (widget.release.useStockArt && widget.release.stockArtFileName != null) {
      _artExistsFuture = AlbumArtService.instance.artExists(
        artist: widget.artist,
        date: widget.date,
        useStockArt: true,
        stockArtFileName: widget.release.stockArtFileName,
      );
    } else if (widget.albumArtPath != null) {
      _artExistsFuture = Future.value(File(widget.albumArtPath!).existsSync());
    } else {
      _artExistsFuture = AlbumArtService.instance.artExists(
        artist: widget.artist,
        date: widget.date,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: 300,
        height: 300,
        child: Stack(
          children: [
            // Constrain the image to the 300x300 box
            SizedBox.expand(
              child: FutureBuilder<bool>(
                future: _artExistsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final artExists = snapshot.data ?? false;
                  if (!artExists) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 100, color: Colors.grey),
                    );
                  }

                  return FutureBuilder<String>(
                    future: AlbumArtService.instance.getArtPath(
                      artist: widget.artist,
                      date: widget.date,
                      useStockArt: widget.release.useStockArt,
                      stockArtFileName: widget.release.stockArtFileName,
                    ),
                    builder: (context, pathSnapshot) {
                      if (pathSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final artPath = widget.albumArtPath ?? pathSnapshot.data;
                      if (artPath == null) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 100, color: Colors.grey),
                        );
                      }

                      return Image.file(
                        File(artPath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          LoggerService.instance.error(
                            'Error loading album art',
                            error,
                            stackTrace,
                          );
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              size: 100,
                              color: Colors.grey,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            // Button for choosing custom art
            Positioned(
              right: 4,
              top: 4,
              child: IconButton(
                icon: const Icon(Icons.photo_library),
                onPressed: () => _handleCustomArtSelection(context),
                tooltip: 'Choose Custom Art',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCustomArtSelection(BuildContext context) async {
    // Show the custom art dialog to pick an image file.
    final selectedPath = await showDialog<String>(
      context: context,
      builder: (context) => const CustomArtDialog(),
    );
    if (selectedPath != null) {
      try {
        // Save the selected custom art to a persistent directory.
        final savedArtPath = await AlbumArtService.instance.saveCustomArt(
          sourcePath: selectedPath,
          artist: widget.artist,
          date: widget.date,
        );
        if (savedArtPath != null) {
          widget.onArtSelected(savedArtPath);
          _updateArtExistsFuture();
        }
      } catch (e, stack) {
        LoggerService.instance.error('Error saving custom art', e, stack);
      }
    }
  }
}

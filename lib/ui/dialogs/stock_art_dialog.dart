import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import '../../services/logger_service.dart';

class StockArtDialog extends StatefulWidget {
  final String assetsPath;

  const StockArtDialog({super.key, required this.assetsPath});

  @override
  State<StockArtDialog> createState() => _StockArtDialogState();
}

class _StockArtDialogState extends State<StockArtDialog> {
  List<String> _artFiles = [];
  String? _selectedFile;

  @override
  void initState() {
    super.initState();
    _loadStockArt();
  }

  Future<void> _loadStockArt() async {
    try {
      // Load the manifest to get list of assets
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = Map.from(
        const JsonDecoder().convert(manifestContent) as Map,
      );

      // Filter for stock art images
      final artFiles = manifestMap.keys
          .where((String key) => key.startsWith('assets/stock_art/') && 
                                (key.endsWith('.jpg') || 
                                 key.endsWith('.jpeg') || 
                                 key.endsWith('.png')))
          .map((String key) => path.basename(key))
          .toList();

      setState(() {
        _artFiles = artFiles;
      });
      LoggerService.instance.debug('Found ${_artFiles.length} stock art files');
    } catch (e) {
      LoggerService.instance.error('Error loading stock art', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Stock Art'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: _artFiles.isEmpty
            ? const Center(child: Text('No stock art available'))
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _artFiles.length,
                itemBuilder: (context, index) {
                  final fileName = _artFiles[index];
                  final isSelected = fileName == _selectedFile;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedFile = fileName;
                      });
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Card(
                          color: isSelected ? Colors.blue.withOpacity(0.2) : null,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Image.asset(
                              'assets/stock_art/$fileName',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                LoggerService.instance.error('Error loading image: $fileName', error);
                                return const Icon(Icons.broken_image);
                              },
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Positioned(
                            top: 4,
                            right: 4,
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.blue,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _selectedFile == null
              ? null
              : () => Navigator.of(context).pop(_selectedFile),
          child: const Text('Select'),
        ),
      ],
    );
  }
}

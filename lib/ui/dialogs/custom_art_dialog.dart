import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/logger_service.dart';

class CustomArtDialog extends StatelessWidget {
  const CustomArtDialog({super.key});

  Future<String?> _pickImageFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        LoggerService.instance.info('Selected custom art: ${file.path}');
        return file.path;
      }
    } catch (e, stack) {
      LoggerService.instance.error('Error picking image file', e, stack);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Custom Art'),
      content: const SizedBox(
        width: 400,
        height: 100,
        child: Center(
          child: Text(
            'Choose a custom image file (JPG or PNG) to use as album art.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final filePath = await _pickImageFile();
            if (context.mounted) {
              Navigator.of(context).pop(filePath);
            }
          },
          child: const Text('Choose File'),
        ),
      ],
    );
  }
}

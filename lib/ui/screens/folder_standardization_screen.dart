import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:live_music_metadata_manager/core/app_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:live_music_metadata_manager/core/services/folder_normalization_service.dart';
import 'package:path/path.dart' as path;

class FolderStandardizationScreen extends StatelessWidget {
  const FolderStandardizationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folder Standardization'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                String? selectedDirectory =
                await FilePicker.platform.getDirectoryPath();

                if (selectedDirectory != null) {
                  final appState =
                  Provider.of<AppState>(context, listen: false);
                  appState.setSelectedDirectory(selectedDirectory);

                  // Update non-normalized folders after selecting a directory
                  final service = FolderNormalizationService(
                      selectedDirectory, appState.selectedArtist);
                  final nonNormalizedFolders =
                  service.getNonNormalizedFolders();
                  appState.setNonNormalizedFolders(nonNormalizedFolders);
                }
              },
              child: const Text('Select Root Directory'),
            ),
            Consumer<AppState>(
              builder: (context, appState, child) {
                final selectedDirectory = appState.selectedDirectory;

                if (selectedDirectory == null) {
                  return const SizedBox.shrink();
                }

                return Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Selected Directory: ${appState.selectedDirectory ?? "None"}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Display the FolderRenameGrid
                      Expanded(
                        child: FolderRenameGrid(
                          foldersToRename: appState.nonNormalizedFolders,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final appState = Provider.of<AppState>(context,
                              listen: false);
                          final selectedDirectory =
                              appState.selectedDirectory;

                          if (selectedDirectory != null) {
                            final service = FolderNormalizationService(
                                selectedDirectory, appState.selectedArtist);

                            // Call the renaming function
                            appState.startRenaming();
                            await service.normalizeFolderNames();
                            appState.stopRenaming();

                            // Update the list of non-normalized folders after renaming
                            final nonNormalizedFolders =
                            service.getNonNormalizedFolders();
                            appState.setNonNormalizedFolders(
                                nonNormalizedFolders);
                          }
                        },
                        child: const Text('Start Renaming'),
                      ),
                      Consumer<AppState>(
                        builder: (context, appState, child) {
                          return appState.isRenaming
                              ? const LinearProgressIndicator()
                              : const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class FolderRenameGrid extends StatelessWidget {
  final List<(String, String)> foldersToRename;

  const FolderRenameGrid({Key? key, required this.foldersToRename})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Original Name",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Proposed Name",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: foldersToRename.length,
              itemBuilder: (context, index) {
                final folder = foldersToRename[index];
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor.withOpacity(0.5),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            folder.$1,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            folder.$2,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: folder.$2 == 'Unable to normalize'
                                      ? Theme.of(context).colorScheme.error
                                      : null,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
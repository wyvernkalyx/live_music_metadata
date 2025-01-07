import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:live_music_metadata_manager/core/models/artist_configuration.dart';
import 'package:live_music_metadata_manager/core/app_state.dart';

class ConfigurationScreen extends StatefulWidget {
  const ConfigurationScreen({Key? key}) : super(key: key);

  @override
  _ConfigurationScreenState createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _prefixController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _prefixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configuration"),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: appState.artistConfigurations.length,
                  itemBuilder: (context, index) {
                    final artistConfig = appState.artistConfigurations[index];
                    return ListTile(
                      title: Text(artistConfig.name),
                      subtitle: Text("Prefix: ${artistConfig.folderPrefix}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          appState.removeArtistConfiguration(artistConfig.name);
                        },
                      ),
                      onTap: () {
                        appState.setSelectedArtist(artistConfig);
                        Navigator.pop(context); // Close screen after selection
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(labelText: "Artist Name"),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an artist name';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _prefixController,
                        decoration:
                            const InputDecoration(labelText: "Folder Prefix"),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a folder prefix';
                          }
                          return null;
                        },
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final newArtistConfig = ArtistConfiguration(
                              name: _nameController.text,
                              folderPrefix: _prefixController.text,
                            );
                            appState.addArtistConfiguration(newArtistConfig);
                            _nameController.clear();
                            _prefixController.clear();
                          }
                        },
                        child: const Text("Add Artist"),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
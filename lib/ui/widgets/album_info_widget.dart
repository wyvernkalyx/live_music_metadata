import 'package:flutter/material.dart';
import '../../core/models/concert_release.dart';

class AlbumInfoWidget extends StatefulWidget {
  /// The media side data (imported from FLAC files).
  final ConcertRelease mediaRelease;

  /// The catalog side data (imported from a JSON file) or null.
  final ConcertRelease? catalogRelease;

  /// Called whenever the catalog release is updated.
  final ValueChanged<ConcertRelease> onCatalogChanged;

  const AlbumInfoWidget({
    Key? key,
    required this.mediaRelease,
    required this.catalogRelease,
    required this.onCatalogChanged,
  }) : super(key: key);

  @override
  _AlbumInfoWidgetState createState() => _AlbumInfoWidgetState();
}

class _AlbumInfoWidgetState extends State<AlbumInfoWidget> {
  // ---------------------
  // Controllers for catalog side (editable)
  // ---------------------
  late TextEditingController _artistController;
  late TextEditingController _dateController;
  late TextEditingController _venueController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _collectionController;
  late TextEditingController _volumeController;
  late TextEditingController _notesController;

  // Computed assembled title for the catalog side
  String _catalogAssembledTitle = '';

  // Additional catalog-only flags
  bool _isOfficialRelease = false;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    if (widget.catalogRelease != null) {
      _initializeCatalogControllers(widget.catalogRelease!);
    }
  }

  @override
  void didUpdateWidget(covariant AlbumInfoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.catalogRelease != null && oldWidget.catalogRelease == null) {
      _initializeCatalogControllers(widget.catalogRelease!);
    }
  }

  void _initializeCatalogControllers(ConcertRelease release) {
    _artistController = TextEditingController(text: release.artist);
    _dateController = TextEditingController(text: release.date);
    _venueController = TextEditingController(text: release.venueName);
    _cityController = TextEditingController(text: release.city);
    _stateController = TextEditingController(text: release.state);
    _collectionController = TextEditingController(text: release.collection);
    _volumeController = TextEditingController(text: release.volume);
    _notesController = TextEditingController(text: release.notes.trim());
    _isOfficialRelease = release.isOfficialRelease;
    _isLocked = false;
    _catalogAssembledTitle = _computeAssembledTitle(
      date: _dateController.text,
      venue: _venueController.text,
      city: _cityController.text,
      state: _stateController.text,
      collection: _collectionController.text,
      volume: _volumeController.text,
      notes: _notesController.text,
    );
  }

  /// When any catalog field changes, update the computed assembled title and call the callback.
  void _updateCatalogRelease() {
    final assembledTitle = _computeAssembledTitle(
      date: _dateController.text,
      venue: _venueController.text,
      city: _cityController.text,
      state: _stateController.text,
      collection: _collectionController.text,
      volume: _volumeController.text,
      notes: _notesController.text,
    );
    setState(() {
      _catalogAssembledTitle = assembledTitle;
    });

    // Update the release with the recomputed album title.
    final updatedRelease = (widget.catalogRelease ?? widget.mediaRelease).copyWith(
      artist: _artistController.text,
      date: _dateController.text,
      venueName: _venueController.text,
      city: _cityController.text,
      state: _stateController.text,
      collection: _collectionController.text,
      volume: _volumeController.text,
      notes: _notesController.text.trim(),
      albumTitle: assembledTitle, // Set the assembled title directly.
      isOfficialRelease: _isOfficialRelease,
    );
    widget.onCatalogChanged(updatedRelease);
  }

  /// Computes an assembled title from the provided fields.
  String _computeAssembledTitle({
    required String date,
    required String venue,
    required String city,
    required String state,
    required String collection,
    required String volume,
    required String notes,
  }) {
    List<String> parts = [];
    if (date.isNotEmpty) parts.add(date);
    if (venue.isNotEmpty) parts.add(venue);
    final location = [
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
    ].join(', ');
    if (location.isNotEmpty) parts.add(location);
    if (collection.isNotEmpty) parts.add(collection);
    if (volume.isNotEmpty) parts.add('Volume $volume');
    if (notes.trim().isNotEmpty) parts.add(notes.trim());
    return parts.join(' - ');
  }

  /// Builds a read-only field with a label.
  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(value.isNotEmpty ? value : '-'),
          ),
        ],
      ),
    );
  }

  /// Builds an editable text field.
  Widget _buildEditableField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: (text) {
          _updateCatalogRelease();
        },
      ),
    );
  }

  /// Builds the catalog metadata form.
  Widget _buildCatalogForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Catalog Metadata", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _buildEditableField("Artist", _artistController),
          const SizedBox(height: 8),
          // Removed the editable Album Title field.
          _buildReadOnlyField("Assembled Album Title", _catalogAssembledTitle),
          const SizedBox(height: 8),
          _buildEditableField("Date", _dateController),
          const SizedBox(height: 8),
          _buildEditableField("Venue", _venueController),
          const SizedBox(height: 8),
          _buildEditableField("City", _cityController),
          const SizedBox(height: 8),
          _buildEditableField("State", _stateController),
          const SizedBox(height: 8),
          _buildEditableField("Collection", _collectionController),
          const SizedBox(height: 8),
          _buildEditableField("Volume", _volumeController),
          const SizedBox(height: 8),
          _buildEditableField("Notes", _notesController, maxLines: 2),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text("Official Release"),
            value: _isOfficialRelease,
            onChanged: (val) {
              setState(() {
                _isOfficialRelease = val;
              });
              _updateCatalogRelease();
            },
          ),
          SwitchListTile(
            title: const Text("Locked"),
            value: _isLocked,
            onChanged: (val) {
              setState(() {
                _isLocked = val;
              });
              _updateCatalogRelease();
            },
          ),
        ],
      ),
    );
  }

  /// If no catalog data exists, show a button to "import from media metadata."
  Widget _buildImportButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          final newCatalog = widget.mediaRelease.copyWith(
            artist: widget.mediaRelease.artist,
            date: widget.mediaRelease.date,
            venueName: widget.mediaRelease.venueName,
            city: widget.mediaRelease.city,
            state: widget.mediaRelease.state,
            collection: widget.mediaRelease.collection,
            volume: widget.mediaRelease.volume,
            notes: widget.mediaRelease.notes.trim(),
          ).copyWith(
            albumTitle: widget.mediaRelease.generateAlbumTitle(includeNotes: true),
            isOfficialRelease: false,
          );
          widget.onCatalogChanged(newCatalog);
          setState(() {
            _initializeCatalogControllers(newCatalog);
          });
        },
        child: const Text("Import from Media Metadata"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side: Media Metadata (read-only)
        Expanded(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Media Metadata", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    _buildReadOnlyField("Artist", widget.mediaRelease.artist),
                    const SizedBox(height: 8),
                    _buildReadOnlyField("Original Album Title", widget.mediaRelease.originalAlbumTitle ?? widget.mediaRelease.albumTitle),
                    const SizedBox(height: 8),
                    _buildReadOnlyField("Assembled Album Title", _computeAssembledTitle(
                      date: widget.mediaRelease.date,
                      venue: widget.mediaRelease.venueName,
                      city: widget.mediaRelease.city,
                      state: widget.mediaRelease.state,
                      collection: widget.mediaRelease.collection,
                      volume: widget.mediaRelease.volume,
                      notes: widget.mediaRelease.notes,
                    )),
                    const SizedBox(height: 8),
                    _buildReadOnlyField("Date", widget.mediaRelease.date),
                    const SizedBox(height: 8),
                    _buildReadOnlyField("Venue", widget.mediaRelease.venueName),
                    const SizedBox(height: 8),
                    _buildReadOnlyField("City", widget.mediaRelease.city),
                    const SizedBox(height: 8),
                    _buildReadOnlyField("State", widget.mediaRelease.state),
                    const SizedBox(height: 8),
                    _buildReadOnlyField("Collection", widget.mediaRelease.collection),
                    const SizedBox(height: 8),
                    _buildReadOnlyField("Volume", widget.mediaRelease.volume),
                    const SizedBox(height: 8),
                    _buildReadOnlyField("Notes", widget.mediaRelease.notes),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Right side: Catalog Metadata (editable) or import button.
        Expanded(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: widget.catalogRelease != null ? _buildCatalogForm() : _buildImportButton(),
            ),
          ),
        ),
      ],
    );
  }
}

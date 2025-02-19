import 'package:flutter/material.dart';

class SongLookupDialog extends StatefulWidget {
  final String currentTitle;
  final Function(String) onAddToOfficialList;
  final Function(String, String) onAddToAbbreviations;
  final Future<List<String>> Function(String) onSearch;

  const SongLookupDialog({
    Key? key,
    required this.currentTitle,
    required this.onAddToOfficialList,
    required this.onAddToAbbreviations,
    required this.onSearch,
  }) : super(key: key);

  @override
  State<SongLookupDialog> createState() => _SongLookupDialogState();
}

class _SongLookupDialogState extends State<SongLookupDialog> {
  String? _selectedTitle;
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Initial search with current title
    _performSearch(widget.currentTitle);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _performSearch(_searchController.text);
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await widget.onSearch(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Find Matching Song'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Current title: ${widget.currentTitle}'),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _searchResults.isEmpty
                        ? const Center(child: Text('No matching songs found'))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final title = _searchResults[index];
                          return ListTile(
                            title: Text(title),
                            selected: title == _selectedTitle,
                            onTap: () {
                              setState(() => _selectedTitle = title);
                              Navigator.of(context).pop(title);
                            },
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await widget.onAddToOfficialList(widget.currentTitle);
                    if (mounted) {
                      Navigator.of(context).pop(widget.currentTitle);
                    }
                  },
                  child: const Text('Add to Official List'),
                ),
                ElevatedButton(
                  onPressed: _selectedTitle == null
                      ? null
                      : () async {
                          await widget.onAddToAbbreviations(
                            widget.currentTitle.toLowerCase(),
                            _selectedTitle!,
                          );
                          if (mounted) {
                            Navigator.of(context).pop(_selectedTitle);
                          }
                        },
                  child: const Text('Add as Abbreviation'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
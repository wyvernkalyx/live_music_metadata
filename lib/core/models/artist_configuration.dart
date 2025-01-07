

class ArtistConfiguration {
  final String name;
  final String folderPrefix; // e.g., "gd" for Grateful Dead
  final RegExp? customRule; // Optional custom rule

  ArtistConfiguration({
    required this.name,
    required this.folderPrefix,
    this.customRule,
  });

  // Convert an ArtistConfiguration to a Map (for JSON serialization)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'folderPrefix': folderPrefix,
      'customRule': customRule?.pattern, // Store only the pattern as a string
    };
  }

  // Create an ArtistConfiguration from a Map (for JSON deserialization)
  factory ArtistConfiguration.fromJson(Map<String, dynamic> jsonMap) {
    return ArtistConfiguration(
      name: jsonMap['name'],
      folderPrefix: jsonMap['folderPrefix'],
      customRule: jsonMap['customRule'] != null
          ? RegExp(jsonMap['customRule'])
          : null,
    );
  }
}
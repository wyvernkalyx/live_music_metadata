import 'dart:io' show Platform;
import '../services/logger_service.dart';

class MetadataParser {
  // Core patterns
  // Standard format: "yyyy-MM-dd - venue - city, state - collection - volume - notes"
  static final RegExp _strictPattern = RegExp(
    r'^(?<Date>\d{4}-\d{2}-\d{2})\s*-\s*(?<Venue>[^-]+?)\s*-\s*(?<City>[^,]+?),\s*(?<State>[A-Za-z]{2})\s*(?:\s*-\s*(?<Collection>[^-]+?))?\s*(?:\s*-\s*Volume\s*(?<Volume>\d+))?\s*(?:\s*-\s*(?<Notes>.+))?$'
  );

  // Pattern to find state abbreviation anywhere in the string
  static final RegExp _statePattern = RegExp(r'\b([A-Z]{2})\b');
  static final RegExp _datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final RegExp _transitionPattern = RegExp(r'(?:\s*-+\s*>|\s*>)+\s*$');
  static final RegExp _dateInBracketsPattern = RegExp(r'\[\d{4}-\d{2}-\d{2}\]');
  static final RegExp _locationPattern = RegExp(r'([^,]+?),\s*([A-Za-z]{2})\s*$');

  // State abbreviations
  static final Map<String, String> stateAbbreviations = {
    'Alabama': 'AL', 'Alaska': 'AK', 'Arizona': 'AZ', 'Arkansas': 'AR', 'California': 'CA',
    'Colorado': 'CO', 'Connecticut': 'CT', 'Delaware': 'DE', 'Florida': 'FL', 'Georgia': 'GA',
    'Hawaii': 'HI', 'Idaho': 'ID', 'Illinois': 'IL', 'Indiana': 'IN', 'Iowa': 'IA',
    'Kansas': 'KS', 'Kentucky': 'KY', 'Louisiana': 'LA', 'Maine': 'ME', 'Maryland': 'MD',
    'Massachusetts': 'MA', 'Michigan': 'MI', 'Minnesota': 'MN', 'Mississippi': 'MS',
    'Missouri': 'MO', 'Montana': 'MT', 'Nebraska': 'NE', 'Nevada': 'NV', 'New Hampshire': 'NH',
    'New Jersey': 'NJ', 'New Mexico': 'NM', 'New York': 'NY', 'North Carolina': 'NC',
    'North Dakota': 'ND', 'Ohio': 'OH', 'Oklahoma': 'OK', 'Oregon': 'OR', 'Pennsylvania': 'PA',
    'Rhode Island': 'RI', 'South Carolina': 'SC', 'South Dakota': 'SD', 'Tennessee': 'TN',
    'Texas': 'TX', 'Utah': 'UT', 'Vermont': 'VT', 'Virginia': 'VA', 'Washington': 'WA',
    'West Virginia': 'WV', 'Wisconsin': 'WI', 'Wyoming': 'WY'
  };

  /// Parses metadata from an album title string
  /// Parses an album title, trying multiple strategies to extract metadata
  /// Parses an album title into its components, handling various formats:
  /// - "1969-02-21 - Dream Bowl - Vallejo - CA"
  /// - "1969-02-21 - Dream Bowl - Vallejo, CA"
  /// - "1969-02-21 - Dream Bowl, Vallejo, CA"
  static Map<String, String> parseMetadataFromAlbumTitle(String albumTitle) {
    LoggerService.instance.debug('Parsing album title: $albumTitle');
    final metadata = <String, String>{};
    
    // First try to parse with the strict pattern
    final strictMatch = _strictPattern.firstMatch(albumTitle);
    if (strictMatch != null) {
      metadata['DATE'] = strictMatch.namedGroup('Date')!;
      metadata['VENUE'] = strictMatch.namedGroup('Venue')!.trim();
      metadata['CITY'] = strictMatch.namedGroup('City')!.trim();
      metadata['STATE'] = _normalizeState(strictMatch.namedGroup('State')!) ?? '';
      
      // Optional fields
      if (strictMatch.namedGroup('Collection') != null) {
        metadata['COLLECTION'] = strictMatch.namedGroup('Collection')!.trim();
      }
      if (strictMatch.namedGroup('Volume') != null) {
        metadata['VOLUME'] = strictMatch.namedGroup('Volume')!;
      }
      if (strictMatch.namedGroup('Notes') != null) {
        metadata['NOTES'] = strictMatch.namedGroup('Notes')!.trim();
      }
      
      LoggerService.instance.debug('Parsed with strict pattern: $metadata');
      return metadata;
    }

    // If strict pattern fails, try parsing based on different formats
    final parts = albumTitle.split(' - ');
    
    if (parts.length == 4) {
      // Format: "1969-02-21 - Dream Bowl - Vallejo - CA"
      metadata['DATE'] = parts[0].trim();
      metadata['VENUE'] = parts[1].trim();
      metadata['CITY'] = parts[2].trim();
      final state = _normalizeState(parts[3].trim());
      if (state != null) {
        metadata['STATE'] = state;
      }
    } else if (parts.length == 3) {
      // Format: "1969-02-21 - Dream Bowl - Vallejo, CA"
      metadata['DATE'] = parts[0].trim();
      metadata['VENUE'] = parts[1].trim();
      final locationParts = parts[2].split(',');
      if (locationParts.length == 2) {
        metadata['CITY'] = locationParts[0].trim();
        final state = _normalizeState(locationParts[1].trim());
        if (state != null) {
          metadata['STATE'] = state;
        }
      }
    } else if (parts.length == 2) {
      // Format: "1969-02-21 - Dream Bowl, Vallejo, CA"
      metadata['DATE'] = parts[0].trim();
      final subParts = parts[1].split(',');
      if (subParts.length == 3) {
        metadata['VENUE'] = subParts[0].trim();
        metadata['CITY'] = subParts[1].trim();
        final state = _normalizeState(subParts[2].trim());
        if (state != null) {
          metadata['STATE'] = state;
        }
      }
    }
    
    // Look for collection and volume in any remaining parts
    final volumeMatch = RegExp(r'Volume\s*(\d+)', caseSensitive: false).firstMatch(albumTitle);
    if (volumeMatch != null) {
      metadata['VOLUME'] = volumeMatch.group(1)!;
      // Collection is typically before volume
      final beforeVol = albumTitle.substring(0, volumeMatch.start).trim();
      final collParts = beforeVol.split('-');
      if (collParts.isNotEmpty) {
        metadata['COLLECTION'] = collParts.last.trim();
      }
    }
    
    LoggerService.instance.debug('Parsed metadata: $metadata');
    return metadata;
  }

  /// Parses metadata from a file path
  static Map<String, String> parseMetadataFromPath(String filePath) {
    LoggerService.instance.debug('Parsing metadata from path: $filePath');
    final metadata = <String, String>{};
    final pathComponents = filePath.split(Platform.pathSeparator);
    final albumTitle = pathComponents.last;
    
    // Try strict pattern first
    final strictMatch = _strictPattern.firstMatch(albumTitle);
    if (strictMatch != null) {
      metadata['DATE'] = strictMatch.namedGroup('Date')!;
      metadata['VENUE'] = strictMatch.namedGroup('Venue')!.trim();
      metadata['CITY'] = strictMatch.namedGroup('City')!.trim();
      metadata['STATE'] = _normalizeState(strictMatch.namedGroup('State')!) ?? '';
      // Handle notes if present
      if (strictMatch.namedGroup('Notes') != null) {
        metadata['NOTES'] = strictMatch.namedGroup('Notes')!.trim();
      }

      // Handle extras (collection and volume)
      if (strictMatch.namedGroup('Extras') != null) {
        final extras = strictMatch.namedGroup('Extras')!;
        if (extras.contains('Vol.')) {
          final volMatch = RegExp(r'Vol\.\s*(\d+)').firstMatch(extras);
          if (volMatch != null) {
            metadata['VOLUME'] = volMatch.group(1)!;
            metadata['COLLECTION'] = extras.replaceAll(RegExp(r'Vol\.\s*\d+'), '').trim();
          }
        } else {
          metadata['COLLECTION'] = extras.trim();
        }
      }
      return metadata;
    }

    // Fallback: Look for date and location separately
    final dateMatch = _datePattern.firstMatch(albumTitle);
    if (dateMatch != null) {
      metadata['DATE'] = dateMatch.group(0)!;
      
      // Split remaining parts
      final parts = albumTitle.split('-').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      
      // Look for location (City, State)
      for (final part in parts) {
        final locationMatch = _locationPattern.firstMatch(part);
        if (locationMatch != null) {
          metadata['CITY'] = locationMatch.group(1)!.trim();
          final stateStr = locationMatch.group(2)!.trim();
          final state = _normalizeState(stateStr);
          if (state != null) {
            metadata['STATE'] = state;
            // Venue is typically the part before location
            final locationIndex = parts.indexOf(part);
            if (locationIndex > 0) {
              metadata['VENUE'] = parts[locationIndex - 1].trim();
            }
            break;
          }
        }
      }
    }
    
    LoggerService.instance.debug('Extracted metadata: $metadata');
    return metadata;
  }

  static String? _normalizeState(String stateInput) {
    if (stateInput.isEmpty) return null;
    
    // Clean and uppercase the input
    final cleanState = stateInput.trim().toUpperCase();
    
    // Already a valid abbreviation
    if (cleanState.length == 2) {
      if (stateAbbreviations.containsValue(cleanState)) {
        return cleanState;
      }
    }
    
    // Try to find abbreviation for state name
    for (final entry in stateAbbreviations.entries) {
      if (entry.key.toUpperCase() == cleanState) {
        return entry.value;
      }
    }
    
    return null;
  }

  static String? extractDateFromTitle(String title) {
    // First try to find a date in YYYY-MM-DD format
    final match = _datePattern.firstMatch(title);
    if (match != null) {
      return match.group(0)!;
    }
    
    // Then try to find date in brackets
    final bracketMatch = _dateInBracketsPattern.firstMatch(title);
    if (bracketMatch != null) {
      final date = bracketMatch.group(0)!.replaceAll(RegExp(r'[\[\]]'), '');
      if (_datePattern.hasMatch(date)) {
        return date;
      }
    }
    
    return null;
  }

  static String cleanDate(String input) {
    final match = _datePattern.firstMatch(input);
    return match?.group(0) ?? '';
  }

  static bool isValidDate(String date) {
    return _datePattern.hasMatch(date);
  }

  static bool hasTransition(String title) {
    return _transitionPattern.hasMatch(title);
  }

  static String removeTransitionMarker(String title) {
    return title.replaceAll(_transitionPattern, '').trim();
  }
}

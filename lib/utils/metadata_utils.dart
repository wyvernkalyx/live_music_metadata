// lib/utils/metadata_utils.dart
String assembleSongTitle(String title, String concertDate, String songDate, {bool isSegue = false}) {
  final dateToUse = (songDate != concertDate) ? songDate : concertDate;
  return isSegue ? "$title -> [$dateToUse]" : "$title [$dateToUse]";
}

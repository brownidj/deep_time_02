part of 'timeline_vertical_columns.dart';

void _debugCladeZoom(String message) {
  debugPrint('[CLADE_DEBUG] $message');
}

List<Clade> _filterCladesForMode({
  required List<Clade> source,
  required List<String> representativeIds,
  required CladeViewMode viewMode,
  required String searchQuery,
  required bool hasActiveRoot,
}) {
  if (!hasActiveRoot && viewMode == CladeViewMode.representativeOnly) {
    return _filterRepresentativeClades(source, representativeIds);
  }
  if (!hasActiveRoot && viewMode == CladeViewMode.searchSpotlight) {
    final query = searchQuery.trim();
    if (query.isEmpty) {
      return _filterRepresentativeClades(source, representativeIds);
    }
    return searchClades(source, query);
  }
  return source;
}

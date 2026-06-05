enum CladeViewMode { representativeOnly, byCategory, searchSpotlight }

extension CladeViewModeMeta on CladeViewMode {
  String get id {
    switch (this) {
      case CladeViewMode.representativeOnly:
        return 'representative_only';
      case CladeViewMode.byCategory:
        return 'by_category';
      case CladeViewMode.searchSpotlight:
        return 'search_spotlight';
    }
  }

  String get label {
    switch (this) {
      case CladeViewMode.representativeOnly:
        return 'Representative clades';
      case CladeViewMode.byCategory:
        return 'By category';
      case CladeViewMode.searchSpotlight:
        return 'Search / spotlight';
    }
  }
}

CladeViewMode parseCladeViewMode(String? value) {
  switch (value) {
    case 'by_category':
      return CladeViewMode.byCategory;
    case 'search_spotlight':
      return CladeViewMode.searchSpotlight;
    case 'representative_only':
    default:
      return CladeViewMode.representativeOnly;
  }
}

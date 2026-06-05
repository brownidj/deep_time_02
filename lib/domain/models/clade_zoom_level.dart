enum CladeZoomLevel { whole, phanerozoic, era, period, epoch }

extension CladeZoomLevelId on CladeZoomLevel {
  String get id {
    switch (this) {
      case CladeZoomLevel.whole:
        return 'whole';
      case CladeZoomLevel.phanerozoic:
        return 'phanerozoic';
      case CladeZoomLevel.era:
        return 'era';
      case CladeZoomLevel.period:
        return 'period';
      case CladeZoomLevel.epoch:
        return 'epoch';
    }
  }
}

CladeZoomLevel parseCladeZoomLevel(String? value) {
  switch (value) {
    case 'phanerozoic':
      return CladeZoomLevel.phanerozoic;
    case 'era':
      return CladeZoomLevel.era;
    case 'period':
      return CladeZoomLevel.period;
    case 'epoch':
      return CladeZoomLevel.epoch;
    case 'whole':
    default:
      return CladeZoomLevel.whole;
  }
}

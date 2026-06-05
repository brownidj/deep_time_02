enum CladeLabelMode { common, scientific, both }

extension CladeLabelModeMeta on CladeLabelMode {
  String get id {
    switch (this) {
      case CladeLabelMode.common:
        return 'common';
      case CladeLabelMode.scientific:
        return 'scientific';
      case CladeLabelMode.both:
        return 'both';
    }
  }

  String get label {
    switch (this) {
      case CladeLabelMode.common:
        return 'Common';
      case CladeLabelMode.scientific:
        return 'Scientific';
      case CladeLabelMode.both:
        return 'Both';
    }
  }
}

CladeLabelMode parseCladeLabelMode(String? value) {
  switch (value) {
    case 'scientific':
      return CladeLabelMode.scientific;
    case 'both':
      return CladeLabelMode.both;
    case 'common':
    default:
      return CladeLabelMode.common;
  }
}

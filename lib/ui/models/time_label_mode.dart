enum TimeLabelMode { geologicTime, stratigraphic }

extension TimeLabelModeLabels on TimeLabelMode {
  String get id {
    switch (this) {
      case TimeLabelMode.geologicTime:
        return 'geologic_time';
      case TimeLabelMode.stratigraphic:
        return 'stratigraphic';
    }
  }

  String get displayName {
    switch (this) {
      case TimeLabelMode.geologicTime:
        return 'Geologic time';
      case TimeLabelMode.stratigraphic:
        return 'Stratigraphic';
    }
  }

  String labelForRank(String rank) {
    final normalized = rank.toLowerCase();
    switch (this) {
      case TimeLabelMode.geologicTime:
        switch (normalized) {
          case 'eon':
            return 'Eon';
          case 'era':
            return 'Era';
          case 'period':
            return 'Period';
          case 'epoch':
            return 'Epoch';
          case 'stage':
          case 'age':
            return 'Age';
          default:
            return rank;
        }
      case TimeLabelMode.stratigraphic:
        switch (normalized) {
          case 'eon':
            return 'Eonothem';
          case 'era':
            return 'Erathem';
          case 'period':
            return 'System';
          case 'epoch':
            return 'Series';
          case 'stage':
          case 'age':
            return 'Stage';
          default:
            return rank;
        }
    }
  }

  String divisionRowLabel() {
    switch (this) {
      case TimeLabelMode.geologicTime:
        return 'Period';
      case TimeLabelMode.stratigraphic:
        return 'System';
    }
  }

  String seriesRowLabel() {
    switch (this) {
      case TimeLabelMode.geologicTime:
        return 'Epoch';
      case TimeLabelMode.stratigraphic:
        return 'Series';
    }
  }

  String stageRowLabel() {
    switch (this) {
      case TimeLabelMode.geologicTime:
        return 'Age';
      case TimeLabelMode.stratigraphic:
        return 'Stage';
    }
  }
}

TimeLabelMode parseTimeLabelMode(String? value) {
  switch (value) {
    case 'stratigraphic':
      return TimeLabelMode.stratigraphic;
    case 'geologic_time':
    default:
      return TimeLabelMode.geologicTime;
  }
}

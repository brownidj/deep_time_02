import 'package:deep_time_2/domain/models/clade.dart';
import 'package:deep_time_2/domain/models/clade_zoom_level.dart';

class CladeVisibilityResolver {
  const CladeVisibilityResolver({this.maxClades = 12});

  final int maxClades;

  CladeZoomLevel zoomLevelForScale(double scale) {
    if (scale < 1.8) {
      return CladeZoomLevel.whole;
    }
    if (scale < 2.4) {
      return CladeZoomLevel.phanerozoic;
    }
    if (scale < 3.0) {
      return CladeZoomLevel.era;
    }
    if (scale < 3.4) {
      return CladeZoomLevel.period;
    }
    return CladeZoomLevel.epoch;
  }

  List<Clade> resolve({
    required List<Clade> clades,
    required CladeZoomLevel zoomLevel,
    required double visibleStartMa,
    required double visibleEndMa,
    String? displayGroupId,
  }) {
    final filtered = clades.where((clade) {
      if (!_overlaps(clade, visibleStartMa, visibleEndMa)) {
        return false;
      }
      if (clade.minZoomLevel.index > zoomLevel.index) {
        return false;
      }
      if (displayGroupId != null &&
          displayGroupId.isNotEmpty &&
          displayGroupId != 'all') {
        return clade.displayGroups.contains(displayGroupId);
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      final priority = a.displayPriority.compareTo(b.displayPriority);
      if (priority != 0) {
        return priority;
      }
      final duration = b.durationMa.compareTo(a.durationMa);
      if (duration != 0) {
        return duration;
      }
      return a.label.compareTo(b.label);
    });

    if (filtered.length <= maxClades) {
      return filtered;
    }
    return filtered.take(maxClades).toList();
  }

  bool _overlaps(Clade clade, double visibleStartMa, double visibleEndMa) {
    final cladeMin = clade.endMa;
    final cladeMax = clade.startMa;
    final viewMin = visibleEndMa;
    final viewMax = visibleStartMa;
    return !(cladeMax < viewMin || cladeMin > viewMax);
  }
}

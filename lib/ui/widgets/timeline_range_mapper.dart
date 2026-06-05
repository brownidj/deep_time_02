import 'package:deep_time_2/application/services/timeline_layout_models.dart';

class TimelineRangeMapper {
  TimelineRangeMapper({
    required this.segments,
    required this.totalUnits,
    required this.scrollWidth,
    required this.oldestMa,
    required this.youngestMa,
  });

  final List<TimelineRowSegment> segments;
  final double totalUnits;
  final double scrollWidth;
  final double oldestMa;
  final double youngestMa;

  double? maForX(double x) {
    if (segments.isEmpty || totalUnits <= 0 || scrollWidth <= 0) {
      return null;
    }
    final unitPos = (x / scrollWidth) * totalUnits;
    var cursor = 0.0;
    for (final segment in segments) {
      final start = cursor;
      cursor += segment.unitSpan;
      if (unitPos <= cursor) {
        if (segment.isGap || segment.unitSpan <= 0) {
          return null;
        }
        final span = segment.startMa - segment.endMa;
        if (span <= 0) {
          return segment.startMa;
        }
        final fraction = (unitPos - start) / segment.unitSpan;
        return segment.startMa - (span * fraction);
      }
    }
    return youngestMa;
  }

  double? xForMa(double ma) {
    if (segments.isEmpty || totalUnits <= 0 || scrollWidth <= 0) {
      return null;
    }
    if (ma >= oldestMa) {
      return 0;
    }
    if (ma <= youngestMa) {
      return scrollWidth;
    }
    var cursor = 0.0;
    for (final segment in segments) {
      final start = segment.startMa;
      final end = segment.endMa;
      if (!segment.isGap && ma <= start && ma >= end) {
        final span = start - end;
        final fraction = span <= 0 ? 0.0 : (start - ma) / span;
        return scrollWidth * ((cursor + segment.unitSpan * fraction) / totalUnits);
      }
      cursor += segment.unitSpan;
    }
    return null;
  }
}

import 'package:deep_time_2/application/services/timeline_layout_service.dart';

class SelectedDivision {
  const SelectedDivision({
    required this.id,
    required this.label,
    required this.startMa,
    required this.endMa,
  });

  factory SelectedDivision.fromRow(TimelineRowSegment segment) {
    return SelectedDivision(
      id: segment.id,
      label: segment.label,
      startMa: segment.startMa,
      endMa: segment.endMa,
    );
  }

  factory SelectedDivision.fromBand(TimelineBandSegment segment) {
    return SelectedDivision(
      id: segment.id,
      label: segment.label,
      startMa: segment.startMa,
      endMa: segment.endMa,
    );
  }

  final int id;
  final String label;
  final double startMa;
  final double endMa;

  double get durationMa => startMa - endMa;
}

extension SegmentList on List<TimelineRowSegment> {
  TimelineRowSegment? get firstNonGap {
    for (final segment in this) {
      if (!segment.isGap) {
        return segment;
      }
    }
    return null;
  }
}

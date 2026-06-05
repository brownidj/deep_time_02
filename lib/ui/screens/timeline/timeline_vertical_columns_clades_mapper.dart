part of 'timeline_vertical_columns.dart';

class _StageRangeMapper {
  _StageRangeMapper({
    required this.stageSegments,
    required this.stageHeights,
    required this.epochSegments,
    required this.epochHeights,
    required this.periodSegments,
    required this.periodHeights,
    required this.eraSegments,
    required this.eraHeights,
    required this.eonSegments,
    required this.eonHeights,
    required this.totalHeight,
    required this.oldestMa,
    required this.youngestMa,
  }) : _tracks = [
         _buildRowTrack(stageSegments, stageHeights),
         _buildRowTrack(epochSegments, epochHeights),
         _buildRowTrack(periodSegments, periodHeights),
         _buildBandTrack(eraSegments, eraHeights),
         _buildBandTrack(eonSegments, eonHeights),
       ];

  final List<TimelineRowSegment> stageSegments;
  final List<double> stageHeights;
  final List<TimelineRowSegment> epochSegments;
  final List<double> epochHeights;
  final List<TimelineRowSegment> periodSegments;
  final List<double> periodHeights;
  final List<TimelineBandSegment> eraSegments;
  final List<double> eraHeights;
  final List<TimelineBandSegment> eonSegments;
  final List<double> eonHeights;
  final double totalHeight;
  final double oldestMa;
  final double youngestMa;
  final List<List<_SegmentSlice>> _tracks;

  static List<_SegmentSlice> _buildRowTrack(
    List<TimelineRowSegment> segments,
    List<double> heights,
  ) {
    final track = <_SegmentSlice>[];
    var top = 0.0;
    final last = math.min(segments.length, heights.length);
    for (var i = 0; i < last; i += 1) {
      final segment = segments[i];
      final height = heights[i];
      track.add(
        _SegmentSlice(
          startMa: segment.startMa,
          endMa: segment.endMa,
          top: top,
          height: height,
          hasContent:
              !segment.isGap &&
              segment.label.trim().isNotEmpty &&
              segment.colorKey.trim().isNotEmpty,
        ),
      );
      top += height;
    }
    return track;
  }

  static List<_SegmentSlice> _buildBandTrack(
    List<TimelineBandSegment> segments,
    List<double> heights,
  ) {
    final track = <_SegmentSlice>[];
    var top = 0.0;
    final last = math.min(segments.length, heights.length);
    for (var i = 0; i < last; i += 1) {
      final segment = segments[i];
      final height = heights[i];
      track.add(
        _SegmentSlice(
          startMa: segment.startMa,
          endMa: segment.endMa,
          top: top,
          height: height,
          hasContent:
              !segment.isGap &&
              segment.label.trim().isNotEmpty &&
              segment.colorKey.trim().isNotEmpty,
        ),
      );
      top += height;
    }
    return track;
  }

  _SegmentSlice? _bestContentSliceForMa(double ma) {
    for (final track in _tracks) {
      for (final slice in track) {
        if (!slice.hasContent) {
          continue;
        }
        if (ma <= slice.startMa && ma >= slice.endMa) {
          return slice;
        }
      }
    }
    return null;
  }

  double? yForMa(double ma) {
    if (_tracks.isEmpty || totalHeight <= 0) {
      return null;
    }
    if (ma >= oldestMa) {
      return 0;
    }
    if (ma <= youngestMa) {
      return totalHeight;
    }
    final slice = _bestContentSliceForMa(ma);
    if (slice != null) {
      final span = slice.startMa - slice.endMa;
      final fraction = span <= 0 ? 0.0 : (slice.startMa - ma) / span;
      return slice.top + (slice.height * fraction.clamp(0.0, 1.0));
    }
    final globalSpan = oldestMa - youngestMa;
    if (globalSpan <= 0) {
      return null;
    }
    final globalFraction = ((oldestMa - ma) / globalSpan).clamp(0.0, 1.0);
    return totalHeight * globalFraction;
  }

  double? maForY(double y) {
    if (_tracks.isEmpty || totalHeight <= 0) {
      return null;
    }
    if (y <= 0) {
      return oldestMa;
    }
    if (y >= totalHeight) {
      return youngestMa;
    }
    for (final track in _tracks) {
      for (final slice in track) {
        final bottom = slice.top + slice.height;
        if (y <= bottom) {
          if (!slice.hasContent || slice.height <= 0) {
            break;
          }
          final span = slice.startMa - slice.endMa;
          if (span <= 0) {
            return slice.startMa;
          }
          final localFraction = ((y - slice.top) / slice.height).clamp(
            0.0,
            1.0,
          );
          return slice.startMa - (span * localFraction);
        }
      }
    }
    return youngestMa;
  }
}

class _SegmentSlice {
  const _SegmentSlice({
    required this.startMa,
    required this.endMa,
    required this.top,
    required this.height,
    required this.hasContent,
  });

  final double startMa;
  final double endMa;
  final double top;
  final double height;
  final bool hasContent;
}

import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/domain/models/timeline_marker_catalog.dart';

class TimelineEventsBuilder {
  TimelineEventsBuilder({required this.definitions});

  final List<TimelineEventDefinition> definitions;

  List<TimelineEventSegment> buildEventsRow({
    required List<TimelineRowSegment> periodSegments,
    required List<TimelineBandSegment> eraSegments,
  }) {
    final periodRanges = _buildRangesFromRows(periodSegments);
    final eraRanges = _buildRangesFromBands(eraSegments);
    if (periodRanges.isEmpty && eraRanges.isEmpty) {
      return const [];
    }

    final events = <TimelineEventSegment>[];
    for (final definition in definitions) {
      final range = _resolveRange(definition);
      if (range == null) {
        continue;
      }
      final colorKey = _colorKeyForRange(range, periodSegments, eraSegments);
      final startUnit = _unitForMa(range.startMa, periodRanges, eraRanges);
      final endUnit = _unitForMa(range.endMa, periodRanges, eraRanges);
      events.add(
        TimelineEventSegment(
          id: definition.id,
          label: definition.label,
          shortLabel: definition.shortLabel,
          type: _eventTypeFor(definition.kind),
          explanation: definition.explanation,
          image: definition.image,
          sourcePage: definition.sourcePage,
          imageLicense: definition.imageLicense,
          imageLicenseUrl: definition.imageLicenseUrl,
          imageAuthor: definition.imageAuthor,
          imageCredit: definition.imageCredit,
          localAssetImage: definition.localAssetImage,
          startMa: range.startMa,
          endMa: range.endMa,
          startUnit: startUnit <= endUnit ? startUnit : endUnit,
          endUnit: startUnit <= endUnit ? endUnit : startUnit,
          colorKey: colorKey,
        ),
      );
    }
    return events;
  }

  TimelineEventType _eventTypeFor(TimelineEventKind kind) {
    switch (kind) {
      case TimelineEventKind.bar:
        return TimelineEventType.bar;
      case TimelineEventKind.point:
        return TimelineEventType.point;
    }
  }

  List<_UnitRange> _buildRangesFromRows(List<TimelineRowSegment> segments) {
    final ranges = <_UnitRange>[];
    var cursor = 0.0;
    for (final segment in segments) {
      final unitStart = cursor;
      final unitEnd = cursor + segment.unitSpan;
      ranges.add(
        _UnitRange(
          startMa: segment.startMa,
          endMa: segment.endMa,
          unitStart: unitStart,
          unitEnd: unitEnd,
          isGap: segment.isGap,
        ),
      );
      cursor = unitEnd;
    }
    return ranges;
  }

  List<_UnitRange> _buildRangesFromBands(List<TimelineBandSegment> segments) {
    final ranges = <_UnitRange>[];
    var cursor = 0.0;
    for (final segment in segments) {
      final unitStart = cursor;
      final unitEnd = cursor + segment.unitSpan;
      ranges.add(
        _UnitRange(
          startMa: segment.startMa,
          endMa: segment.endMa,
          unitStart: unitStart,
          unitEnd: unitEnd,
          isGap: segment.isGap,
        ),
      );
      cursor = unitEnd;
    }
    return ranges;
  }

  double _unitForMa(
    double ma,
    List<_UnitRange> primary,
    List<_UnitRange> fallback,
  ) {
    final primaryValue = _unitForMaInRanges(ma, primary);
    if (primaryValue != null) {
      return primaryValue;
    }
    final fallbackValue = _unitForMaInRanges(ma, fallback);
    if (fallbackValue != null) {
      return fallbackValue;
    }
    if (primary.isNotEmpty) {
      if (ma >= primary.first.startMa) {
        return primary.first.unitStart;
      }
      return primary.last.unitEnd;
    }
    if (fallback.isNotEmpty) {
      if (ma >= fallback.first.startMa) {
        return fallback.first.unitStart;
      }
      return fallback.last.unitEnd;
    }
    return 0;
  }

  double? _unitForMaInRanges(double ma, List<_UnitRange> ranges) {
    for (final range in ranges) {
      if (range.isGap) {
        continue;
      }
      if (ma <= range.startMa && ma >= range.endMa) {
        final span = range.startMa - range.endMa;
        if (span <= 0) {
          return range.unitStart;
        }
        final fraction = (range.startMa - ma) / span;
        return range.unitStart + (range.unitEnd - range.unitStart) * fraction;
      }
    }
    return null;
  }

  String _colorKeyForRange(
    _MaRange range,
    List<TimelineRowSegment> periodSegments,
    List<TimelineBandSegment> eraSegments,
  ) {
    final startPeriod = _segmentForMa(periodSegments, range.startMa);
    final endPeriod = _segmentForMa(periodSegments, range.endMa);
    if (startPeriod != null &&
        endPeriod != null &&
        startPeriod.label == endPeriod.label) {
      return startPeriod.colorKey;
    }
    final era = _bandForMa(eraSegments, (range.startMa + range.endMa) / 2);
    if (era != null) {
      return era.colorKey;
    }
    return '';
  }

  TimelineRowSegment? _segmentForMa(
    List<TimelineRowSegment> segments,
    double ma,
  ) {
    for (final segment in segments) {
      if (segment.isGap) {
        continue;
      }
      if (ma <= segment.startMa && ma >= segment.endMa) {
        return segment;
      }
    }
    return null;
  }

  TimelineBandSegment? _bandForMa(
    List<TimelineBandSegment> segments,
    double ma,
  ) {
    for (final segment in segments) {
      if (segment.isGap) {
        continue;
      }
      if (ma <= segment.startMa && ma >= segment.endMa) {
        return segment;
      }
    }
    return null;
  }

  _MaRange? _resolveRange(TimelineEventDefinition definition) {
    if (definition.startMa != null && definition.endMa != null) {
      return _MaRange(startMa: definition.startMa!, endMa: definition.endMa!);
    }
    if (definition.atMa != null) {
      return _MaRange(startMa: definition.atMa!, endMa: definition.atMa!);
    }
    return null;
  }
}

class _MaRange {
  const _MaRange({required this.startMa, required this.endMa});

  final double startMa;
  final double endMa;
}

class _UnitRange {
  const _UnitRange({
    required this.startMa,
    required this.endMa,
    required this.unitStart,
    required this.unitEnd,
    required this.isGap,
  });

  final double startMa;
  final double endMa;
  final double unitStart;
  final double unitEnd;
  final bool isGap;
}

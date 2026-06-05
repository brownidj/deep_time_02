import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/domain/models/paleo_ecology_entry.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_min_height_helpers_calculations.dart';

const double _fallbackWidth = 40.0;

String formatMaLabel(double value) {
  return value.toStringAsFixed(1);
}

double minimalHorizontalLabelWidth(String label, {TextStyle? style}) {
  if (label.trim().isEmpty) {
    return _fallbackWidth;
  }
  final painter = TextPainter(
    text: TextSpan(text: label, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  return painter.width + 16;
}

double eventBarTrackWidth(
  List<TimelineEventSegment> events, {
  TextStyle? style,
  double horizontalPadding = 3,
  double laneGap = 4,
  double? laneWidth,
}) {
  final barEvents = events
      .where((event) => event.type == TimelineEventType.bar)
      .toList();
  if (barEvents.isEmpty) {
    return 0.0;
  }
  final laneCount = overlappingEventBarLaneCount(barEvents);
  final resolvedLaneWidth =
      laneWidth ??
      math.max(
        3.0,
        ((style?.fontSize ?? 14.0) * (style?.height ?? 1.0)) + 18.0,
      );
  return (laneCount * resolvedLaneWidth) +
      (math.max(0, laneCount - 1) * laneGap) +
      (horizontalPadding * 2);
}

double eventPointLabelInsetWidth(
  List<TimelineEventSegment> events, {
  TextStyle? style,
}) {
  final pointEvents = events
      .where((event) => event.type == TimelineEventType.point)
      .toList(growable: false);
  if (pointEvents.isEmpty || style == null) {
    return 0.0;
  }
  const markerLeft = 0.0;
  const markerSize = 9.0;
  const markerLabelGap = 6.0;
  const barGapFromLabel = 8.0;
  final textLeft = markerLeft + markerSize + markerLabelGap;
  var maxLabelWidth = 0.0;
  for (final event in pointEvents) {
    final painter = TextPainter(
      text: TextSpan(text: event.shortLabel, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    if (painter.width > maxLabelWidth) {
      maxLabelWidth = painter.width;
    }
  }
  return textLeft + maxLabelWidth + barGapFromLabel;
}

int overlappingEventBarLaneCount(List<TimelineEventSegment> barEvents) {
  if (barEvents.isEmpty) {
    return 0;
  }
  final sorted = barEvents.toList()
    ..sort((a, b) {
      final startCompare = b.startMa.compareTo(a.startMa);
      if (startCompare != 0) {
        return startCompare;
      }
      return b.endMa.compareTo(a.endMa);
    });

  final laneBottoms = <double>[];
  for (final event in sorted) {
    final top = math.min(event.startUnit, event.endUnit);
    final bottom = math.max(event.startUnit, event.endUnit);
    var lane = 0;
    for (; lane < laneBottoms.length; lane += 1) {
      if (top >= laneBottoms[lane]) {
        break;
      }
    }
    if (lane == laneBottoms.length) {
      laneBottoms.add(bottom);
    } else {
      laneBottoms[lane] = bottom;
    }
  }
  return laneBottoms.length;
}

double minimalVerticalLabelWidth(String label, {TextStyle? style}) {
  if (label.trim().isEmpty) {
    return 36.0;
  }
  final painter = TextPainter(
    text: TextSpan(text: label, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  return painter.height + 12;
}

double segmentLabelWidth(
  List<TimelineRowSegment> segments, {
  TextStyle? style,
  double horizontalPadding = 12,
}) {
  var maxWidth = 0.0;
  for (final segment in segments) {
    final label = segment.label.trim();
    if (label.isEmpty) {
      continue;
    }
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final width = painter.width + horizontalPadding;
    if (width > maxWidth) {
      maxWidth = width;
    }
  }
  return maxWidth;
}

double maColumnWidth(
  TimelineLayoutSnapshot layout, {
  TextStyle? style,
  double padding = 12,
}) {
  var maxWidth = minimalHorizontalLabelWidth('Ma', style: style);
  for (final segment in layout.eonSegments) {
    if (segment.isGap) {
      continue;
    }
    final width = labelWidth(formatMaLabel(segment.endMa), style: style);
    if (width > maxWidth) {
      maxWidth = width;
    }
  }
  for (final segment in layout.eraSegments) {
    if (segment.isGap) {
      continue;
    }
    final width = labelWidth(formatMaLabel(segment.endMa), style: style);
    if (width > maxWidth) {
      maxWidth = width;
    }
  }
  return maxWidth + padding;
}

double labelWidth(String label, {TextStyle? style}) {
  final painter = TextPainter(
    text: TextSpan(text: label, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  return painter.width;
}

double maxLabelWidth(
  List<String> labels, {
  TextStyle? style,
  double padding = 0,
  double fallback = _fallbackWidth,
}) {
  var maxWidth = 0.0;
  for (final label in labels) {
    final text = label.trim();
    if (text.isEmpty) {
      continue;
    }
    final width = labelWidth(text, style: style) + padding;
    if (width > maxWidth) {
      maxWidth = width;
    }
  }
  return maxWidth > 0 ? maxWidth : fallback;
}

double minScrollHeightForStages(
  TimelineLayoutSnapshot layout, {
  TextStyle? style,
  List<PaleoEcologyEntry> paleoEcology = const [],
  double paleoWidth = 0,
  TextStyle? paleoStyle,
  double verticalPadding = 4,
}) {
  final segments = layout.stageSegments;
  if (segments.isEmpty) {
    return 0.0;
  }
  final stageHeights = buildStageMinHeights(
    segments,
    style,
    verticalPadding: verticalPadding,
    divisions: layout.divisions,
    paleoEcology: paleoEcology,
    paleoWidth: paleoWidth,
    paleoStyle: paleoStyle ?? style,
  );
  var total = 0.0;
  for (final segment in segments) {
    if (segment.isGap || segment.label.trim().isEmpty) {
      continue;
    }
    total += stageHeights[segment.id] ?? 0.0;
  }
  return total;
}

double extinctionsTrackWidthForLabels(
  List<String> labels, {
  TextStyle? style,
  double markerLeft = 0,
  double markerSize = 13,
  double labelGap = 6,
  double rightPadding = 6,
  String fallbackLabel = 'Ext.',
}) {
  var maxWidth = 0.0;
  for (final label in labels) {
    final text = label.trim();
    if (text.isEmpty) {
      continue;
    }
    final width = labelWidth(text, style: style);
    if (width > maxWidth) {
      maxWidth = width;
    }
  }
  if (maxWidth <= 0) {
    maxWidth = labelWidth(fallbackLabel, style: style);
  }
  return markerLeft + markerSize + labelGap + maxWidth + rightPadding;
}

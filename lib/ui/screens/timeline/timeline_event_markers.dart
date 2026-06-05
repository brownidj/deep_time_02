import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:deep_time_2/application/services/timeline_layout_service.dart';
import 'package:deep_time_2/ui/widgets/timeline_explanation_dialog.dart';
import 'package:deep_time_2/ui/widgets/time_range_format.dart';

part 'timeline_event_marker_widgets.dart';

class EventPointMarkers extends StatelessWidget {
  const EventPointMarkers({
    super.key,
    required this.width,
    required this.totalUnits,
    required this.events,
    required this.height,
    required this.lineTop,
    required this.markerTop,
    this.showMarkers = true,
    this.showLines = true,
    this.showLineHitTargets = false,
  });

  final double width;
  final double totalUnits;
  final List<TimelineEventSegment> events;
  final double height;
  final double lineTop;
  final double markerTop;
  final bool showMarkers;
  final bool showLines;
  final bool showLineHitTargets;

  static const markerHeight = 14.0;
  static const triangleWidth = 12.0;
  static const markerColor = Color(0xFFFFEB3B);

  @override
  Widget build(BuildContext context) {
    if (totalUnits <= 0 || !width.isFinite || width <= 0) {
      return const SizedBox.shrink();
    }
    final pointEvents = events
        .where((event) => event.type == TimelineEventType.point)
        .toList();
    if (pointEvents.isEmpty) {
      return const SizedBox.shrink();
    }
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: markerColor,
      fontWeight: FontWeight.w700,
    );
    if (labelStyle == null) {
      return const SizedBox.shrink();
    }
    final stackedLevels = <List<_Span>>[[]];
    final markerOffsets = <TimelineEventSegment, double>{};
    for (final event in pointEvents) {
      final center = (event.startUnit / totalUnits * width);
      if (!center.isFinite) {
        continue;
      }
      final textPainter = TextPainter(
        text: TextSpan(text: event.shortLabel, style: labelStyle),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      final markerWidth = math.max(textPainter.width, triangleWidth);
      final span = _Span(center: center, halfWidth: markerWidth / 2);
      var levelIndex = 0;
      while (true) {
        if (levelIndex >= stackedLevels.length) {
          stackedLevels.add([]);
        }
        final overlaps = stackedLevels[levelIndex].any(
          (existing) => existing.overlaps(span, padding: 4),
        );
        if (!overlaps) {
          stackedLevels[levelIndex].add(span);
          markerOffsets[event] = levelIndex * (textPainter.height + 10);
          break;
        }
        levelIndex += 1;
      }
    }
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (showMarkers)
            for (final event in pointEvents)
              if ((event.startUnit / totalUnits * width).isFinite)
                Positioned(
                  left: (event.startUnit / totalUnits * width).clamp(
                    0.0,
                    width,
                  ),
                  top: markerTop + (markerOffsets[event] ?? 0),
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, 0),
                    child: _EventMarker(
                      label: event.shortLabel,
                      pointUp: true,
                      explanation: event.explanation,
                      title: event.label,
                      tooltip: formatTimeRange(
                        startMa: event.startMa,
                        endMa: event.startMa == event.endMa
                            ? null
                            : event.endMa,
                        startPrecision: 1,
                        endPrecision: 1,
                        durationPrecision: 1,
                      ),
                    ),
                  ),
                ),
          if (showLines)
            for (final event in pointEvents)
              if ((event.startUnit / totalUnits * width).isFinite &&
                  (markerTop + (markerOffsets[event] ?? 0)) > lineTop)
                Positioned(
                  left: (event.startUnit / totalUnits * width - 0.5).clamp(
                    0.0,
                    width - 1,
                  ),
                  top: lineTop,
                  height: (markerTop + (markerOffsets[event] ?? 0) - lineTop)
                      .clamp(0.0, height),
                  child: Container(width: 1, color: markerColor),
                ),
          if (showLineHitTargets)
            for (final event in pointEvents)
              if ((event.startUnit / totalUnits * width).isFinite &&
                  (markerTop + (markerOffsets[event] ?? 0)) > lineTop)
                Positioned(
                  left: (event.startUnit / totalUnits * width - 6).clamp(
                    0.0,
                    width - 12,
                  ),
                  top: lineTop,
                  height: (markerTop + (markerOffsets[event] ?? 0) - lineTop)
                      .clamp(0.0, height),
                  child: SizedBox(
                    width: 12,
                    child: _EventLineHitTarget(
                      title: event.label,
                      explanation: event.explanation,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _EventLineHitTarget extends StatelessWidget {
  const _EventLineHitTarget({required this.title, required this.explanation});

  final String title;
  final String? explanation;

  @override
  Widget build(BuildContext context) {
    final hasExplanation =
        explanation != null && explanation!.trim().isNotEmpty;
    if (!hasExplanation) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => showTimelineExplanationDialog(
        context: context,
        title: title,
        explanation: explanation!.trim(),
      ),
    );
  }
}

class _Span {
  const _Span({required this.center, required this.halfWidth});

  final double center;
  final double halfWidth;

  bool overlaps(_Span other, {double padding = 0}) {
    return (center - other.center).abs() <
        (halfWidth + other.halfWidth + padding);
  }
}

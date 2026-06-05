import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:deep_time_2/application/services/timeline_layout_service.dart';
import 'package:deep_time_2/domain/models/timeline_marker_catalog.dart';
import 'package:deep_time_2/ui/widgets/timeline_explanation_dialog.dart';
import 'package:deep_time_2/ui/widgets/time_range_format.dart';

part 'timeline_extinction_marker_widgets.dart';

class ExtinctionMarkers extends StatelessWidget {
  const ExtinctionMarkers({
    super.key,
    required this.width,
    required this.height,
    required this.periodSegments,
    required this.stageSegments,
    required this.lineTop,
    required this.triangleTip,
    this.extinctions = const [],
    this.markerLayouts,
    this.showMarkers = true,
    this.showLines = true,
    this.showLineHitTargets = false,
  });

  static const markerHeight = 14.0;
  static const triangleWidth = 12.0;
  static const majorMarkerHeight = 42.0;
  static const majorTriangleWidth = 36.0;
  static const lineWidth = 1.0;
  static const markerColor = Color(0xFFFF6D00);

  final double width;
  final double height;
  final double lineTop;
  final double triangleTip;
  final List<TimelineRowSegment> periodSegments;
  final List<TimelineRowSegment> stageSegments;
  final List<ExtinctionDefinition> extinctions;
  final List<ExtinctionMarkerLayout>? markerLayouts;
  final bool showMarkers;
  final bool showLines;
  final bool showLineHitTargets;

  @override
  Widget build(BuildContext context) {
    final markers =
        markerLayouts ??
        ExtinctionMarkers.buildMarkerLayouts(
          width: width,
          periodSegments: periodSegments,
          stageSegments: stageSegments,
          extinctions: extinctions,
        );
    if (markers.isEmpty) {
      return const SizedBox.shrink();
    }
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Colors.black,
      fontWeight: FontWeight.w700,
    );
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (showMarkers)
            for (final marker in markers)
              if (textStyle != null)
                Positioned(
                  left: _centeredLeftForMarker(
                    marker: marker,
                    textStyle: textStyle,
                  ).clamp(0.0, width),
                  top: triangleTip,
                  child: Tooltip(
                    message: marker.ma == null
                        ? marker.label
                        : '${marker.label} • '
                            '${formatTimeRange(
                              startMa: marker.ma!,
                              endMa: null,
                              startPrecision: 1,
                              durationPrecision: 1,
                            )}',
                    child: _ExtinctionMarker(
                      label: marker.isMajor ? marker.label : marker.shortLabel,
                      isMajor: marker.isMajor,
                      pointUp: true,
                      explanation: marker.explanation,
                    ),
                  ),
                ),
          if (showLines)
            for (final marker in markers)
              Positioned(
                left: (marker.x - lineWidth / 2).clamp(0.0, width - lineWidth),
                top: lineTop,
                height: (triangleTip - lineTop).clamp(0.0, height),
                child: Container(width: lineWidth, color: markerColor),
              ),
          if (showLineHitTargets)
            for (final marker in markers)
              Positioned(
                left: (marker.x - 6).clamp(0.0, width - 12),
                top: lineTop,
                height: (triangleTip - lineTop).clamp(0.0, height),
                child: SizedBox(
                  width: 12,
                  child: _ExtinctionLineHitTarget(
                    title: marker.label,
                    explanation: marker.explanation,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  static List<ExtinctionMarkerLayout> buildMarkerLayouts({
    required double width,
    required List<TimelineRowSegment> periodSegments,
    required List<TimelineRowSegment> stageSegments,
    required List<ExtinctionDefinition> extinctions,
  }) {
    final markers = <ExtinctionMarkerLayout>[];
    final periodTotal = _totalUnits(periodSegments);
    final stageTotal = _totalUnits(stageSegments);
    if (periodTotal <= 0) {
      return markers;
    }

    double? boundaryForPeriod(String label) {
      var sum = 0.0;
      for (final segment in periodSegments) {
        sum += segment.unitSpan;
        if (!segment.isGap && segment.label == label) {
          return width * (sum / periodTotal);
        }
      }
      return null;
    }

    double? boundaryForStage(String label) {
      if (stageTotal <= 0) {
        return null;
      }
      var sum = 0.0;
      for (final segment in stageSegments) {
        sum += segment.unitSpan;
        if (!segment.isGap && segment.label == label) {
          return width * (sum / stageTotal);
        }
      }
      return null;
    }

    double? boundaryMaForPeriod(String label) {
      for (final segment in periodSegments) {
        if (!segment.isGap && segment.label == label) {
          return segment.endMa;
        }
      }
      return null;
    }

    double? boundaryMaForStage(String label) {
      for (final segment in stageSegments) {
        if (!segment.isGap && segment.label == label) {
          return segment.endMa;
        }
      }
      return null;
    }

    double? positionForMa(double ma) {
      var unitCursor = 0.0;
      for (final segment in periodSegments) {
        final unitEnd = unitCursor + segment.unitSpan;
        if (!segment.isGap && ma <= segment.startMa && ma >= segment.endMa) {
          final span = segment.startMa - segment.endMa;
          if (span <= 0) {
            return width * (unitCursor / periodTotal);
          }
          final fraction = (segment.startMa - ma) / span;
          final unitPos =
              unitCursor + (segment.unitSpan * fraction.clamp(0.0, 1.0));
          return width * (unitPos / periodTotal);
        }
        unitCursor = unitEnd;
      }
      if (ma >= periodSegments.first.startMa) {
        return 0;
      }
      return width;
    }

    for (final extinction in extinctions) {
      double? x;
      double? ma;
      switch (extinction.anchor.type) {
        case ExtinctionAnchorType.period:
          x = boundaryForPeriod(extinction.anchor.label ?? '');
          ma = boundaryMaForPeriod(extinction.anchor.label ?? '');
          break;
        case ExtinctionAnchorType.stage:
          x = boundaryForStage(extinction.anchor.label ?? '');
          ma = boundaryMaForStage(extinction.anchor.label ?? '');
          break;
        case ExtinctionAnchorType.ma:
          if (extinction.anchor.ma != null) {
            x = positionForMa(extinction.anchor.ma!);
            ma = extinction.anchor.ma;
          }
          break;
      }
      if (x == null) {
        continue;
      }
      markers.add(
        ExtinctionMarkerLayout(
          label: extinction.label,
          shortLabel: extinction.shortLabel,
          x: x,
          isMajor: extinction.isMajor,
          explanation: extinction.explanation,
          ma: ma,
        ),
      );
    }

    return markers;
  }

  static double _totalUnits(List<TimelineRowSegment> segments) {
    return segments.fold<double>(0.0, (sum, segment) => sum + segment.unitSpan);
  }

  double _centeredLeftForMarker({
    required ExtinctionMarkerLayout marker,
    required TextStyle textStyle,
  }) {
    final label = marker.isMajor ? marker.label : marker.shortLabel;
    final effectiveStyle = marker.isMajor
        ? textStyle.copyWith(fontSize: (textStyle.fontSize ?? 12) + 4)
        : textStyle;
    final textPainter = TextPainter(
      text: TextSpan(text: label, style: effectiveStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    final markerTriangleWidth = marker.isMajor
        ? majorTriangleWidth
        : triangleWidth;
    final markerWidth = math.max(textPainter.width, markerTriangleWidth);
    return marker.x - markerWidth / 2;
  }
}

class _ExtinctionLineHitTarget extends StatelessWidget {
  const _ExtinctionLineHitTarget({
    required this.title,
    required this.explanation,
  });

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

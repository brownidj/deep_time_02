part of 'timeline_vertical_columns.dart';

class _VerticalExtinctionColumn extends StatelessWidget {
  const _VerticalExtinctionColumn({
    required this.width,
    required this.height,
    required this.periodSegments,
    required this.stageSegments,
    required this.extinctions,
  });

  final double width;
  final double height;
  final List<TimelineRowSegment> periodSegments;
  final List<TimelineRowSegment> stageSegments;
  final List<ExtinctionDefinition> extinctions;

  @override
  Widget build(BuildContext context) {
    if (width <= 0 || height <= 0) {
      return const SizedBox.shrink();
    }
    final markers = _buildMarkerLayouts(
      height: height,
      periodSegments: periodSegments,
      stageSegments: stageSegments,
      extinctions: extinctions,
    );
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DeepTimePalette.timelineGapBackground,
          border: Border.all(color: DeepTimePalette.periodDivider, width: 1),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final marker in markers)
              _VerticalExtinctionMarker(
                marker: marker,
                width: width,
                height: height,
              ),
          ],
        ),
      ),
    );
  }

  List<_VerticalExtinctionLayout> _buildMarkerLayouts({
    required double height,
    required List<TimelineRowSegment> periodSegments,
    required List<TimelineRowSegment> stageSegments,
    required List<ExtinctionDefinition> extinctions,
  }) {
    final layouts = <_VerticalExtinctionLayout>[];
    final periodTotal = _totalUnits(periodSegments);
    final stageTotal = _totalUnits(stageSegments);
    if (periodTotal <= 0) {
      return layouts;
    }

    double? boundaryForPeriod(String label) {
      var sum = 0.0;
      for (final segment in periodSegments) {
        sum += segment.unitSpan;
        if (!segment.isGap && segment.label == label) {
          return height * (sum / periodTotal);
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
          return height * (sum / stageTotal);
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
            return height * (unitCursor / periodTotal);
          }
          final fraction = (segment.startMa - ma) / span;
          final unitPos =
              unitCursor + (segment.unitSpan * fraction.clamp(0.0, 1.0));
          return height * (unitPos / periodTotal);
        }
        unitCursor = unitEnd;
      }
      if (ma >= periodSegments.first.startMa) {
        return 0;
      }
      return height;
    }

    for (final extinction in extinctions) {
      double? y;
      double? ma;
      switch (extinction.anchor.type) {
        case ExtinctionAnchorType.period:
          y = boundaryForPeriod(extinction.anchor.label ?? '');
          ma = boundaryMaForPeriod(extinction.anchor.label ?? '');
          break;
        case ExtinctionAnchorType.stage:
          y = boundaryForStage(extinction.anchor.label ?? '');
          ma = boundaryMaForStage(extinction.anchor.label ?? '');
          break;
        case ExtinctionAnchorType.ma:
          if (extinction.anchor.ma != null) {
            y = positionForMa(extinction.anchor.ma!);
            ma = extinction.anchor.ma;
          }
          break;
      }
      if (y == null) {
        continue;
      }
      layouts.add(
        _VerticalExtinctionLayout(
          y: y,
          label: extinction.label,
          shortLabel: extinction.shortLabel,
          isMajor: extinction.isMajor,
          explanation: extinction.explanation,
          ma: ma,
        ),
      );
    }
    return layouts;
  }

  static double _totalUnits(List<TimelineRowSegment> segments) {
    return segments.fold<double>(0.0, (sum, segment) => sum + segment.unitSpan);
  }
}

class _VerticalExtinctionMarker extends StatelessWidget {
  const _VerticalExtinctionMarker({
    required this.marker,
    required this.width,
    required this.height,
  });

  final _VerticalExtinctionLayout marker;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final markerSize = marker.isMajor ? 13.0 : 9.0;
    final markerLeft = 0.0;
    final textLeft = (markerLeft + markerSize + 6).clamp(0.0, width - 6);
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: const Color(0xFFFF6D00),
      fontWeight: FontWeight.w700,
      fontSize: marker.isMajor ? 13 : null,
    );
    final y = marker.y.clamp(0.0, height);
    final rowHeight = math.max(markerSize + 8.0, 22.0);
    final maxTop = math.max(0.0, height - rowHeight);
    final rowTop = (y - rowHeight / 2).clamp(0.0, maxTop);
    final localY = (y - rowTop).clamp(0.0, rowHeight);
    final markerTop = (localY - markerSize / 2).clamp(
      0.0,
      rowHeight - markerSize,
    );
    final textTop = (localY - 8).clamp(0.0, rowHeight - 16);

    return Positioned(
      key: ValueKey('vertical-extinction-marker-${marker.shortLabel}'),
      left: 0,
      right: 0,
      top: rowTop,
      height: rowHeight,
      child: Tooltip(
        message: marker.ma == null
            ? marker.label
            : '${marker.label} • ${formatTimeRange(startMa: marker.ma!, endMa: null, startPrecision: 1, durationPrecision: 1)}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress:
              marker.explanation == null || marker.explanation!.trim().isEmpty
              ? null
              : () => showTimelineExplanationDialog(
                  context: context,
                  title: marker.label,
                  explanation: marker.explanation!.trim(),
                ),
          child: Stack(
            children: [
              Positioned(
                left: markerLeft,
                top: markerTop,
                child: SizedBox(
                  width: markerSize,
                  height: markerSize,
                  child: CustomPaint(
                    painter: _LeftTrianglePainter(
                      color: const Color(0xFFFF6D00),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: textLeft,
                right: 6,
                top: textTop,
                child: Text(
                  marker.shortLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerticalExtinctionLayout {
  const _VerticalExtinctionLayout({
    required this.y,
    required this.label,
    required this.shortLabel,
    required this.isMajor,
    this.explanation,
    this.ma,
  });

  final double y;
  final String label;
  final String shortLabel;
  final bool isMajor;
  final String? explanation;
  final double? ma;
}

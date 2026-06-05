part of 'timeline_vertical_columns.dart';

class _VerticalEventsColumn extends StatelessWidget {
  const _VerticalEventsColumn({
    required this.width,
    required this.height,
    required this.events,
    required this.totalUnits,
    required this.palette,
    this.barGradientForEvent,
    this.horizontalPadding = 3.0,
    this.laneGap = 4.0,
    this.showPoints = true,
    this.fillLaneWidths = false,
    this.fixedLaneWidth,
  });

  final double width;
  final double height;
  final List<TimelineEventSegment> events;
  final double totalUnits;
  final DeepTimePalette palette;
  final Gradient Function(TimelineEventSegment event)? barGradientForEvent;
  final double horizontalPadding;
  final double laneGap;
  final bool showPoints;
  final bool fillLaneWidths;
  final double? fixedLaneWidth;

  @override
  Widget build(BuildContext context) {
    if (width <= 0 || height <= 0 || totalUnits <= 0) {
      return const SizedBox.shrink();
    }
    final barTextStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Colors.black,
      fontWeight: FontWeight.w700,
      height: 1.0,
    );
    final pointTextStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: DeepTimePalette.panelText,
      fontWeight: FontWeight.w700,
    );
    final pointEvents = events
        .where((e) => e.type == TimelineEventType.point)
        .toList(growable: false);
    final barLeftInset = showPoints
        ? _barLeftInsetForPointLabels(
            pointEvents: pointEvents,
            textStyle: pointTextStyle,
            availableWidth: width,
          )
        : 0.0;
    final barLayouts = _buildBarLayouts(
      events: events.where((e) => e.type == TimelineEventType.bar).toList(),
      totalUnits: totalUnits,
      height: height,
    );
    final laneFrames = _buildCompactLaneFrames(
      layouts: barLayouts,
      textStyle: barTextStyle,
      availableWidth: width,
      leftInset: barLeftInset,
      horizontalPadding: horizontalPadding,
      laneGap: laneGap,
      fillLaneWidths: fillLaneWidths,
      fixedLaneWidth: fixedLaneWidth,
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
            for (final layout in barLayouts)
              _VerticalEventBar(
                layout: layout,
                left: laneFrames[layout.lane]?.$1 ?? 0,
                barWidth: laneFrames[layout.lane]?.$2 ?? 3,
                palette: palette,
                gradient: barGradientForEvent?.call(layout.event),
                textStyle: barTextStyle,
              ),
            if (showPoints)
              for (final event in pointEvents)
                _VerticalEventPoint(
                  event: event,
                  width: width,
                  height: height,
                  totalUnits: totalUnits,
                ),
          ],
        ),
      ),
    );
  }

  List<_VerticalBarLayout> _buildBarLayouts({
    required List<TimelineEventSegment> events,
    required double totalUnits,
    required double height,
  }) {
    if (events.isEmpty) {
      return const [];
    }
    final sorted = events.toList()
      ..sort((a, b) {
        final startCompare = b.startMa.compareTo(a.startMa);
        if (startCompare != 0) {
          return startCompare;
        }
        return b.endMa.compareTo(a.endMa);
      });

    final laneBottoms = <double>[];
    final layouts = <_VerticalBarLayout>[];
    for (final event in sorted) {
      final yStart = (event.startUnit / totalUnits * height).clamp(0.0, height);
      final yEnd = (event.endUnit / totalUnits * height).clamp(0.0, height);
      final top = math.min(yStart, yEnd);
      final rawHeight = (yEnd - yStart).abs();
      final barHeight = math.max(10.0, rawHeight);
      final occupancyBottom = top + rawHeight;

      var lane = 0;
      for (; lane < laneBottoms.length; lane += 1) {
        if (top >= laneBottoms[lane]) {
          break;
        }
      }
      if (lane == laneBottoms.length) {
        laneBottoms.add(occupancyBottom);
      } else {
        laneBottoms[lane] = occupancyBottom;
      }

      layouts.add(
        _VerticalBarLayout(
          event: event,
          top: top,
          height: barHeight,
          lane: lane,
        ),
      );
    }
    return layouts;
  }

  Map<int, (double, double)> _buildCompactLaneFrames({
    required List<_VerticalBarLayout> layouts,
    required TextStyle? textStyle,
    required double availableWidth,
    required double leftInset,
    required double horizontalPadding,
    required double laneGap,
    required bool fillLaneWidths,
    required double? fixedLaneWidth,
  }) {
    final laneMaxWidth = <int, double>{};
    for (final layout in layouts) {
      var desired = fixedLaneWidth ?? 3.0;
      if (fixedLaneWidth == null && textStyle != null) {
        final painter = TextPainter(
          text: TextSpan(text: layout.event.shortLabel, style: textStyle),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();
        desired = painter.height + 18;
      }
      final current = laneMaxWidth[layout.lane];
      if (current == null || desired > current) {
        laneMaxWidth[layout.lane] = desired;
      }
    }

    final lanes = laneMaxWidth.keys.toList()..sort();
    if (lanes.isEmpty) {
      return const {};
    }
    final usable = math.max(
      0.0,
      availableWidth - leftInset - (horizontalPadding * 2),
    );
    final gaps = laneGap * math.max(0, lanes.length - 1);
    final widthBudget = math.max(0.0, usable - gaps);
    final rawWidths = fillLaneWidths
        ? List<double>.filled(
            lanes.length,
            lanes.isEmpty ? 0.0 : (widthBudget / lanes.length),
          )
        : [for (final lane in lanes) laneMaxWidth[lane] ?? 3.0];
    final rawTotal = rawWidths.fold<double>(0.0, (a, b) => a + b);
    final scale = fillLaneWidths
        ? 1.0
        : (rawTotal > widthBudget && rawTotal > 0
              ? widthBudget / rawTotal
              : 1.0);

    final frames = <int, (double, double)>{};
    var cursor = leftInset + horizontalPadding;
    for (var i = 0; i < lanes.length; i += 1) {
      final lane = lanes[i];
      final maxWidth = math.max(0.0, usable);
      final minWidth = maxWidth >= 3.0 ? 3.0 : maxWidth;
      final width = (rawWidths[i] * scale).clamp(minWidth, maxWidth);
      frames[lane] = (cursor, width);
      cursor += width + laneGap;
    }
    return frames;
  }

  double _barLeftInsetForPointLabels({
    required List<TimelineEventSegment> pointEvents,
    required TextStyle? textStyle,
    required double availableWidth,
  }) {
    if (pointEvents.isEmpty || textStyle == null || availableWidth <= 0) {
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
        text: TextSpan(text: event.shortLabel, style: textStyle),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      if (painter.width > maxLabelWidth) {
        maxLabelWidth = painter.width;
      }
    }
    final inset = textLeft + maxLabelWidth + barGapFromLabel;
    return inset.clamp(0.0, availableWidth);
  }
}

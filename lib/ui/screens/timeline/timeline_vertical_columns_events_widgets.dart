part of 'timeline_vertical_columns.dart';

class _VerticalEventBar extends StatelessWidget {
  const _VerticalEventBar({
    required this.layout,
    required this.left,
    required this.barWidth,
    required this.palette,
    this.gradient,
    required this.textStyle,
  });

  final _VerticalBarLayout layout;
  final double left;
  final double barWidth;
  final DeepTimePalette palette;
  final Gradient? gradient;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final event = layout.event;
    final top = layout.top;
    final barHeight = layout.height;
    final fillColor = _safeColorForKey(event.colorKey, palette);
    final explanation = event.explanation;

    return Positioned(
      key: ValueKey('vertical-event-bar-${event.shortLabel}-${layout.lane}'),
      left: left,
      top: top,
      width: barWidth,
      height: barHeight,
      child: Tooltip(
        message:
            '${event.label} • ${formatTimeRange(startMa: event.startMa, endMa: event.endMa, startPrecision: 1, endPrecision: 1, durationPrecision: 1)}',
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPress: explanation == null || explanation.trim().isEmpty
              ? null
              : () => showTimelineExplanationDialog(
                  context: context,
                  title: event.label,
                  explanation: explanation.trim(),
                  localAssetImage: event.localAssetImage,
                  imageUrl: event.image,
                  sourcePage: event.sourcePage,
                  imageLicense: event.imageLicense,
                  imageLicenseUrl: event.imageLicenseUrl,
                  imageAuthor: event.imageAuthor,
                  imageCredit: event.imageCredit,
                ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: gradient == null ? fillColor : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: DeepTimePalette.periodDivider),
            ),
            child: textStyle == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: SizedBox(
                          width: math.max(0.0, barHeight - 4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              event.shortLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textStyle,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _VerticalBarLayout {
  const _VerticalBarLayout({
    required this.event,
    required this.top,
    required this.height,
    required this.lane,
  });

  final TimelineEventSegment event;
  final double top;
  final double height;
  final int lane;
}

class _VerticalEventPoint extends StatelessWidget {
  const _VerticalEventPoint({
    required this.event,
    required this.width,
    required this.height,
    required this.totalUnits,
  });

  final TimelineEventSegment event;
  final double width;
  final double height;
  final double totalUnits;

  @override
  Widget build(BuildContext context) {
    final y = (event.startUnit / totalUnits * height).clamp(0.0, height);
    const rowHeight = 20.0;
    final rowTop = (y - rowHeight / 2).clamp(0.0, height - rowHeight);
    final markerSize = 9.0;
    final markerLeft = 0.0;
    final textLeft = (markerLeft + markerSize + 6).clamp(0.0, width - 6);
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: DeepTimePalette.panelText,
      fontWeight: FontWeight.w700,
    );
    final explanation = event.explanation;

    return Positioned(
      left: 0,
      right: 0,
      top: rowTop,
      height: rowHeight,
      child: Tooltip(
        message:
            '${event.label} • ${formatTimeRange(startMa: event.startMa, endMa: event.startMa == event.endMa ? null : event.endMa, startPrecision: 1, endPrecision: 1, durationPrecision: 1)}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: explanation == null || explanation.trim().isEmpty
              ? null
              : () => showTimelineExplanationDialog(
                  context: context,
                  title: event.label,
                  explanation: explanation.trim(),
                  localAssetImage: event.localAssetImage,
                  imageUrl: event.image,
                  sourcePage: event.sourcePage,
                  imageLicense: event.imageLicense,
                  imageLicenseUrl: event.imageLicenseUrl,
                  imageAuthor: event.imageAuthor,
                  imageCredit: event.imageCredit,
                ),
          child: Stack(
            children: [
              Positioned(
                left: markerLeft,
                top: rowHeight / 2 - markerSize / 2,
                child: SizedBox(
                  width: markerSize,
                  height: markerSize,
                  child: CustomPaint(
                    painter: _LeftTrianglePainter(
                      color: const Color(0xFFFFEB3B),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: textLeft,
                right: 6,
                top: 2,
                child: Text(
                  event.shortLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:deep_time_2/application/services/timeline_layout_service.dart';
import 'package:deep_time_2/ui/theme/deep_time_palette.dart';
import 'package:deep_time_2/ui/widgets/timeline_explanation_dialog.dart';
import 'package:deep_time_2/ui/widgets/timeline_segment_label.dart';

class TimelineBands extends StatelessWidget {
  const TimelineBands({
    super.key,
    required this.eonSegments,
    required this.eraSegments,
    required this.palette,
    required this.onTapSegment,
    required this.eonHeight,
    required this.eraHeight,
    required this.selectedId,
    this.eonBorderWidth = 1,
    this.eraBorderWidth = 1,
  });

  final List<TimelineBandSegment> eonSegments;
  final List<TimelineBandSegment> eraSegments;
  final DeepTimePalette palette;
  final ValueChanged<TimelineBandSegment> onTapSegment;
  final double eonHeight;
  final double eraHeight;
  final int? selectedId;
  final double eonBorderWidth;
  final double eraBorderWidth;

  @override
  Widget build(BuildContext context) {
    Color darken(Color color, double factor) {
      int scaledChannel(double value) {
        return (value * 255.0 * factor).round().clamp(0, 255).toInt();
      }

      int scaledAlpha(double value) {
        return (value * 255.0).round().clamp(0, 255).toInt();
      }

      return Color.fromARGB(
        scaledAlpha(color.a),
        scaledChannel(color.r),
        scaledChannel(color.g),
        scaledChannel(color.b),
      );
    }

    return Column(
      children: [
        TimelineBandRow(
          segments: eonSegments,
          height: eonHeight,
          borderWidth: eonBorderWidth,
          rowBackgroundColor: DeepTimePalette.timelineGapBackground,
          borderColorForSegment: (segment) => segment.isGap
              ? DeepTimePalette.timelineGapBackground
              : DeepTimePalette.frameBorder,
          colorForSegment: (segment) {
            if (segment.isGap) {
              return DeepTimePalette.timelineGapBackground;
            }
            var color = palette.colorForKey(segment.colorKey);
            if (selectedId == segment.id) {
              color = darken(color, 0.93);
            }
            return color;
          },
          labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: DeepTimePalette.darkLabel,
          ),
          borderColor: DeepTimePalette.frameBorder,
          overlayBuilder: (context, index, width) {
            final segment = eonSegments[index];
            final explanation = segment.explanation;
            final content = _BandLabel(
              segment: segment,
              width: width,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: DeepTimePalette.darkLabel,
              ),
            );
            if (segment.isGap) {
              return content;
            }
            return InkWell(
              onTap: () => onTapSegment(segment),
              onLongPress: explanation == null || explanation.trim().isEmpty
                  ? null
                  : () => showTimelineExplanationDialog(
                      context: context,
                      title: segment.label,
                      explanation: explanation,
                    ),
              child: content,
            );
          },
        ),
        TimelineBandRow(
          segments: eraSegments,
          height: eraHeight,
          borderWidth: eraBorderWidth,
          rowBackgroundColor: DeepTimePalette.timelineGapBackground,
          borderColorForSegment: (segment) => segment.isGap
              ? DeepTimePalette.timelineGapBackground
              : DeepTimePalette.frameBorder,
          colorForSegment: (segment) {
            if (segment.isGap) {
              return DeepTimePalette.timelineGapBackground;
            }
            var color = palette.colorForKey(segment.colorKey);
            if (selectedId == segment.id) {
              color = darken(color, 0.93);
            }
            return color;
          },
          labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: DeepTimePalette.darkLabel,
          ),
          borderColor: DeepTimePalette.frameBorder,
          overlayBuilder: (context, index, width) {
            final segment = eraSegments[index];
            final explanation = segment.explanation;
            final content = _BandLabel(
              segment: segment,
              width: width,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: DeepTimePalette.darkLabel,
              ),
              verticalOffset: 0,
            );
            if (segment.isGap) {
              return content;
            }
            return InkWell(
              onTap: () => onTapSegment(segment),
              onLongPress: explanation == null || explanation.trim().isEmpty
                  ? null
                  : () => showTimelineExplanationDialog(
                      context: context,
                      title: segment.label,
                      explanation: explanation,
                    ),
              child: content,
            );
          },
        ),
      ],
    );
  }
}

class TimelineBandRow extends StatelessWidget {
  const TimelineBandRow({
    super.key,
    required this.segments,
    required this.height,
    required this.colorForSegment,
    required this.borderColor,
    this.borderWidth = 1,
    required this.labelStyle,
    this.overlayBuilder,
    this.borderColorForSegment,
    this.rowBackgroundColor,
  });

  final List<TimelineBandSegment> segments;
  final double height;
  final Color Function(TimelineBandSegment segment) colorForSegment;
  final Color borderColor;
  final double borderWidth;
  final TextStyle? labelStyle;
  final Widget Function(BuildContext context, int index, double width)?
  overlayBuilder;
  final Color Function(TimelineBandSegment segment)? borderColorForSegment;
  final Color? rowBackgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (segments.isEmpty || constraints.maxWidth <= 0) {
            return const SizedBox.shrink();
          }

          final totalUnits = segments.fold<double>(
            0.0,
            (sum, segment) => sum + segment.unitSpan,
          );
          if (totalUnits <= 0) {
            return const SizedBox.shrink();
          }

          var consumedWidth = 0.0;
          final children = <Widget>[];
          for (var index = 0; index < segments.length; index++) {
            final segment = segments[index];
            final rawWidth =
                constraints.maxWidth * (segment.unitSpan / totalUnits);
            final width = index == segments.length - 1
                ? (constraints.maxWidth - consumedWidth).clamp(
                    0.0,
                    constraints.maxWidth,
                  )
                : rawWidth.clamp(0.0, constraints.maxWidth);
            consumedWidth += width;

            final content = overlayBuilder == null
                ? _BandLabel(segment: segment, width: width, style: labelStyle)
                : overlayBuilder!(context, index, width);

            final resolvedBorderColor =
                borderColorForSegment?.call(segment) ?? borderColor;
            children.add(
              SizedBox(
                width: width,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorForSegment(segment),
                    border: Border.all(
                      color: resolvedBorderColor,
                      width: borderWidth,
                    ),
                  ),
                  child: content,
                ),
              ),
            );
          }

          final row = Row(children: children);
          if (rowBackgroundColor == null) {
            return row;
          }
          return DecoratedBox(
            decoration: BoxDecoration(color: rowBackgroundColor),
            child: row,
          );
        },
      ),
    );
  }
}

class _BandLabel extends StatelessWidget {
  const _BandLabel({
    required this.segment,
    required this.width,
    required this.style,
    this.verticalOffset = 0,
  });

  final TimelineBandSegment segment;
  final double width;
  final TextStyle? style;
  final double verticalOffset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Transform.translate(
        offset: Offset(0, verticalOffset),
        child: TimelineSegmentLabel(
          label: segment.label,
          width: width,
          style: style,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:deep_time_2/application/services/timeline_layout_service.dart';
import 'package:deep_time_2/ui/theme/deep_time_palette.dart';
import 'package:deep_time_2/ui/widgets/timeline_band_row.dart';
import 'package:deep_time_2/ui/widgets/timeline_explanation_dialog.dart';
import 'package:deep_time_2/ui/widgets/timeline_segment_label.dart';
import 'package:deep_time_2/ui/widgets/time_range_format.dart';

class ContinuousTimelineRow extends StatelessWidget {
  const ContinuousTimelineRow({
    super.key,
    required this.segments,
    required this.selectedId,
    required this.onTapSegment,
    required this.palette,
    required this.rowHeight,
    this.borderWidth = 1,
    this.verticalLabels = false,
    this.multiLineLabels = false,
    this.maxLabelLines = 1,
  });

  final List<TimelineRowSegment> segments;
  final int? selectedId;
  final ValueChanged<TimelineRowSegment> onTapSegment;
  final DeepTimePalette palette;
  final double rowHeight;
  final double borderWidth;
  final bool verticalLabels;
  final bool multiLineLabels;
  final int maxLabelLines;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: verticalLabels ? FontWeight.w500 : FontWeight.w700,
      color: DeepTimePalette.darkLabel,
      fontSize: verticalLabels
          ? (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) - 2
          : Theme.of(context).textTheme.titleMedium?.fontSize,
    );
    final detailStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: DeepTimePalette.darkLabel,
      fontWeight: FontWeight.w600,
    );
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

    return SizedBox(
      width: double.infinity,
      child: TimelineBandRow(
        segments: segments
            .map(
              (segment) => TimelineBandSegment(
                label: segment.label,
                id: segment.id,
                rank: segment.rank,
                startMa: segment.startMa,
                endMa: segment.endMa,
                colorKey: segment.colorKey,
                isGap: segment.isGap,
                unitSpan: segment.unitSpan,
                explanation: segment.explanation,
              ),
            )
            .toList(),
        height: rowHeight,
        rowBackgroundColor: DeepTimePalette.timelineGapBackground,
        colorForSegment: (segment) => segment.isGap
            ? DeepTimePalette.timelineGapBackground
            : palette.colorForKey(segment.colorKey),
        borderColorForSegment: (segment) => segment.isGap
            ? DeepTimePalette.timelineGapBackground
            : DeepTimePalette.periodDivider,
        borderColor: DeepTimePalette.periodDivider,
        borderWidth: borderWidth,
        labelStyle: labelStyle,
        overlayBuilder: (context, index, width) {
          final segment = segments[index];
          final isSelected = selectedId == segment.id;
          final showSecondary = width >= 160 && segment.secondaryLabel != null;
          final isGap = segment.isGap;
          final borderColor = isGap
              ? DeepTimePalette.timelineGapBackground
              : DeepTimePalette.periodDivider;
          Color baseColor;
          try {
            baseColor = isGap
                ? DeepTimePalette.timelineGapBackground
                : palette.colorForKey(segment.colorKey);
          } catch (error) {
            baseColor = const Color(0xFF7A1F1F);
          }
          if (isSelected && !isGap) {
            baseColor = darken(baseColor, 0.93);
          }

          final content = AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: verticalLabels
                ? const EdgeInsets.symmetric(horizontal: 4, vertical: 4)
                : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: baseColor,
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (verticalLabels) {
                  return SizedBox.expand(
                    child: TimelineSegmentLabel(
                      label: segment.label,
                      width: width,
                      style: labelStyle,
                      vertical: verticalLabels,
                      maxLines: maxLabelLines,
                      overflow: multiLineLabels
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                  );
                }
                if (constraints.maxHeight < 48) {
                  return TimelineSegmentLabel(
                    label: segment.label,
                    width: width,
                    style: labelStyle,
                    vertical: verticalLabels,
                    maxLines: maxLabelLines,
                    overflow: multiLineLabels
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  );
                }

                final canShowRange =
                    width >= 96 && !isGap && constraints.maxHeight >= 60;
                final canShowSecondary =
                    showSecondary && constraints.maxHeight >= 56;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TimelineSegmentLabel(
                      label: segment.label,
                      width: width,
                      style: labelStyle,
                      vertical: verticalLabels,
                      maxLines: maxLabelLines,
                      overflow: multiLineLabels
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                    if (canShowSecondary)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          segment.secondaryLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: detailStyle,
                        ),
                      ),
                    if (canShowRange) ...[
                      const Spacer(),
                      Text(
                        formatTimeRange(
                          startMa: segment.startMa,
                          endMa: segment.endMa,
                          startPrecision: 1,
                          endPrecision: 1,
                          durationPrecision: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: detailStyle,
                      ),
                    ],
                  ],
                );
              },
            ),
          );

          if (isGap) {
            return content;
          }

          final explanation = segment.explanation;
          return Tooltip(
            message:
                '${segment.label} • '
                '${formatTimeRange(
                  startMa: segment.startMa,
                  endMa: segment.endMa,
                  startPrecision: 2,
                  endPrecision: 2,
                  durationPrecision: 2,
                )}',
            child: InkWell(
              onTap: () => onTapSegment(segment),
              onLongPress: explanation == null || explanation.trim().isEmpty
                  ? null
                  : () => showTimelineExplanationDialog(
                      context: context,
                      title: segment.label,
                      explanation: explanation,
                    ),
              child: content,
            ),
          );
        },
      ),
    );
  }
}

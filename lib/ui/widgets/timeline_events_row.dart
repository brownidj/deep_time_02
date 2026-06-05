import 'package:flutter/material.dart';
import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/ui/theme/deep_time_palette.dart';
import 'package:deep_time_2/ui/widgets/timeline_explanation_dialog.dart';
import 'package:deep_time_2/ui/widgets/time_range_format.dart';

class TimelineEventsRow extends StatelessWidget {
  const TimelineEventsRow({
    super.key,
    required this.events,
    required this.totalUnits,
    required this.rowHeight,
    required this.palette,
  });

  final List<TimelineEventSegment> events;
  final double totalUnits;
  final double rowHeight;
  final DeepTimePalette palette;

  static const _barHeight = 32.0;
  static const _barSpacing = 6.0;

  static double requiredHeight({
    required List<TimelineEventSegment> events,
    required double rowHeight,
  }) {
    if (events.isEmpty) {
      return rowHeight;
    }
    final rows = _layoutRows(events);
    if (rows.isEmpty) {
      return rowHeight;
    }
    final minHeight =
        rows.length * _barHeight + (rows.length + 1) * _barSpacing;
    return rowHeight < minHeight ? minHeight : rowHeight;
  }

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty || totalUnits <= 0) {
      return SizedBox(
        height: rowHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: DeepTimePalette.timelineGapBackground,
            border: Border.all(color: DeepTimePalette.periodDivider),
          ),
        ),
      );
    }
    final rows = _layoutRows(events);
    final height = requiredHeight(events: events, rowHeight: rowHeight);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: DeepTimePalette.timelineGapBackground,
                    border: Border.all(color: DeepTimePalette.periodDivider),
                  ),
                ),
              ),
              for (var rowIndex = 0; rowIndex < rows.length; rowIndex++)
                for (final event in rows[rowIndex])
                  _EventBar(
                    event: event,
                    width: width,
                    totalUnits: totalUnits,
                    palette: palette,
                    top: _barSpacing + rowIndex * (_barHeight + _barSpacing),
                  ),
              // Point markers are rendered in the overlay with extinction markers.
            ],
          );
        },
      ),
    );
  }

  static List<List<TimelineEventSegment>> _layoutRows(
    List<TimelineEventSegment> events,
  ) {
    final bars = events
        .where((event) => event.type == TimelineEventType.bar)
        .toList();
    if (bars.isEmpty) {
      return const [];
    }
    bars.sort((a, b) {
      final startCompare = b.startMa.compareTo(a.startMa);
      if (startCompare != 0) {
        return startCompare;
      }
      return b.endMa.compareTo(a.endMa);
    });
    final rows = <List<TimelineEventSegment>>[];
    final rowEndUnits = <double>[];
    for (final event in bars) {
      var placed = false;
      for (var i = 0; i < rowEndUnits.length; i++) {
        if (event.startUnit >= rowEndUnits[i]) {
          rows[i].add(event);
          rowEndUnits[i] = event.endUnit;
          placed = true;
          break;
        }
      }
      if (!placed) {
        rows.add([event]);
        rowEndUnits.add(event.endUnit);
      }
    }
    return rows;
  }
}

class _EventBar extends StatelessWidget {
  const _EventBar({
    required this.event,
    required this.width,
    required this.totalUnits,
    required this.palette,
    required this.top,
  });

  final TimelineEventSegment event;
  final double width;
  final double totalUnits;
  final DeepTimePalette palette;
  final double top;

  @override
  Widget build(BuildContext context) {
    final startX = (event.startUnit / totalUnits) * width;
    final endX = (event.endUnit / totalUnits) * width;
    final barWidth = (endX - startX).clamp(6.0, width);
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Colors.black,
      fontWeight: FontWeight.w700,
    );
    final fallback = const Color(0xFFFFD978);
    Color barColor;
    if (event.colorKey.isEmpty) {
      barColor = fallback;
    } else {
      try {
        barColor = palette.colorForKey(event.colorKey);
      } catch (_) {
        barColor = fallback;
      }
    }
    final displayLabel = event.shortLabel;
    final hasExplanation =
        event.explanation != null && event.explanation!.trim().isNotEmpty;
    final endMa = event.startMa == event.endMa ? null : event.endMa;
    return Positioned(
      left: startX,
      top: top,
      width: barWidth,
      height: TimelineEventsRow._barHeight,
      child: Tooltip(
        message:
            '${event.label} • '
            '${formatTimeRange(startMa: event.startMa, endMa: endMa, startPrecision: 1, endPrecision: 1, durationPrecision: 1)}',
        child: GestureDetector(
          onLongPress: hasExplanation
              ? () => showTimelineExplanationDialog(
                  context: context,
                  title: event.label,
                  explanation: event.explanation!.trim(),
                  localAssetImage: event.localAssetImage,
                  imageUrl: event.image,
                  sourcePage: event.sourcePage,
                  imageLicense: event.imageLicense,
                  imageLicenseUrl: event.imageLicenseUrl,
                  imageAuthor: event.imageAuthor,
                  imageCredit: event.imageCredit,
                )
              : null,
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: barColor,
              border: Border.all(color: barColor),
            ),
            child: Text(
              displayLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
          ),
        ),
      ),
    );
  }
}

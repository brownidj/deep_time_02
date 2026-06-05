import 'package:flutter/material.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_selection.dart';
import 'package:deep_time_2/ui/theme/deep_time_palette.dart';
import 'package:deep_time_2/ui/widgets/time_range_format.dart';

class TimelineSelectionPanel extends StatelessWidget {
  const TimelineSelectionPanel({super.key, required this.selection});

  final SelectedDivision selection;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DeepTimePalette.timelineGapBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DeepTimePalette.frameBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            '${selection.label} · '
            '${formatTimeRange(
              startMa: selection.startMa,
              endMa: selection.endMa,
              startPrecision: 2,
              endPrecision: 2,
              durationPrecision: 2,
            )}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: DeepTimePalette.panelText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

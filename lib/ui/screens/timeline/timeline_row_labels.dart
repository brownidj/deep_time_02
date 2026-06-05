import 'package:flutter/material.dart';
import 'package:deep_time_2/ui/models/time_label_mode.dart';
import 'package:deep_time_2/ui/theme/deep_time_palette.dart';

class TimelineRowLabels extends StatelessWidget {
  const TimelineRowLabels({
    super.key,
    required this.eonHeight,
    required this.eraHeight,
    required this.rowHeight,
    required this.subRowHeight,
    required this.stageRowHeight,
    required this.rlifeRowHeight,
    required this.eventsRowHeight,
    required this.cladeRowHeight,
    required this.extinctionsRowHeight,
    required this.labelMode,
  });

  final double eonHeight;
  final double eraHeight;
  final double rowHeight;
  final double subRowHeight;
  final double stageRowHeight;
  final double rlifeRowHeight;
  final double eventsRowHeight;
  final double cladeRowHeight;
  final double extinctionsRowHeight;
  final TimeLabelMode labelMode;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: DeepTimePalette.panelText,
      fontWeight: FontWeight.w700,
    );
    return Column(
      children: [
        _RowLabel(
          text: labelMode.labelForRank('eon'),
          height: eonHeight,
          style: labelStyle,
          backgroundColor: DeepTimePalette.frameBorder,
        ),
        _RowLabel(
          text: labelMode.labelForRank('era'),
          height: eraHeight,
          style: labelStyle,
          backgroundColor: DeepTimePalette.frameBorder,
        ),
        _RowLabel(
          text: labelMode.divisionRowLabel(),
          height: subRowHeight,
          style: labelStyle,
          backgroundColor: DeepTimePalette.frameBorder,
        ),
        _RowLabel(
          text: labelMode.seriesRowLabel(),
          height: subRowHeight,
          style: labelStyle,
          backgroundColor: DeepTimePalette.frameBorder,
        ),
        _RowLabel(
          text: labelMode.stageRowLabel(),
          height: stageRowHeight,
          style: labelStyle,
          backgroundColor: DeepTimePalette.frameBorder,
        ),
        _RowLabel(
          text: 'RLife',
          height: rlifeRowHeight,
          style: labelStyle,
          backgroundColor: DeepTimePalette.frameBorder,
        ),
        _RowLabel(
          text: 'Events',
          height: eventsRowHeight,
          style: labelStyle,
          backgroundColor: DeepTimePalette.frameBorder,
        ),
        _RowLabel(
          text: 'Extinctions',
          height: extinctionsRowHeight,
          style: labelStyle,
          backgroundColor: DeepTimePalette.frameBorder,
        ),
        _RowLabel(
          text: 'Clades',
          height: cladeRowHeight,
          style: labelStyle,
          backgroundColor: DeepTimePalette.frameBorder,
        ),
      ],
    );
  }
}

class _RowLabel extends StatelessWidget {
  const _RowLabel({
    required this.text,
    required this.height,
    required this.style,
    this.backgroundColor,
  });

  final String text;
  final double height;
  final TextStyle? style;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ?? DeepTimePalette.panelBackground,
          border: Border.all(color: DeepTimePalette.frameBorder),
        ),
        child: Center(child: Text(text, style: style)),
      ),
    );
  }
}

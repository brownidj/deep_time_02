import 'package:flutter/material.dart';
import 'package:deep_time_2/ui/models/time_label_mode.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_body_metrics.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_orientation.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_track_widths.dart';
import 'package:deep_time_2/ui/theme/deep_time_palette.dart';

class TimelineColumnHeaders extends StatelessWidget {
  const TimelineColumnHeaders({
    super.key,
    required this.metrics,
    required this.labelMode,
    this.cladeHeaderLabel,
    this.expandCladesTrack = false,
  });

  final TimelineBodyMetrics metrics;
  final TimeLabelMode labelMode;
  final String? cladeHeaderLabel;
  final bool expandCladesTrack;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: DeepTimePalette.panelText,
      fontWeight: FontWeight.w700,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidths = resolveTimelineTrackWidths(
          metrics: metrics,
          maxWidth: constraints.maxWidth,
          expandedTrack: expandCladesTrack ? TimelineTrack.clades : null,
        );
        double scaledWidth(TimelineTrack track) =>
            trackWidths[track] ?? metrics.trackWidth(track);
        return SizedBox(
          height: metrics.headerHeight,
          child: Row(
            children: [
              for (final track in metrics.trackOrder) ...[
                if (metrics.gapBefore(track) > 0)
                  SizedBox(width: metrics.gapBefore(track)),
                SizedBox(
                  width: scaledWidth(track),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: DeepTimePalette.frameBorder,
                      border: Border.all(color: DeepTimePalette.frameBorder),
                    ),
                    child: Center(
                      child: Text(
                        _labelFor(track),
                        style: labelStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                if (metrics.gapAfter(track) > 0)
                  SizedBox(width: metrics.gapAfter(track)),
              ],
            ],
          ),
        );
      },
    );
  }

  String _labelFor(TimelineTrack track) {
    switch (track) {
      case TimelineTrack.eon:
        return labelMode.labelForRank('eon');
      case TimelineTrack.era:
        return labelMode.labelForRank('era');
      case TimelineTrack.period:
        return labelMode.divisionRowLabel();
      case TimelineTrack.epoch:
        return labelMode.seriesRowLabel();
      case TimelineTrack.stage:
        return labelMode.stageRowLabel();
      case TimelineTrack.rlife:
        return 'Representative life';
      case TimelineTrack.paleoEcology:
        return 'Paleo-ecology';
      case TimelineTrack.events:
        return 'Events';
      case TimelineTrack.extinctions:
        return 'Ext.';
      case TimelineTrack.continents:
        return 'Land';
      case TimelineTrack.waterways:
        return 'Seas';
      case TimelineTrack.clades:
        return cladeHeaderLabel ?? 'Clades';
      case TimelineTrack.ma:
        return 'Ma\n4567';
    }
  }

  // Header labels are horizontal.
}

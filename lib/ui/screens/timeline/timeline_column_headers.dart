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
    final legendStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: DeepTimePalette.panelText.withValues(alpha: 0.78),
      fontWeight: FontWeight.w600,
      height: 1.0,
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
                    child: _buildHeaderContent(
                      track,
                      labelStyle: labelStyle,
                      legendStyle: legendStyle,
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

  Widget _buildHeaderContent(
    TimelineTrack track, {
    required TextStyle? labelStyle,
    required TextStyle? legendStyle,
  }) {
    final label = _labelFor(track);
    if (track != TimelineTrack.paleoEcology) {
      return Center(
        child: Text(label, style: labelStyle, textAlign: TextAlign.center),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: labelStyle, textAlign: TextAlign.center),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Extent | Bias | Anchor',
                key: const ValueKey('paleo-ecology-header-legend'),
                style: legendStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
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

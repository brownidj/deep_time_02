import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:deep_time_2/app/app_debug.dart';
import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/domain/models/timeline_marker_catalog.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_extinction_markers.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_orientation.dart';
import 'package:deep_time_2/ui/widgets/timeline_events_row.dart';

part 'timeline_body_metrics_helpers.dart';

class TimelineBodyMetrics {
  TimelineBodyMetrics._({
    required this.defaultTrackWidth,
    required this.layout,
    required this.markers,
    required this.minHeight,
    required this.headerHeight,
    required this.labelWidth,
    required this.eonHeight,
    required this.eraHeight,
    required this.rowHeight,
    required this.subRowHeight,
    required this.stageRowHeight,
    required this.rlifeRowHeight,
    required this.eventsRowBaseHeight,
    required this.cladeRowHeight,
    required this.extinctionsRowHeight,
    required this.minUnitWidth,
    required this.minUnitHeight,
    required this.eventsRowHeight,
    required this.contentHeight,
    required this.totalUnits,
    required this.periodUnits,
    required this.scrollWidth,
    required this.scrollHeight,
    required this.trackOrder,
    required this.trackWidths,
    required this.trackStartXs,
    required this.trackLeadingGaps,
    required this.trackTrailingGaps,
    required this.trackColumnsWidth,
    required this.extinctionLayouts,
    required this.eventsRowTop,
    required this.cladeRowTop,
    required this.extinctionsRowTop,
    required this.eonEraBoundary,
    required this.rlifeBottom,
    required this.eonTotalUnits,
    required this.eraTotalUnits,
    required this.epochTotalUnits,
    required this.stageTotalUnits,
    required this.rlifeTotalUnits,
    required this.periodBoundaryYs,
    required this.eraBoundaryYs,
    required this.eonBoundaryYs,
  });

  factory TimelineBodyMetrics.fromLayout({
    required TimelineLayoutSnapshot layout,
    required TimelineMarkerCatalog markers,
    required BoxConstraints constraints,
    TimelineOrientationConfig config = kDefaultTimelineOrientation,
    double? minScrollHeight,
    List<TimelineTrack>? trackOrder,
  }) {
    const labelWidth = 96.0;
    const eonHeight = 44.0;
    const eraHeight = 72.0;
    const rowHeight = 110.0;
    const subRowHeight = 72.0;
    const stageRowHeight = 120.0;
    const rlifeRowHeight = 110.0;
    const eventsRowBaseHeight = 70.0;
    const cladeRowHeight = 140.0;
    const extinctionsRowHeight = 70.0;
    const minUnitWidth = 96.0;
    final headerHeight = config.verticalHeaderHeight;
    final minUnitHeight = config.minUnitHeight;
    final eventsRowHeight = TimelineEventsRow.requiredHeight(
      events: layout.eventSegments,
      rowHeight: eventsRowBaseHeight,
    );
    final contentHeight =
        eonHeight +
        eraHeight +
        subRowHeight +
        subRowHeight +
        stageRowHeight +
        rlifeRowHeight +
        eventsRowHeight +
        cladeRowHeight +
        extinctionsRowHeight;
    final totalUnits = layout.eonSegments.fold<double>(
      0.0,
      (sum, segment) => sum + segment.unitSpan,
    );
    final periodUnits = layout.periodSegments.fold<double>(
      0.0,
      (sum, segment) => sum + segment.unitSpan,
    );
    final scale = AppDebug.timelineScale
        .clamp(AppDebug.minTimelineScale, AppDebug.maxTimelineScale)
        .toDouble();
    final resolvedTrackOrder = (trackOrder == null || trackOrder.isEmpty)
        ? List<TimelineTrack>.from(kDefaultTimelineTrackOrder)
        : List<TimelineTrack>.from(trackOrder);
    final trackWidths = <TimelineTrack, double>{
      for (final track in resolvedTrackOrder)
        track: config.trackWidthFor(track),
    };
    final trackStartXs = <TimelineTrack, double>{};
    final trackLeadingGaps = <TimelineTrack, double>{};
    final trackTrailingGaps = <TimelineTrack, double>{};
    var trackCursor = 0.0;
    for (var i = 0; i < resolvedTrackOrder.length; i += 1) {
      final track = resolvedTrackOrder[i];
      final isFirst = i == 0;
      final leadingGap = leadingGapForTrack(track, isFirstVisible: isFirst);
      trackLeadingGaps[track] = leadingGap;
      trackCursor += leadingGap;
      trackStartXs[track] = trackCursor;
      final isLast = i == resolvedTrackOrder.length - 1;
      final gap = trailingGapForTrack(track, isLastVisible: isLast);
      trackTrailingGaps[track] = gap;
      trackCursor += trackWidths[track]! + gap;
    }
    final trackColumnsWidth = trackCursor;
    final scrollWidth = math.max(
      constraints.maxWidth * scale,
      totalUnits * minUnitWidth,
    );
    final fixedHeight = layout.fixedHeight;
    final baseScrollHeight = fixedHeight == null
        ? math.max(constraints.maxHeight * scale, totalUnits * minUnitHeight)
        : math.max(fixedHeight * scale, 0.0);
    final scrollHeight = math.max(baseScrollHeight, minScrollHeight ?? 0.0);
    final extinctionLayouts = ExtinctionMarkers.buildMarkerLayouts(
      width: scrollWidth,
      periodSegments: layout.periodSegments,
      stageSegments: layout.stageSegments,
      extinctions: markers.extinctions,
    );
    final eventsRowTop =
        eonHeight +
        eraHeight +
        subRowHeight +
        subRowHeight +
        stageRowHeight +
        rlifeRowHeight;
    final extinctionsRowTop = eventsRowTop + eventsRowHeight;
    final cladeRowTop = extinctionsRowTop + extinctionsRowHeight;
    final eonEraBoundary = eonHeight;
    final rlifeBottom =
        eonHeight +
        eraHeight +
        subRowHeight +
        subRowHeight +
        stageRowHeight +
        rlifeRowHeight;
    final eonTotalUnits = layout.eonSegments.fold<double>(
      0.0,
      (sum, segment) => sum + segment.unitSpan,
    );
    final eraTotalUnits = layout.eraSegments.fold<double>(
      0.0,
      (sum, segment) => sum + segment.unitSpan,
    );
    final epochTotalUnits = layout.epochSegments.fold<double>(
      0.0,
      (sum, segment) => sum + segment.unitSpan,
    );
    final stageTotalUnits = layout.stageSegments.fold<double>(
      0.0,
      (sum, segment) => sum + segment.unitSpan,
    );
    final rlifeTotalUnits = layout.rlifeSegments.fold<double>(
      0.0,
      (sum, segment) => sum + segment.unitSpan,
    );
    final periodBoundaryYs = _rowBoundaryPositionsForHeight(
      layout.periodSegments,
      periodUnits,
      scrollHeight,
    );
    final eraBoundaryYs = _bandBoundaryPositionsForHeight(
      layout.eraSegments,
      eraTotalUnits,
      scrollHeight,
    );
    final eonBoundaryYs = _bandBoundaryPositionsForHeight(
      layout.eonSegments,
      eonTotalUnits,
      scrollHeight,
    );

    return TimelineBodyMetrics._(
      defaultTrackWidth: config.defaultTrackWidth,
      layout: layout,
      markers: markers,
      minHeight: constraints.maxHeight,
      headerHeight: headerHeight,
      labelWidth: labelWidth,
      eonHeight: eonHeight,
      eraHeight: eraHeight,
      rowHeight: rowHeight,
      subRowHeight: subRowHeight,
      stageRowHeight: stageRowHeight,
      rlifeRowHeight: rlifeRowHeight,
      eventsRowBaseHeight: eventsRowBaseHeight,
      cladeRowHeight: cladeRowHeight,
      extinctionsRowHeight: extinctionsRowHeight,
      minUnitWidth: minUnitWidth,
      minUnitHeight: minUnitHeight,
      eventsRowHeight: eventsRowHeight,
      contentHeight: contentHeight,
      totalUnits: totalUnits,
      periodUnits: periodUnits,
      scrollWidth: scrollWidth,
      scrollHeight: scrollHeight,
      trackOrder: List.unmodifiable(resolvedTrackOrder),
      trackWidths: Map.unmodifiable(trackWidths),
      trackStartXs: Map.unmodifiable(trackStartXs),
      trackLeadingGaps: Map.unmodifiable(trackLeadingGaps),
      trackTrailingGaps: Map.unmodifiable(trackTrailingGaps),
      trackColumnsWidth: trackColumnsWidth,
      extinctionLayouts: extinctionLayouts,
      eventsRowTop: eventsRowTop,
      cladeRowTop: cladeRowTop,
      extinctionsRowTop: extinctionsRowTop,
      eonEraBoundary: eonEraBoundary,
      rlifeBottom: rlifeBottom,
      eonTotalUnits: eonTotalUnits,
      eraTotalUnits: eraTotalUnits,
      epochTotalUnits: epochTotalUnits,
      stageTotalUnits: stageTotalUnits,
      rlifeTotalUnits: rlifeTotalUnits,
      periodBoundaryYs: periodBoundaryYs,
      eraBoundaryYs: eraBoundaryYs,
      eonBoundaryYs: eonBoundaryYs,
    );
  }

  final double defaultTrackWidth;
  final TimelineLayoutSnapshot layout;
  final TimelineMarkerCatalog markers;
  final double minHeight;
  final double headerHeight;
  final double labelWidth;
  final double eonHeight;
  final double eraHeight;
  final double rowHeight;
  final double subRowHeight;
  final double stageRowHeight;
  final double rlifeRowHeight;
  final double eventsRowBaseHeight;
  final double cladeRowHeight;
  final double extinctionsRowHeight;
  final double minUnitWidth;
  final double minUnitHeight;
  final double eventsRowHeight;
  final double contentHeight;
  final double totalUnits;
  final double periodUnits;
  final double scrollWidth;
  final double scrollHeight;
  final List<TimelineTrack> trackOrder;
  final Map<TimelineTrack, double> trackWidths;
  final Map<TimelineTrack, double> trackStartXs;
  final Map<TimelineTrack, double> trackLeadingGaps;
  final Map<TimelineTrack, double> trackTrailingGaps;
  final double trackColumnsWidth;
  final List<ExtinctionMarkerLayout> extinctionLayouts;
  final double eventsRowTop;
  final double cladeRowTop;
  final double extinctionsRowTop;
  final double eonEraBoundary;
  final double rlifeBottom;
  final double eonTotalUnits;
  final double eraTotalUnits;
  final double epochTotalUnits;
  final double stageTotalUnits;
  final double rlifeTotalUnits;
  final List<double> periodBoundaryYs;
  final List<double> eraBoundaryYs;
  final List<double> eonBoundaryYs;
}

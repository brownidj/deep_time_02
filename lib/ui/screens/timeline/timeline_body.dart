import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:deep_time_2/application/services/timeline_layout_models.dart';
import 'package:deep_time_2/domain/models/clade.dart';
import 'package:deep_time_2/domain/models/paleo_ecology_entry.dart';
import 'package:deep_time_2/domain/models/timeline_marker_catalog.dart';
import 'package:deep_time_2/domain/repositories/taxonomy_repository.dart';
import 'package:deep_time_2/ui/models/biology_column_mode.dart';
import 'package:deep_time_2/ui/models/clade_label_mode.dart';
import 'package:deep_time_2/ui/models/clade_view_mode.dart';
import 'package:deep_time_2/ui/models/time_label_mode.dart';
import 'package:deep_time_2/ui/theme/deep_time_palette.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_body_content.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_body_helpers.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_body_metrics.dart';
import 'package:deep_time_2/ui/screens/timeline/timeline_orientation.dart';

class TimelineBody extends StatelessWidget {
  const TimelineBody({
    super.key,
    required this.layout,
    required this.palette,
    required this.markers,
    required this.labelMode,
    required this.scrollController,
    required this.selectedId,
    required this.onBandSelect,
    required this.onSelect,
    required this.clades,
    this.taxonomyRepository,
    this.biologyColumnMode = BiologyColumnMode.cladistic,
    required this.cladeViewMode,
    required this.cladeCategoryId,
    this.cladeLabelMode = CladeLabelMode.common,
    required this.cladeRepresentativeIds,
    required this.cladeSearchQuery,
    required this.cladeSpotlightId,
    this.activeCladeRootId,
    this.pendingFocusedRootAutoScrollId,
    this.activeCladeRootLabel,
    this.childrenByParentId = const {},
    required this.onCladeSpotlight,
    this.onCladeRootChanged,
    this.onFocusedRootAutoScrollHandled,
    this.activeTaxonomyTaxonId,
    this.onTaxonomyTaxonSelected,
    required this.visibleTracks,
    required this.paleoEcology,
  });

  final TimelineLayoutSnapshot layout;
  final DeepTimePalette palette;
  final TimelineMarkerCatalog markers;
  final TimeLabelMode labelMode;
  final ScrollController scrollController;
  final int? selectedId;
  final ValueChanged<TimelineBandSegment> onBandSelect;
  final ValueChanged<TimelineRowSegment> onSelect;
  final List<Clade> clades;
  final TaxonomyRepository? taxonomyRepository;
  final BiologyColumnMode biologyColumnMode;
  final CladeViewMode cladeViewMode;
  final String cladeCategoryId;
  final CladeLabelMode cladeLabelMode;
  final List<String> cladeRepresentativeIds;
  final String cladeSearchQuery;
  final String? cladeSpotlightId;
  final String? activeCladeRootId;
  final String? pendingFocusedRootAutoScrollId;
  final String? activeCladeRootLabel;
  final Map<String, List<Clade>> childrenByParentId;
  final ValueChanged<Clade> onCladeSpotlight;
  final ValueChanged<String?>? onCladeRootChanged;
  final ValueChanged<String>? onFocusedRootAutoScrollHandled;
  final String? activeTaxonomyTaxonId;
  final ValueChanged<String?>? onTaxonomyTaxonSelected;
  final Set<TimelineTrack> visibleTracks;
  final List<PaleoEcologyEntry> paleoEcology;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final headerStyle = Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700);
            final stageTextStyle = Theme.of(context).textTheme.bodySmall
                ?.copyWith(
                  color: DeepTimePalette.darkLabel,
                  fontWeight: FontWeight.w700,
                );
            final maTextStyle = Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600);
            final config = _buildOrientationConfig(
              layout: layout,
              markers: markers,
              labelMode: labelMode,
              style: headerStyle,
              stageStyle: stageTextStyle,
              maStyle: maTextStyle,
            );
            final minScrollHeight = minScrollHeightForStages(
              layout,
              style: stageTextStyle,
              paleoEcology: visibleTracks.contains(TimelineTrack.paleoEcology)
                  ? paleoEcology
                  : const [],
              paleoWidth: visibleTracks.contains(TimelineTrack.paleoEcology)
                  ? config.trackWidthFor(TimelineTrack.paleoEcology)
                  : 0,
              paleoStyle: stageTextStyle,
              verticalPadding: 4,
            );
            final metrics = TimelineBodyMetrics.fromLayout(
              layout: layout,
              markers: markers,
              constraints: constraints,
              config: config,
              minScrollHeight: minScrollHeight,
              trackOrder: [
                for (final track in kDefaultTimelineTrackOrder)
                  if (visibleTracks.contains(track)) track,
              ],
            );
            return TimelineBodyContent(
              layout: layout,
              palette: palette,
              markers: markers,
              labelMode: labelMode,
              scrollController: scrollController,
              selectedId: selectedId,
              onBandSelect: onBandSelect,
              onSelect: onSelect,
              metrics: metrics,
              clades: clades,
              taxonomyRepository: taxonomyRepository,
              biologyColumnMode: biologyColumnMode,
              cladeViewMode: cladeViewMode,
              cladeCategoryId: cladeCategoryId,
              cladeLabelMode: cladeLabelMode,
              cladeRepresentativeIds: cladeRepresentativeIds,
              cladeSearchQuery: cladeSearchQuery,
              cladeSpotlightId: cladeSpotlightId,
              activeCladeRootId: activeCladeRootId,
              pendingFocusedRootAutoScrollId: pendingFocusedRootAutoScrollId,
              activeCladeRootLabel: activeCladeRootLabel,
              childrenByParentId: childrenByParentId,
              onCladeSpotlight: onCladeSpotlight,
              onCladeRootChanged: onCladeRootChanged ?? (_) {},
              onFocusedRootAutoScrollHandled:
                  onFocusedRootAutoScrollHandled ?? (_) {},
              activeTaxonomyTaxonId: activeTaxonomyTaxonId,
              onTaxonomyTaxonSelected: onTaxonomyTaxonSelected ?? (_) {},
              paleoEcology: paleoEcology,
            );
          },
        ),
      ),
    );
  }

  TimelineOrientationConfig _buildOrientationConfig({
    required TimelineLayoutSnapshot layout,
    required TimelineMarkerCatalog markers,
    required TimeLabelMode labelMode,
    TextStyle? style,
    TextStyle? stageStyle,
    TextStyle? maStyle,
  }) {
    const standardVerticalEventBarWidth = 24.0;
    final eonLabel = labelMode.labelForRank('eon');
    final eraLabel = labelMode.labelForRank('era');
    final periodLabel = labelMode.divisionRowLabel();
    final epochLabel = labelMode.seriesRowLabel();
    final maxEpochLabelWidth = segmentLabelWidth(
      layout.epochSegments,
      style: style,
      horizontalPadding: 12,
    );
    final eonWidth = minimalHorizontalLabelWidth(eonLabel, style: style);
    final eraWidth = minimalHorizontalLabelWidth(eraLabel, style: style);
    final periodWidth = math.max(
      minimalVerticalLabelWidth(periodLabel, style: style),
      minimalHorizontalLabelWidth(periodLabel, style: style),
    );
    final epochWidth = math.max(
      minimalHorizontalLabelWidth(epochLabel, style: style),
      maxEpochLabelWidth,
    );
    final maxStageLabelWidth = segmentLabelWidth(
      layout.stageSegments,
      style: stageStyle,
      horizontalPadding: 12,
    );
    final stageWidth = math.max(
      minimalHorizontalLabelWidth(labelMode.stageRowLabel(), style: style),
      maxStageLabelWidth,
    );
    const extinctionMarkerLeft = 0.0;
    const extinctionMarkerSize = 13.0;
    const extinctionLabelGap = 6.0;
    const extinctionRightPadding = 6.0;
    final extinctionsWidth = extinctionsTrackWidthForLabels(
      [for (final extinction in markers.extinctions) extinction.shortLabel],
      style: style,
      markerLeft: extinctionMarkerLeft,
      markerSize: extinctionMarkerSize,
      labelGap: extinctionLabelGap,
      rightPadding: extinctionRightPadding,
      fallbackLabel: 'Ext.',
    );
    final rlifeWidth =
        minimalHorizontalLabelWidth('Representative life', style: style) * 1.5;
    final paleoEcologyWidth = math.max(40.0, rlifeWidth - 18.0);
    final eventsWidth = math.max(
      minimalHorizontalLabelWidth('Events', style: style),
      eventBarTrackWidth(
            layout.eventSegments,
            style: style,
            laneWidth: standardVerticalEventBarWidth,
          ) +
          eventPointLabelInsetWidth(layout.eventSegments, style: style),
    );
    const continentLaneCount = 3;
    const continentLaneGap = 6.0;
    const continentHorizontalPadding = 0.0;
    final continentsWidth =
        (continentLaneCount * standardVerticalEventBarWidth) +
        ((continentLaneCount - 1) * continentLaneGap) +
        (continentHorizontalPadding * 2);
    final maWidth = maColumnWidth(layout, style: maStyle, padding: 20);
    return TimelineOrientationConfig(
      trackWidths: {
        TimelineTrack.ma: maWidth,
        TimelineTrack.eon: eonWidth,
        TimelineTrack.era: eraWidth,
        TimelineTrack.period: periodWidth,
        TimelineTrack.epoch: epochWidth,
        TimelineTrack.stage: stageWidth,
        TimelineTrack.rlife: rlifeWidth,
        TimelineTrack.paleoEcology: paleoEcologyWidth,
        TimelineTrack.extinctions: extinctionsWidth,
        TimelineTrack.continents: continentsWidth,
        TimelineTrack.waterways: continentsWidth,
        TimelineTrack.events: eventsWidth,
      },
    );
  }
}

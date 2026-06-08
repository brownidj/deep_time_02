part of 'timeline_vertical_columns.dart';

class TimelineVerticalColumns extends StatelessWidget {
  const TimelineVerticalColumns({
    super.key,
    required this.layout,
    required this.markers,
    required this.palette,
    required this.selectedId,
    required this.onBandSelect,
    required this.onSelect,
    required this.scrollController,
    required this.clades,
    this.taxonomyRepository,
    this.biologyColumnMode = BiologyColumnMode.cladistic,
    required this.cladeViewMode,
    required this.cladeCategoryId,
    required this.cladeLabelMode,
    required this.cladeRepresentativeIds,
    required this.cladeSearchQuery,
    required this.cladeSpotlightId,
    this.activeCladeRootId,
    this.childrenByParentId = const {},
    required this.onCladeSpotlight,
    this.onCladeRootChanged,
    this.activeTaxonomyTaxonId,
    this.onTaxonomyTaxonSelected,
    required this.metrics,
    required this.paleoEcology,
  });

  final TimelineLayoutSnapshot layout;
  final TimelineMarkerCatalog markers;
  final DeepTimePalette palette;
  final int? selectedId;
  final ValueChanged<TimelineBandSegment> onBandSelect;
  final ValueChanged<TimelineRowSegment> onSelect;
  final ScrollController scrollController;
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
  final Map<String, List<Clade>> childrenByParentId;
  final ValueChanged<Clade> onCladeSpotlight;
  final ValueChanged<String?>? onCladeRootChanged;
  final String? activeTaxonomyTaxonId;
  final ValueChanged<String?>? onTaxonomyTaxonSelected;
  final TimelineBodyMetrics metrics;
  final List<PaleoEcologyEntry> paleoEcology;

  bool get _expandCladesTrack =>
      biologyColumnMode == BiologyColumnMode.cladistic &&
      activeCladeRootId?.trim().isNotEmpty == true;

  @override
  Widget build(BuildContext context) {
    final columnHeight = math.max(metrics.minHeight, metrics.scrollHeight);
    return LayoutBuilder(
      builder: (context, constraints) {
        final useFixedHeights = layout.fixedHeight != null;
        final stageLabelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: DeepTimePalette.darkLabel,
          fontWeight: FontWeight.w700,
        );
        final periodLabelStyle = stageLabelStyle;
        final minHeights = buildMinHeightMaps(
          layout,
          stageLabelStyle,
          periodStyle: periodLabelStyle,
          divisions: layout.divisions,
          paleoEcology: paleoEcology,
          paleoWidth: metrics.trackWidth(TimelineTrack.paleoEcology),
          paleoStyle: stageLabelStyle,
        );
        final trackWidths = resolveTimelineTrackWidths(
          metrics: metrics,
          maxWidth: constraints.maxWidth,
          expandedTrack: _expandCladesTrack ? TimelineTrack.clades : null,
        );
        final stageHeightsForPaleo = useFixedHeights
            ? _computeProportionalHeights(
                layout.stageSegments,
                height: columnHeight,
                unitsTotal: metrics.stageTotalUnits,
                unitSpan: (segment) => segment.unitSpan,
              )
            : _computeHeightsWithMinimums(
                layout.stageSegments,
                height: columnHeight,
                unitsTotal: metrics.stageTotalUnits,
                minHeights: [
                  for (final segment in layout.stageSegments)
                    segment.isGap
                        ? minHeightFromParentRange(
                            segment.startMa,
                            segment.endMa,
                            layout.epochSegments,
                            minHeights.epochHeights,
                            (parent) => parent.startMa,
                            (parent) => parent.endMa,
                            (parent) => parent.id,
                          )
                        : (minHeights.stageHeights[segment.id] ??
                              minHeightForStageLabel(segment, stageLabelStyle)),
                ],
                unitSpan: (segment) => segment.unitSpan,
              );
        final eonHeightsForClades = useFixedHeights
            ? _computeProportionalHeights(
                layout.eonSegments,
                height: columnHeight,
                unitsTotal: metrics.eonTotalUnits,
                unitSpan: (segment) => segment.unitSpan,
              )
            : _computeHeightsWithMinimums(
                layout.eonSegments,
                height: columnHeight,
                unitsTotal: metrics.eonTotalUnits,
                minHeights: [
                  for (final segment in layout.eonSegments)
                    minHeights.eonHeights[segment.id] ?? 0.0,
                ],
                unitSpan: (segment) => segment.unitSpan,
              );
        final eraHeightsForClades = useFixedHeights
            ? _computeProportionalHeights(
                layout.eraSegments,
                height: columnHeight,
                unitsTotal: metrics.eraTotalUnits,
                unitSpan: (segment) => segment.unitSpan,
              )
            : _computeHeightsWithMinimums(
                layout.eraSegments,
                height: columnHeight,
                unitsTotal: metrics.eraTotalUnits,
                minHeights: [
                  for (final segment in layout.eraSegments)
                    segment.isGap
                        ? minHeightFromParentRange(
                            segment.startMa,
                            segment.endMa,
                            layout.eonSegments,
                            minHeights.eonHeights,
                            (parent) => parent.startMa,
                            (parent) => parent.endMa,
                            (parent) => parent.id,
                          )
                        : (minHeights.eraHeights[segment.id] ?? 0.0),
                ],
                unitSpan: (segment) => segment.unitSpan,
              );
        final periodHeightsForClades = useFixedHeights
            ? _computeProportionalHeights(
                layout.periodSegments,
                height: columnHeight,
                unitsTotal: metrics.periodUnits,
                unitSpan: (segment) => segment.unitSpan,
              )
            : _computeHeightsWithMinimums(
                layout.periodSegments,
                height: columnHeight,
                unitsTotal: metrics.periodUnits,
                minHeights: [
                  for (final segment in layout.periodSegments)
                    segment.isGap
                        ? minHeightFromParentRange(
                            segment.startMa,
                            segment.endMa,
                            layout.eraSegments,
                            minHeights.eraHeights,
                            (parent) => parent.startMa,
                            (parent) => parent.endMa,
                            (parent) => parent.id,
                          )
                        : (minHeights.periodHeights[segment.id] ?? 0.0),
                ],
                unitSpan: (segment) => segment.unitSpan,
              );
        final epochHeightsForClades = useFixedHeights
            ? _computeProportionalHeights(
                layout.epochSegments,
                height: columnHeight,
                unitsTotal: metrics.epochTotalUnits,
                unitSpan: (segment) => segment.unitSpan,
              )
            : _computeHeightsWithMinimums(
                layout.epochSegments,
                height: columnHeight,
                unitsTotal: metrics.epochTotalUnits,
                minHeights: [
                  for (final segment in layout.epochSegments)
                    segment.isGap
                        ? minHeightFromParentRange(
                            segment.startMa,
                            segment.endMa,
                            layout.periodSegments,
                            minHeights.periodHeights,
                            (parent) => parent.startMa,
                            (parent) => parent.endMa,
                            (parent) => parent.id,
                          )
                        : (minHeights.epochHeights[segment.id] ?? 0.0),
                ],
                unitSpan: (segment) => segment.unitSpan,
              );
        double scaledWidth(TimelineTrack track) =>
            trackWidths[track] ?? metrics.trackWidth(track);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final track in metrics.trackOrder) ...[
              if (metrics.gapBefore(track) > 0)
                SizedBox(width: metrics.gapBefore(track)),
              _buildVerticalTrack(
                track: track,
                scaledWidth: scaledWidth,
                columnHeight: columnHeight,
                layout: layout,
                metrics: metrics,
                selectedId: selectedId,
                onBandSelect: onBandSelect,
                onSelect: onSelect,
                palette: palette,
                useFixedHeights: useFixedHeights,
                minHeights: minHeights,
                markers: markers,
                scrollController: scrollController,
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
                childrenByParentId: childrenByParentId,
                onCladeSpotlight: onCladeSpotlight,
                onCladeRootChanged: onCladeRootChanged ?? (_) {},
                activeTaxonomyTaxonId: activeTaxonomyTaxonId,
                onTaxonomyTaxonSelected: onTaxonomyTaxonSelected ?? (_) {},
                paleoEcology: paleoEcology,
                stageHeightsForPaleo: stageHeightsForPaleo,
                eonHeightsForClades: eonHeightsForClades,
                eraHeightsForClades: eraHeightsForClades,
                periodHeightsForClades: periodHeightsForClades,
                epochHeightsForClades: epochHeightsForClades,
              ),
              if (metrics.gapAfter(track) > 0)
                SizedBox(width: metrics.gapAfter(track)),
            ],
          ],
        );
      },
    );
  }
}

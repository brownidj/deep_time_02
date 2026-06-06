part of 'timeline_vertical_columns.dart';

Widget _buildBiologyTrack({
  required double width,
  required double height,
  required TimelineLayoutSnapshot layout,
  required TimelineBodyMetrics metrics,
  required ScrollController scrollController,
  required List<Clade> clades,
  required TaxonomyRepository? taxonomyRepository,
  required BiologyColumnMode biologyColumnMode,
  required CladeViewMode cladeViewMode,
  required String cladeCategoryId,
  required CladeLabelMode cladeLabelMode,
  required List<String> cladeRepresentativeIds,
  required String cladeSearchQuery,
  required String? cladeSpotlightId,
  required String? activeCladeRootId,
  required Map<String, List<Clade>> childrenByParentId,
  required ValueChanged<Clade> onCladeSpotlight,
  required ValueChanged<String?> onCladeRootChanged,
  required String? activeTaxonomyTaxonId,
  required ValueChanged<String?> onTaxonomyTaxonSelected,
  required List<double> stageHeightsForPaleo,
  required List<double> epochHeightsForClades,
  required List<double> periodHeightsForClades,
  required List<double> eraHeightsForClades,
  required List<double> eonHeightsForClades,
}) {
  if (biologyColumnMode == BiologyColumnMode.taxonomic) {
    if (taxonomyRepository == null) {
      return const _VerticalTaxonomyPlaceholderColumn(
        message: 'Taxonomy data unavailable',
      );
    }
    return TimelineTaxonomyColumn(
      width: width,
      height: height,
      repository: taxonomyRepository,
      activeTaxonomyTaxonId: activeTaxonomyTaxonId,
      onTaxonomyTaxonSelected: onTaxonomyTaxonSelected,
    );
  }
  return _VerticalCladeColumn(
    width: width,
    height: height,
    layout: layout,
    totalUnits: metrics.periodUnits,
    scrollController: scrollController,
    clades: clades,
    stageSegments: layout.stageSegments,
    stageHeights: stageHeightsForPaleo,
    epochSegments: layout.epochSegments,
    epochHeights: epochHeightsForClades,
    periodSegments: layout.periodSegments,
    periodHeights: periodHeightsForClades,
    eraSegments: layout.eraSegments,
    eraHeights: eraHeightsForClades,
    eonSegments: layout.eonSegments,
    eonHeights: eonHeightsForClades,
    viewMode: cladeViewMode,
    displayGroupId: cladeCategoryId,
    labelMode: cladeLabelMode,
    representativeIds: cladeRepresentativeIds,
    searchQuery: cladeSearchQuery,
    spotlightId: cladeSpotlightId,
    activeCladeRootId: activeCladeRootId,
    childrenByParentId: childrenByParentId,
    onSpotlight: onCladeSpotlight,
    onCladeRootChanged: onCladeRootChanged,
  );
}

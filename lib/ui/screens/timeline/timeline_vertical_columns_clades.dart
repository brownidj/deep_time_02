part of 'timeline_vertical_columns.dart';

class _VerticalCladeColumn extends StatelessWidget {
  const _VerticalCladeColumn({
    required this.width,
    required this.height,
    required this.layout,
    required this.totalUnits,
    required this.scrollController,
    required this.clades,
    required this.stageSegments,
    required this.stageHeights,
    required this.epochSegments,
    required this.epochHeights,
    required this.periodSegments,
    required this.periodHeights,
    required this.eraSegments,
    required this.eraHeights,
    required this.eonSegments,
    required this.eonHeights,
    required this.viewMode,
    required this.displayGroupId,
    required this.labelMode,
    required this.representativeIds,
    required this.searchQuery,
    required this.spotlightId,
    this.activeCladeRootId,
    this.pendingFocusedRootAutoScrollId,
    this.childrenByParentId = const {},
    required this.onSpotlight,
    required this.onCladeRootChanged,
    required this.onFocusedRootAutoScrollHandled,
  });

  final double width;
  final double height;
  final TimelineLayoutSnapshot layout;
  final double totalUnits;
  final ScrollController scrollController;
  final List<Clade> clades;
  final List<TimelineRowSegment> stageSegments;
  final List<double> stageHeights;
  final List<TimelineRowSegment> epochSegments;
  final List<double> epochHeights;
  final List<TimelineRowSegment> periodSegments;
  final List<double> periodHeights;
  final List<TimelineBandSegment> eraSegments;
  final List<double> eraHeights;
  final List<TimelineBandSegment> eonSegments;
  final List<double> eonHeights;
  final CladeViewMode viewMode;
  final String displayGroupId;
  final CladeLabelMode labelMode;
  final List<String> representativeIds;
  final String searchQuery;
  final String? spotlightId;
  final String? activeCladeRootId;
  final String? pendingFocusedRootAutoScrollId;
  final Map<String, List<Clade>> childrenByParentId;
  final ValueChanged<Clade> onSpotlight;
  final ValueChanged<String?> onCladeRootChanged;
  final ValueChanged<String> onFocusedRootAutoScrollHandled;

  @override
  Widget build(BuildContext context) {
    if (width <= 0 || height <= 0 || totalUnits <= 0) {
      return const SizedBox.shrink();
    }
    const horizontalInset = 6.0;
    const bottomInset = 4.0;
    final contentWidth = math.max(0.0, width - (horizontalInset * 2));
    final contentHeight = math.max(0.0, height - bottomInset);
    return SizedBox(
      key: const ValueKey('vertical-clade-column'),
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DeepTimePalette.timelineGapBackground,
          border: Border.all(color: DeepTimePalette.periodDivider, width: 1),
        ),
        child: AnimatedBuilder(
          animation: scrollController,
          builder: (context, child) {
            return _buildCladeViewport(
              context: context,
              width: contentWidth,
              height: contentHeight,
              layout: layout,
              scrollController: scrollController,
              clades: clades,
              stageSegments: stageSegments,
              stageHeights: stageHeights,
              epochSegments: epochSegments,
              epochHeights: epochHeights,
              periodSegments: periodSegments,
              periodHeights: periodHeights,
              eraSegments: eraSegments,
              eraHeights: eraHeights,
              eonSegments: eonSegments,
              eonHeights: eonHeights,
              viewMode: viewMode,
              displayGroupId: displayGroupId,
              labelMode: labelMode,
              representativeIds: representativeIds,
              searchQuery: searchQuery,
              spotlightId: spotlightId,
              activeCladeRootId: activeCladeRootId,
              pendingFocusedRootAutoScrollId: pendingFocusedRootAutoScrollId,
              childrenByParentId: childrenByParentId,
              onSpotlight: onSpotlight,
              onCladeRootChanged: onCladeRootChanged,
              onFocusedRootAutoScrollHandled: onFocusedRootAutoScrollHandled,
            );
          },
        ),
      ),
    );
  }
}

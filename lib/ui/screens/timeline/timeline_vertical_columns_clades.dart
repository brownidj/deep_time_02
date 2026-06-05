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
    this.childrenByParentId = const {},
    required this.onSpotlight,
    required this.onCladeRootChanged,
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
  final Map<String, List<Clade>> childrenByParentId;
  final ValueChanged<Clade> onSpotlight;
  final ValueChanged<String?> onCladeRootChanged;

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
            final mapper = _StageRangeMapper(
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
              totalHeight: contentHeight,
              oldestMa: layout.oldestMa,
              youngestMa: layout.youngestMa,
            );
            if (clades.isEmpty) {
              return _emptyCladeColumn('No clades loaded');
            }
            var viewportHeight = height;
            var scrollOffset = 0.0;
            if (scrollController.hasClients) {
              final position = scrollController.position;
              if (position.hasContentDimensions) {
                viewportHeight = position.viewportDimension;
              }
              if (position.hasPixels) {
                scrollOffset = position.pixels;
              }
            }
            final visibleStart = mapper.maForY(scrollOffset) ?? layout.oldestMa;
            final visibleEnd =
                mapper.maForY(scrollOffset + viewportHeight) ??
                layout.youngestMa;
            final scopedClades = _scopeCladesForActiveRoot(
              source: clades,
              activeRootId: activeCladeRootId,
              childrenByParentId: childrenByParentId,
              targetVisibleCount: 40,
            );
            final filtered = _filterCladesForMode(
              source: scopedClades,
              representativeIds: representativeIds,
              viewMode: viewMode,
              searchQuery: searchQuery,
              hasActiveRoot: activeCladeRootId != null,
            );
            final filterId =
                activeCladeRootId == null && viewMode == CladeViewMode.byCategory
                ? displayGroupId
                : null;
            final visible = _filterVisibleClades(
              clades: filtered,
              visibleStartMa: visibleStart,
              visibleEndMa: visibleEnd,
              displayGroupId: filterId,
              scale: AppDebug.timelineScale,
              availableWidth: contentWidth,
              includeAllZoomLevels: activeCladeRootId != null,
              preferredVisibleCount: activeCladeRootId == null ? null : 40,
              includeOutsideVisibleRange: activeCladeRootId != null,
            );
            if (visible.isEmpty) {
              return _emptyCladeColumn(
                _emptyCladeMessage(
                  viewMode: viewMode,
                  displayGroupId: displayGroupId,
                  searchQuery: searchQuery,
                ),
              );
            }
            final allById = {for (final clade in clades) clade.id: clade};
            void handleCladeTap(Clade clade) {
              if (!clade.zoomable) {
                onSpotlight(clade);
                return;
              }
              onCladeRootChanged(
                activeCladeRootId == clade.id ? null : clade.id,
              );
            }
            final barLayouts = _layoutCladeBars(
              visible: visible,
              allById: allById,
              mapper: mapper,
              columnWidth: contentWidth,
              columnHeight: contentHeight,
            );
            final lucaTop = _lucaTop(barLayouts, contentHeight);
            final pinnedCapHeight = _pinnedRowCapHeight(
              eonSegments: eonSegments,
              eonHeights: eonHeights,
              scale: AppDebug.timelineScale,
            );
            final topStripHeight = pinnedCapHeight > 0
                ? math.min(lucaTop, pinnedCapHeight)
                : lucaTop;
            final pinnedTop = scrollOffset
                .clamp(0.0, math.max(0.0, contentHeight - topStripHeight))
                .toDouble();
            final clipTop = pinnedTop + topStripHeight;
            return Stack(
              children: [
                Positioned(
                  left: horizontalInset,
                  top: 0,
                  width: contentWidth,
                  height: contentHeight,
                  child: Stack(
                    children: [
                      for (final connector in _layoutCladeConnectors(
                        barLayouts,
                      ))
                        if (connector.top >= clipTop)
                          Positioned(
                          key: ValueKey(
                            'vertical-clade-connector-${connector.parent.id}-${connector.child.id}',
                          ),
                          left: connector.left,
                          top: connector.top,
                          width: connector.width,
                          height: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _VerticalCladeBar.baseColor.withValues(
                                alpha: 0.9,
                              ),
                            ),
                          ),
                        ),
                      for (final entry in barLayouts)
                        if (entry.top + entry.height > clipTop)
                          if ((entry.top < clipTop
                                      ? entry.height - (clipTop - entry.top)
                                      : entry.height) >
                                  0)
                            Positioned(
                              left: entry.left,
                              top: math.max(entry.top, clipTop),
                              child: Tooltip(
                                message: _cladeTooltip(entry, labelMode),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () => handleCladeTap(entry.clade),
                                  onLongPress: () => showTimelineExplanationDialog(
                                    context: context,
                                    title: _displayCladeLabel(
                                      entry.clade,
                                      labelMode,
                                    ),
                                    explanation: _buildCladeDetailsText(entry),
                                  ),
                                  child: _VerticalCladeBar(
                                    key: ValueKey(
                                      'vertical-clade-${entry.clade.id}',
                                    ),
                                    clade: entry.clade,
                                    labelText: _interactiveCladeLabel(
                                      entry.clade,
                                      labelMode,
                                      activeCladeRootId,
                                    ),
                                    width: entry.width,
                                    height: (entry.top < clipTop
                                            ? entry.height - (clipTop - entry.top)
                                            : entry.height)
                                        .clamp(0.0, entry.height),
                                    hideInlineLabel:
                                        entry.top <= (pinnedTop + topStripHeight),
                                    isDimmed:
                                        spotlightId != null &&
                                        spotlightId != entry.clade.id,
                                    isHighlighted: spotlightId == entry.clade.id,
                                    onLongPress: () =>
                                        showTimelineExplanationDialog(
                                          context: context,
                                          title: _displayCladeLabel(
                                            entry.clade,
                                            labelMode,
                                          ),
                                          explanation: _buildCladeDetailsText(
                                            entry,
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                            ),
                      if (topStripHeight > 0)
                        _VisibleCladeTopStrip(
                          height: topStripHeight,
                          top: pinnedTop,
                          barLayouts: barLayouts,
                          labelMode: labelMode,
                          activeCladeRootId: activeCladeRootId,
                          onTapClade: handleCladeTap,
                        ),
                    ],
                  ),
                ),
                _CladeColumnScrollbar(
                  width: width,
                  height: contentHeight,
                  controller: scrollController,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

}

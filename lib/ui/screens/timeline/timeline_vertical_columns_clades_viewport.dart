part of 'timeline_vertical_columns.dart';

Widget _buildCladeViewport({
  required BuildContext context,
  required double width,
  required double height,
  required TimelineLayoutSnapshot layout,
  required ScrollController scrollController,
  required List<Clade> clades,
  required List<TimelineRowSegment> stageSegments,
  required List<double> stageHeights,
  required List<TimelineRowSegment> epochSegments,
  required List<double> epochHeights,
  required List<TimelineRowSegment> periodSegments,
  required List<double> periodHeights,
  required List<TimelineBandSegment> eraSegments,
  required List<double> eraHeights,
  required List<TimelineBandSegment> eonSegments,
  required List<double> eonHeights,
  required CladeViewMode viewMode,
  required String displayGroupId,
  required CladeLabelMode labelMode,
  required List<String> representativeIds,
  required String searchQuery,
  required String? spotlightId,
  required String? activeCladeRootId,
  required Map<String, List<Clade>> childrenByParentId,
  required ValueChanged<Clade> onSpotlight,
  required ValueChanged<String?> onCladeRootChanged,
}) {
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
    totalHeight: height,
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
  final visibleEnd = mapper.maForY(scrollOffset + viewportHeight) ?? layout.youngestMa;
  final scopedClades = _scopeCladesForActiveRoot(
    source: clades,
    activeRootId: activeCladeRootId,
    childrenByParentId: childrenByParentId,
    targetVisibleCount: 40,
  );
  final dateableClades = _filterDateableClades(scopedClades);
  if (dateableClades.isEmpty) {
    return _emptyCladeColumn('No clades with usable start dates');
  }
  final filtered = _filterCladesForMode(
    source: dateableClades,
    representativeIds: representativeIds,
    viewMode: viewMode,
    searchQuery: searchQuery,
    hasActiveRoot: activeCladeRootId != null,
  );
  final filterId = activeCladeRootId == null && viewMode == CladeViewMode.byCategory
      ? displayGroupId
      : null;
  final visible = _filterVisibleClades(
    clades: filtered,
    visibleStartMa: visibleStart,
    visibleEndMa: visibleEnd,
    displayGroupId: filterId,
    scale: AppDebug.timelineScale,
    availableWidth: width,
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
    onCladeRootChanged(activeCladeRootId == clade.id ? null : clade.id);
  }

  final barLayouts = _layoutCladeBars(
    visible: visible,
    allById: allById,
    mapper: mapper,
    columnWidth: width,
    columnHeight: height,
  );
  final lucaTop = _lucaTop(barLayouts, height);
  final pinnedCapHeight = _pinnedRowCapHeight(
    eonSegments: eonSegments,
    eonHeights: eonHeights,
    scale: AppDebug.timelineScale,
  );
  final topStripHeight = pinnedCapHeight > 0 ? math.min(lucaTop, pinnedCapHeight) : lucaTop;
  final pinnedTop = scrollOffset
      .clamp(0.0, math.max(0.0, height - topStripHeight))
      .toDouble();
  final clipTop = pinnedTop + topStripHeight;
  return Stack(
    children: [
      Positioned(
        left: 0,
        top: 0,
        width: width,
        height: height,
        child: Stack(
          children: [
            for (final connector in _layoutCladeConnectors(barLayouts))
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
                      color: _VerticalCladeBar.baseColor.withValues(alpha: 0.9),
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
                          title: _displayCladeLabel(entry.clade, labelMode),
                          explanation: _buildCladeDetailsText(entry),
                        ),
                        child: _VerticalCladeBar(
                          key: ValueKey('vertical-clade-${entry.clade.id}'),
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
                          hideInlineLabel: entry.top <= (pinnedTop + topStripHeight),
                          isDimmed: spotlightId != null && spotlightId != entry.clade.id,
                          isHighlighted: spotlightId == entry.clade.id,
                          onLongPress: () => showTimelineExplanationDialog(
                            context: context,
                            title: _displayCladeLabel(entry.clade, labelMode),
                            explanation: _buildCladeDetailsText(entry),
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
      if (topStripHeight > 0)
        Positioned(
          left: 0,
          top: pinnedTop,
          width: width,
          height: topStripHeight,
          child: _VisibleCladeTopStrip(
            height: topStripHeight,
            top: pinnedTop,
            barLayouts: barLayouts,
            labelMode: labelMode,
            activeCladeRootId: activeCladeRootId,
            onTapClade: handleCladeTap,
          ),
        ),
      _CladeColumnScrollbar(
        width: width,
        height: height,
        controller: scrollController,
      ),
    ],
  );
}

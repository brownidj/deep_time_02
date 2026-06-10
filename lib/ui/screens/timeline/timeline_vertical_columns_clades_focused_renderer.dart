// ignore_for_file: unused_element

part of 'timeline_vertical_columns.dart';

const _FocusedCladeLayoutEngine _focusedCladeLayoutEngine =
    _DefaultFocusedCladeLayoutEngine();

Widget _buildFocusedCladeViewport({
  required BuildContext context,
  required double width,
  required double height,
  required _StageRangeMapper mapper,
  required ScrollController scrollController,
  required List<Clade> allClades,
  required List<Clade> visibleClades,
  required String activeCladeRootId,
  required String? pendingFocusedRootAutoScrollId,
  required CladeLabelMode labelMode,
  required String? spotlightId,
  required ValueChanged<Clade> onSpotlight,
  required ValueChanged<String?> onCladeRootChanged,
  required ValueChanged<String> onFocusedRootAutoScrollHandled,
  required List<TimelineBandSegment> eonSegments,
  required List<double> eonHeights,
}) {
  final allById = {for (final clade in allClades) clade.id: clade};
  final focusedLayout = _focusedCladeLayoutEngine.build(
    _FocusedCladeLayoutRequest(
      rootCladeId: activeCladeRootId,
      visibleClades: visibleClades,
      allById: allById,
      mapper: mapper,
      columnWidth: width,
      columnHeight: height,
    ),
  );
  if (focusedLayout.isEmpty) {
    return _emptyCladeColumn('No clades in focused subtree');
  }

  final barLayouts = [
    for (final node in focusedLayout.nodes)
      _VerticalCladeBarLayout(
        clade: node.clade,
        left: node.left,
        top: node.top,
        width: math.max(12.0, width - node.left),
        height: node.height,
        parent: node.parentId == null ? null : allById[node.parentId!],
        parentLabel: node.parentId == null ? null : allById[node.parentId!]?.label,
      ),
  ];

  final pinnedCapHeight = _pinnedRowCapHeight(
    eonSegments: eonSegments,
    eonHeights: eonHeights,
    scale: AppDebug.timelineScale,
  );
  final topStripHeight = _resolveTopStripHeight(
    barLayouts: barLayouts,
    maxHeight: height,
    pinnedCapHeight: pinnedCapHeight,
    hasActiveRoot: true,
  );
  _scheduleFocusedRootAutoScroll(
    scrollController: scrollController,
    activeCladeRootId: activeCladeRootId,
    pendingFocusedRootAutoScrollId: pendingFocusedRootAutoScrollId,
    onFocusedRootAutoScrollHandled: onFocusedRootAutoScrollHandled,
    barLayouts: barLayouts,
    topStripHeight: topStripHeight,
  );

  var scrollOffset = 0.0;
  if (scrollController.hasClients && scrollController.position.hasPixels) {
    scrollOffset = scrollController.position.pixels;
  }
  final pinnedTop = scrollOffset
      .clamp(0.0, math.max(0.0, height - topStripHeight))
      .toDouble();
  final clipTop = pinnedTop + topStripHeight;

  void handleCladeTap(Clade clade) {
    if (!clade.zoomable) {
      onSpotlight(clade);
      return;
    }
    onCladeRootChanged(activeCladeRootId == clade.id ? null : clade.id);
  }

  return Stack(
    children: [
      Positioned.fill(
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _FocusedVerticalStructurePainter(
                    nodes: focusedLayout.nodes,
                    segments: focusedLayout.segments,
                    clipTop: clipTop,
                    color: _VerticalCladeBar.baseColor,
                  ),
                ),
              ),
            ),
            for (final entry in barLayouts)
              if (entry.top + entry.height > clipTop)
                _FocusedCladeLabelOverlay(
                  entry: entry,
                  labelMode: labelMode,
                  activeCladeRootId: activeCladeRootId,
                  clipTop: clipTop,
                  pinnedTop: pinnedTop,
                  topStripHeight: topStripHeight,
                  spotlightId: spotlightId,
                  onTap: () => handleCladeTap(entry.clade),
                  onLongPress: () => showTimelineExplanationDialog(
                    context: context,
                    title: _displayCladeLabel(entry.clade, labelMode),
                    explanation: _buildCladeDetailsText(entry),
                  ),
                ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _FocusedHorizontalConnectorPainter(
                    segments: focusedLayout.segments,
                    nodes: focusedLayout.nodes,
                    clipTop: clipTop,
                    color: _VerticalCladeBar.baseColor.withValues(alpha: 0.95),
                  ),
                ),
              ),
            ),
          ],
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
      _CladeColumnScrollbar(
        width: width,
        height: height,
        controller: scrollController,
      ),
    ],
  );
}

class _FocusedCladeLabelOverlay extends StatelessWidget {
  const _FocusedCladeLabelOverlay({
    required this.entry,
    required this.labelMode,
    required this.activeCladeRootId,
    required this.clipTop,
    required this.pinnedTop,
    required this.topStripHeight,
    required this.spotlightId,
    required this.onTap,
    required this.onLongPress,
  });

  final _VerticalCladeBarLayout entry;
  final CladeLabelMode labelMode;
  final String? activeCladeRootId;
  final double clipTop;
  final double pinnedTop;
  final double topStripHeight;
  final String? spotlightId;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final hideInlineLabel = entry.top <= (pinnedTop + topStripHeight);
    if (hideInlineLabel) {
      return const SizedBox.shrink();
    }
    final labelTop = math.max(entry.top + 10.0, clipTop);
    final isDimmed = spotlightId != null && spotlightId != entry.clade.id;
    final isHighlighted = spotlightId == entry.clade.id;
    final labelText = _interactiveVerticalCladeLabel(
      entry.clade,
      activeCladeRootId,
    );
    final tooltipMessage =
        '${_cladeTooltip(entry, labelMode)}\n${_cladeActionHint(entry.clade, activeCladeRootId)}';

    return Positioned(
      left: 0,
      top: 0,
      right: 0,
      bottom: 0,
      child: Opacity(
        opacity: isDimmed ? 0.35 : 1.0,
        child: Stack(
          children: [
            _CladeInlineRotatedLabel(
              key: ValueKey('focused-clade-label-${entry.clade.id}'),
              lineCenterX: entry.left + 1.0,
              top: labelTop,
              labelText: labelText,
              textColor: isHighlighted
                  ? _VerticalCladeBar.highlightColor
                  : Colors.white,
              tooltipMessage: tooltipMessage,
              onTap: onTap,
              onLongPress: onLongPress,
            ),
          ],
        ),
      ),
    );
  }
}

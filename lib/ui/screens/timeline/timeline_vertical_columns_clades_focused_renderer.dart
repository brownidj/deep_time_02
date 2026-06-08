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

bool _isFocusedSegmentVisible(
  _FocusedCladeBranchSegment segment,
  double clipTop,
) {
  return math.max(segment.startY, segment.endY) >= clipTop;
}

class _FocusedVerticalStructurePainter extends CustomPainter {
  const _FocusedVerticalStructurePainter({
    required this.nodes,
    required this.segments,
    required this.clipTop,
    required this.color,
  });

  final List<_FocusedCladeLayoutNode> nodes;
  final List<_FocusedCladeBranchSegment> segments;
  final double clipTop;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    for (final node in nodes) {
      final startY = math.max(node.top, clipTop);
      if (node.bottom - startY < 1) {
        continue;
      }
      canvas.drawLine(
        Offset(node.lineX, startY),
        Offset(node.lineX, node.bottom),
        paint,
      );
    }

    for (final segment in segments) {
      if (!segment.isVertical || !_isFocusedSegmentVisible(segment, clipTop)) {
        continue;
      }
      final startY = math.max(math.min(segment.startY, segment.endY), clipTop);
      final endY = math.max(segment.startY, segment.endY);
      if (endY - startY < 1) {
        continue;
      }
      canvas.drawLine(
        Offset(segment.startX, startY),
        Offset(segment.endX, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FocusedVerticalStructurePainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.segments != segments ||
        oldDelegate.clipTop != clipTop ||
        oldDelegate.color != color;
  }
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
    final labelText = _interactiveCladeLabel(
      entry.clade,
      labelMode,
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

class _FocusedHorizontalConnectorPainter extends CustomPainter {
  const _FocusedHorizontalConnectorPainter({
    required this.segments,
    required this.nodes,
    required this.clipTop,
    required this.color,
  });

  final List<_FocusedCladeBranchSegment> segments;
  final List<_FocusedCladeLayoutNode> nodes;
  final double clipTop;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    final nodeById = {for (final node in nodes) node.clade.id: node};
    final trunkSegments = [
      for (final segment in segments)
        if (segment.kind == _FocusedCladeBranchSegmentKind.trunk) segment,
    ];
    final verticalObstacles = <_FocusedVerticalObstacle>[
      for (final node in nodes)
        _FocusedVerticalObstacle(
          cladeId: node.clade.id,
          x: node.lineX,
          top: math.max(node.top, clipTop),
          bottom: node.bottom,
        ),
      for (final segment in trunkSegments)
        _FocusedVerticalObstacle(
          cladeId: segment.sourceCladeId,
          x: segment.startX,
          top: math.max(math.min(segment.startY, segment.endY), clipTop),
          bottom: math.max(segment.startY, segment.endY),
        ),
    ];

    for (final segment in segments) {
      if (!segment.isHorizontal || !_isFocusedSegmentVisible(segment, clipTop)) {
        continue;
      }
      final sourceNode = nodeById[segment.sourceCladeId];
      final targetNode = nodeById[segment.targetCladeId];
      final startX = math.min(segment.startX, segment.endX);
      final endX = math.max(segment.startX, segment.endX);
      final y = segment.startY;
      if (endX - startX < 1 || y < clipTop) {
        continue;
      }

      final crossings = [
        for (final obstacle in verticalObstacles)
          if (obstacle.x > startX + 1.0 &&
              obstacle.x < endX - 1.0 &&
              y > obstacle.top + 1.0 &&
              y < obstacle.bottom - 1.0 &&
              obstacle.cladeId != segment.sourceCladeId &&
              obstacle.cladeId != segment.targetCladeId)
            obstacle.x,
      ]..sort();
      final dedupedCrossings = <double>[];
      for (final crossing in crossings) {
        if (dedupedCrossings.isEmpty ||
            (dedupedCrossings.last - crossing).abs() > 0.5) {
          dedupedCrossings.add(crossing);
        }
      }

      if (dedupedCrossings.isEmpty) {
        canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
        continue;
      }

      const bridgeHalfWidth = 5.0;
      const bridgeHeight = 6.0;
      var cursorX = startX;
      for (final crossingX in dedupedCrossings) {
        final bridgeStart = math.max(cursorX, crossingX - bridgeHalfWidth);
        if (bridgeStart > cursorX) {
          canvas.drawLine(Offset(cursorX, y), Offset(bridgeStart, y), paint);
        }
        final bridgeEnd = math.min(endX, crossingX + bridgeHalfWidth);
        if (bridgeEnd > bridgeStart) {
          final path = Path()
            ..moveTo(bridgeStart, y)
            ..quadraticBezierTo(
              crossingX,
              y - bridgeHeight,
              bridgeEnd,
              y,
            );
          canvas.drawPath(path, paint);
        }
        cursorX = math.max(cursorX, bridgeEnd);
      }
      if (cursorX < endX) {
        canvas.drawLine(Offset(cursorX, y), Offset(endX, y), paint);
      }

      if (sourceNode != null) {
        canvas.drawLine(
          Offset(sourceNode.lineX, y),
          Offset(sourceNode.lineX + 1.0, y),
          paint,
        );
      }
      if (targetNode != null) {
        canvas.drawLine(
          Offset(targetNode.lineX - 1.0, y),
          Offset(targetNode.lineX, y),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FocusedHorizontalConnectorPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.nodes != nodes ||
        oldDelegate.clipTop != clipTop ||
        oldDelegate.color != color;
  }
}

class _FocusedVerticalObstacle {
  const _FocusedVerticalObstacle({
    required this.cladeId,
    required this.x,
    required this.top,
    required this.bottom,
  });

  final String cladeId;
  final double x;
  final double top;
  final double bottom;
}

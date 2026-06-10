// ignore_for_file: unused_element, unused_element_parameter, unused_field

part of 'timeline_vertical_columns.dart';

abstract class _FocusedCladeLayoutEngine {
  const _FocusedCladeLayoutEngine();

  _FocusedCladeLayout build(_FocusedCladeLayoutRequest request);
}

class _DefaultFocusedCladeLayoutEngine implements _FocusedCladeLayoutEngine {
  const _DefaultFocusedCladeLayoutEngine();

  @override
  _FocusedCladeLayout build(_FocusedCladeLayoutRequest request) {
    final visibleById = {
      for (final clade in request.visibleClades)
        if (clade.id == request.rootCladeId ||
            _isDescendantOfRoot(
              clade: clade,
              rootCladeId: request.rootCladeId,
              allById: request.allById,
            ))
          clade.id: clade,
    };
    final root = visibleById[request.rootCladeId];
    if (root == null || visibleById.isEmpty) {
      return _FocusedCladeLayout(
        rootCladeId: request.rootCladeId,
        nodes: const [],
        segments: const [],
        contentWidth: request.columnWidth,
        contentHeight: request.columnHeight,
      );
    }

    final childrenByParentId = <String, List<Clade>>{};
    for (final clade in visibleById.values) {
      final parentId = clade.parentId;
      if (parentId == null || !visibleById.containsKey(parentId)) {
        continue;
      }
      childrenByParentId.putIfAbsent(parentId, () => []).add(clade);
    }

    final subtreeOrderStatsById = <String, _FocusedSubtreeOrderStats>{};
    _FocusedSubtreeOrderStats computeSubtreeOrderStats(Clade clade) {
      final cached = subtreeOrderStatsById[clade.id];
      if (cached != null) {
        return cached;
      }
      final (startMa, endMa) = _focusedEffectiveBounds(
        clade: clade,
        allById: request.allById,
      );
      final selfTop = math.min(
        (request.mapper.yForMa(startMa) ?? 0.0).toDouble(),
        (request.mapper.yForMa(endMa) ?? request.columnHeight).toDouble(),
      );
      final selfBottom = math.max(
        (request.mapper.yForMa(startMa) ?? 0.0).toDouble(),
        (request.mapper.yForMa(endMa) ?? request.columnHeight).toDouble(),
      );
      var minTop = selfTop;
      var maxBottom = selfBottom;
      var weightedCenterSum = (selfTop + selfBottom) / 2;
      var weightedCount = 1.0;

      final children = childrenByParentId[clade.id] ?? const <Clade>[];
      for (final child in children) {
        final childStats = computeSubtreeOrderStats(child);
        minTop = math.min(minTop, childStats.minTop);
        maxBottom = math.max(maxBottom, childStats.maxBottom);
        weightedCenterSum += childStats.centerY * childStats.weight;
        weightedCount += childStats.weight;
      }

      final stats = _FocusedSubtreeOrderStats(
        minTop: minTop,
        maxBottom: maxBottom,
        centerY: weightedCenterSum / weightedCount,
        weight: weightedCount,
      );
      subtreeOrderStatsById[clade.id] = stats;
      return stats;
    }

    void sortChildrenRecursively(Clade parent) {
      final children = childrenByParentId[parent.id];
      if (children == null || children.isEmpty) {
        return;
      }
      for (final child in children) {
        sortChildrenRecursively(child);
      }
      int insertionCompare(Clade a, Clade b) {
        final aStats = computeSubtreeOrderStats(a);
        final bStats = computeSubtreeOrderStats(b);
        final (aStartMa, aEndMa) = _focusedEffectiveBounds(
          clade: a,
          allById: request.allById,
        );
        final (bStartMa, bEndMa) = _focusedEffectiveBounds(
          clade: b,
          allById: request.allById,
        );
        final startCompare = aStartMa.compareTo(bStartMa);
        if (startCompare != 0) {
          return startCompare;
        }
        final aSpan = aStartMa - aEndMa;
        final bSpan = bStartMa - bEndMa;
        final spanCompare = aSpan.compareTo(bSpan);
        if (spanCompare != 0) {
          return spanCompare;
        }
        final weightCompare = aStats.weight.compareTo(bStats.weight);
        if (weightCompare != 0) {
          return weightCompare;
        }
        return _compareFocusedClades(a, b);
      }
      children.sort(insertionCompare);
    }

    sortChildrenRecursively(root);

    final depthById = <String, int>{root.id: 0};
    var maxDepth = 0;
    void assignDepths(Clade clade) {
      final parentDepth = depthById[clade.id] ?? 0;
      for (final child in childrenByParentId[clade.id] ?? const <Clade>[]) {
        final depth = parentDepth + 1;
        depthById[child.id] = depth;
        maxDepth = math.max(maxDepth, depth);
        assignDepths(child);
      }
    }

    assignDepths(root);

    final lanePositionById = <String, double>{};

    int assignLanePositions(Clade clade, int lane) {
      lanePositionById[clade.id] = lane.toDouble();
      var nextLane = lane + 1;
      for (final child in childrenByParentId[clade.id] ?? const <Clade>[]) {
        nextLane = assignLanePositions(child, nextLane);
      }
      return nextLane;
    }

    assignLanePositions(root, 0);
    final maxLanePosition = lanePositionById.values.reduce(math.max);

    final usableWidth = math.max(
      0.0,
      request.columnWidth -
          request.leftPadding -
          request.rightPadding -
          request.nodeBarWidth,
    );
    final laneCount = math.max(1.0, maxLanePosition);
    final laneSpacing = laneCount <= 0.0
        ? 0.0
        : math.min(
            request.maxLaneSpacing,
            usableWidth / laneCount,
          );

    final nodes = <_FocusedCladeLayoutNode>[];
    void addNode(Clade clade, {required int siblingIndex}) {
      final depth = depthById[clade.id] ?? 0;
      final lanePosition = lanePositionById[clade.id] ?? 0.0;
      final parentId =
          clade.id == root.id || !visibleById.containsKey(clade.parentId)
          ? null
          : clade.parentId;
      final (startMa, endMa) = _focusedEffectiveBounds(
        clade: clade,
        allById: request.allById,
      );
      final startY = (request.mapper.yForMa(startMa) ?? 0.0).clamp(
        request.topPadding,
        request.columnHeight - request.bottomPadding,
      );
      final endY = (request.mapper.yForMa(endMa) ?? request.columnHeight).clamp(
        request.topPadding,
        request.columnHeight - request.bottomPadding,
      );
      var top = math.min(startY, endY).toDouble();
      var height = math.max(request.minNodeHeight, (endY - startY).abs());
      final maxBottom = request.columnHeight - request.bottomPadding;
      if (top + height > maxBottom) {
        height = math.max(request.minNodeHeight, maxBottom - top);
        top = math.max(request.topPadding, maxBottom - height);
      }

      nodes.add(
        _FocusedCladeLayoutNode(
          clade: clade,
          parentId: parentId,
          depth: depth,
          lanePosition: lanePosition,
          siblingIndex: siblingIndex,
          left: request.leftPadding + (laneSpacing * lanePosition),
          top: top,
          width: request.nodeBarWidth,
          height: height,
          labelPlacement: _FocusedCladeLabelPlacement.inline,
          isPinnedCandidate: true,
        ),
      );

      final children = childrenByParentId[clade.id] ?? const <Clade>[];
      for (var i = 0; i < children.length; i += 1) {
        addNode(children[i], siblingIndex: i);
      }
    }

    addNode(root, siblingIndex: 0);

    final nodeById = {for (final node in nodes) node.clade.id: node};
    final segments = <_FocusedCladeBranchSegment>[];
    for (final parent in nodes) {
      final children = [
        for (final child in childrenByParentId[parent.clade.id] ?? const <Clade>[])
          nodeById[child.id],
      ].whereType<_FocusedCladeLayoutNode>().toList();
      if (children.isEmpty) {
        continue;
      }
      children.sort((a, b) => a.top.compareTo(b.top));
      final parentJoinY = parent.top;
      final trunkStartY = math.min(parentJoinY, children.first.top);
      final trunkEndY = math.max(parentJoinY, children.last.top);
      final parentLineX = parent.lineX;
      if ((trunkEndY - trunkStartY).abs() >= 0.001) {
        segments.add(
          _FocusedCladeBranchSegment(
            kind: _FocusedCladeBranchSegmentKind.trunk,
            sourceCladeId: parent.clade.id,
            targetCladeId: parent.clade.id,
            startX: parentLineX,
            startY: trunkStartY,
            endX: parentLineX,
            endY: trunkEndY,
          ),
        );
      }
      for (final child in children) {
        final childLineX = child.lineX;
        segments.add(
          _FocusedCladeBranchSegment(
            kind: _FocusedCladeBranchSegmentKind.elbowHorizontal,
            sourceCladeId: parent.clade.id,
            targetCladeId: child.clade.id,
            startX: parentLineX,
            startY: child.top,
            endX: childLineX,
            endY: child.top,
          ),
        );
      }
    }

    return _FocusedCladeLayout(
      rootCladeId: request.rootCladeId,
      nodes: nodes,
      segments: segments,
      contentWidth: request.columnWidth,
      contentHeight: request.columnHeight,
    );
  }
}

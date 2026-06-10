// ignore_for_file: unused_element, unused_element_parameter, unused_field

part of 'timeline_vertical_columns.dart';

enum _FocusedCladeBranchSegmentKind {
  trunk,
  elbowHorizontal,
}

enum _FocusedCladeLabelPlacement {
  inline,
  pinnedStrip,
  hidden,
}

class _FocusedCladeLayoutRequest {
  const _FocusedCladeLayoutRequest({
    required this.rootCladeId,
    required this.visibleClades,
    required this.allById,
    required this.mapper,
    required this.columnWidth,
    required this.columnHeight,
    this.leftPadding = 14.0,
    this.rightPadding = 14.0,
    this.topPadding = 0.0,
    this.bottomPadding = 0.0,
    this.minLaneSpacing = 30.0,
    this.maxLaneSpacingMultiplier = 3.0,
    this.minNodeHeight = 12.0,
    this.nodeBarWidth = 12.0,
    this.branchElbowWidth = 18.0,
    this.verticalNodeGap = 20.0,
  });

  final String rootCladeId;
  final List<Clade> visibleClades;
  final Map<String, Clade> allById;
  final _StageRangeMapper mapper;
  final double columnWidth;
  final double columnHeight;
  final double leftPadding;
  final double rightPadding;
  final double topPadding;
  final double bottomPadding;
  final double minLaneSpacing;
  final double maxLaneSpacingMultiplier;
  final double minNodeHeight;
  final double nodeBarWidth;
  final double branchElbowWidth;
  final double verticalNodeGap;

  double get maxLaneSpacing => minLaneSpacing * maxLaneSpacingMultiplier;
}

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
      children.sort((a, b) {
        final aStats = computeSubtreeOrderStats(a);
        final bStats = computeSubtreeOrderStats(b);
        final weightCompare = aStats.weight.compareTo(bStats.weight);
        if (weightCompare != 0) {
          return weightCompare;
        }
        final centerCompare = aStats.centerY.compareTo(bStats.centerY);
        if (centerCompare != 0) {
          return centerCompare;
        }
        final topCompare = aStats.minTop.compareTo(bStats.minTop);
        if (topCompare != 0) {
          return topCompare;
        }
        return _compareFocusedClades(a, b);
      });
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
    var nextLane = 0;

    void assignLanePositions(Clade clade) {
      lanePositionById[clade.id] = nextLane.toDouble();
      nextLane += 1;
      for (final child in childrenByParentId[clade.id] ?? const <Clade>[]) {
        assignLanePositions(child);
      }
    }

    assignLanePositions(root);
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

class _FocusedCladeLayout {
  const _FocusedCladeLayout({
    required this.rootCladeId,
    required this.nodes,
    required this.segments,
    required this.contentWidth,
    required this.contentHeight,
  });

  final String rootCladeId;
  final List<_FocusedCladeLayoutNode> nodes;
  final List<_FocusedCladeBranchSegment> segments;
  final double contentWidth;
  final double contentHeight;

  bool get isEmpty => nodes.isEmpty;

  _FocusedCladeLayoutNode? nodeForId(String cladeId) {
    for (final node in nodes) {
      if (node.clade.id == cladeId) {
        return node;
      }
    }
    return null;
  }
}

class _FocusedCladeLayoutNode {
  const _FocusedCladeLayoutNode({
    required this.clade,
    required this.parentId,
    required this.depth,
    required this.lanePosition,
    required this.siblingIndex,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.labelPlacement,
    required this.isPinnedCandidate,
  });

  final Clade clade;
  final String? parentId;
  final int depth;
  final double lanePosition;
  final int siblingIndex;
  final double left;
  final double top;
  final double width;
  final double height;
  final _FocusedCladeLabelPlacement labelPlacement;
  final bool isPinnedCandidate;

  bool get isRoot => parentId == null;
  double get right => left + width;
  double get bottom => top + height;
  double get lineX => left + 1.0;
  double get centerX => left + (width / 2);
  double get centerY => top + (height / 2);
}

class _FocusedCladeBranchSegment {
  const _FocusedCladeBranchSegment({
    required this.kind,
    required this.sourceCladeId,
    required this.targetCladeId,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
  });

  final _FocusedCladeBranchSegmentKind kind;
  final String sourceCladeId;
  final String targetCladeId;
  final double startX;
  final double startY;
  final double endX;
  final double endY;

  bool get isVertical => (startX - endX).abs() < 0.001;
  bool get isHorizontal => (startY - endY).abs() < 0.001;
}

class _FocusedSubtreeOrderStats {
  const _FocusedSubtreeOrderStats({
    required this.minTop,
    required this.maxBottom,
    required this.centerY,
    required this.weight,
  });

  final double minTop;
  final double maxBottom;
  final double centerY;
  final double weight;
}

bool _isDescendantOfRoot({
  required Clade clade,
  required String rootCladeId,
  required Map<String, Clade> allById,
}) {
  var current = clade.parentId == null ? null : allById[clade.parentId!];
  final visited = <String>{clade.id};
  while (current != null && visited.add(current.id)) {
    if (current.id == rootCladeId) {
      return true;
    }
    final parentId = current.parentId;
    current = parentId == null ? null : allById[parentId];
  }
  return false;
}

int _compareFocusedClades(Clade a, Clade b) {
  final branchPriorityA = a.branchPriority ?? 1 << 20;
  final branchPriorityB = b.branchPriority ?? 1 << 20;
  final branchPriorityCompare = branchPriorityA.compareTo(branchPriorityB);
  if (branchPriorityCompare != 0) {
    return branchPriorityCompare;
  }
  final startCompare = b.startMa.compareTo(a.startMa);
  if (startCompare != 0) {
    return startCompare;
  }
  final displayPriorityCompare = a.displayPriority.compareTo(b.displayPriority);
  if (displayPriorityCompare != 0) {
    return displayPriorityCompare;
  }
  return a.label.compareTo(b.label);
}

(double, double) _focusedEffectiveBounds({
  required Clade clade,
  required Map<String, Clade> allById,
}) {
  var start = clade.startMa;
  var end = clade.endMa;
  if (start > end && (start - end).abs() > 0.0001) {
    return (start, end);
  }
  final visited = <String>{clade.id};
  var cursor = clade;
  while (cursor.parentId != null) {
    final parent = allById[cursor.parentId!];
    if (parent == null || !visited.add(parent.id)) {
      break;
    }
    if (parent.startMa > parent.endMa &&
        (parent.startMa - parent.endMa).abs() > 0.0001) {
      return (parent.startMa, parent.endMa);
    }
    cursor = parent;
  }
  return (start, end);
}

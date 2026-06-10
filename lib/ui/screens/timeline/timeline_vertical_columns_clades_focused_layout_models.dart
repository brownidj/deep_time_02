// ignore_for_file: unused_element

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

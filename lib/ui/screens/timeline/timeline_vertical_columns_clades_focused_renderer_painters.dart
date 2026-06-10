part of 'timeline_vertical_columns.dart';

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

      const bridgeHalfWidth = 10.0;
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
            ..quadraticBezierTo(crossingX, y - bridgeHeight, bridgeEnd, y);
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

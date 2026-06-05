import 'dart:math' as math;

class ConnectorSpan {
  const ConnectorSpan({required this.left, required this.right});

  final double left;
  final double right;
}

ConnectorSpan leftwardConnectorSpan({
  required double boundaryX,
  required double markerTipX,
}) {
  return ConnectorSpan(
    left: math.min(boundaryX, markerTipX),
    right: markerTipX,
  );
}

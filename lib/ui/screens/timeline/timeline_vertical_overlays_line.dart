import 'dart:math' as math;

import 'package:flutter/material.dart';

class OverlayLine extends StatelessWidget {
  const OverlayLine({
    super.key,
    required this.left,
    required this.right,
    required this.top,
    required this.color,
  });

  final double left;
  final double right;
  final double top;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final lineLeft = math.min(left, right);
    final lineRight = math.max(left, right);
    final width = lineRight - lineLeft;
    if (width <= 0) {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: lineLeft,
      top: top,
      width: width,
      child: Container(height: 1, color: color),
    );
  }
}

import 'package:flutter/material.dart';

class TimelineSegmentLabel extends StatelessWidget {
  const TimelineSegmentLabel({
    super.key,
    required this.label,
    required this.width,
    required this.style,
    this.vertical = false,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  final String label;
  final double width;
  final TextStyle? style;
  final bool vertical;
  final int maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) {
      return const SizedBox.shrink();
    }
    if (width < 24) {
      return const SizedBox.shrink();
    }
    final text = Text(
      label,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: maxLines > 1,
      style: style,
    );
    if (!vertical) {
      return Align(alignment: Alignment.centerLeft, child: text);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: constraints.maxHeight,
              maxWidth: constraints.maxWidth,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: RotatedBox(quarterTurns: 3, child: text),
            ),
          ),
        );
      },
    );
  }
}

part of 'timeline_event_markers.dart';

class _EventMarker extends StatelessWidget {
  const _EventMarker({
    required this.label,
    required this.pointUp,
    this.explanation,
    this.title,
    this.tooltip,
  });

  final String label;
  final bool pointUp;
  final String? explanation;
  final String? title;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: EventPointMarkers.markerColor,
      fontWeight: FontWeight.w700,
    );
    final textPainter = TextPainter(
      text: TextSpan(text: label, style: textStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    final markerWidth = math.max(
      textPainter.width,
      EventPointMarkers.triangleWidth,
    );

    final trianglePainter = pointUp
        ? _UpTrianglePainter()
        : _DownTrianglePainter();
    final labelSpacing = 4.0;
    final labelHeight = textPainter.height;
    final contentWidth = markerWidth;
    final contentHeight =
        EventPointMarkers.markerHeight + labelSpacing + labelHeight;
    final content = SizedBox(
      width: contentWidth,
      height: contentHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: pointUp ? 0 : null,
            bottom: pointUp ? null : 0,
            left: (markerWidth - EventPointMarkers.triangleWidth) / 2,
            child: CustomPaint(
              size: const Size(
                EventPointMarkers.triangleWidth,
                EventPointMarkers.markerHeight,
              ),
              painter: trianglePainter,
            ),
          ),
          Positioned(
            top: EventPointMarkers.markerHeight + labelSpacing,
            left: 0,
            right: 0,
            child: Text(label, style: textStyle, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
    final hasExplanation =
        explanation != null && explanation!.trim().isNotEmpty;
    if (!hasExplanation) {
      return _wrapTooltip(content);
    }
    final markerWithLongPress = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: () => showTimelineExplanationDialog(
        context: context,
        title: title ?? label,
        explanation: explanation!.trim(),
      ),
      child: content,
    );
    return _wrapTooltip(markerWithLongPress);
  }

  Widget _wrapTooltip(Widget content) {
    final value = tooltip;
    if (value == null || value.trim().isEmpty) {
      return content;
    }
    return Tooltip(message: value, child: content);
  }
}

class _DownTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = EventPointMarkers.markerColor
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UpTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = EventPointMarkers.markerColor
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

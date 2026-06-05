part of 'timeline_extinction_markers.dart';

class _ExtinctionMarker extends StatelessWidget {
  const _ExtinctionMarker({
    required this.label,
    required this.isMajor,
    this.explanation,
    this.pointUp = false,
  });

  final String label;
  final bool isMajor;
  final String? explanation;
  final bool pointUp;

  @override
  Widget build(BuildContext context) {
    final baseStyle =
        Theme.of(context).textTheme.labelSmall?.copyWith(
          color: ExtinctionMarkers.markerColor,
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle(
          color: ExtinctionMarkers.markerColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        );
    final majorStyle = baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 12) + 4,
    );
    if (!isMajor) {
      final textPainter = TextPainter(
        text: TextSpan(text: label, style: baseStyle),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      final markerWidth = math.max(
        textPainter.width,
        ExtinctionMarkers.triangleWidth,
      );
      final content = SizedBox(
        width: markerWidth,
        height: ExtinctionMarkers.markerHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: pointUp ? 0 : null,
              bottom: pointUp ? null : 0,
              left: (markerWidth - ExtinctionMarkers.triangleWidth) / 2,
              child: CustomPaint(
                size: const Size(
                  ExtinctionMarkers.triangleWidth,
                  ExtinctionMarkers.markerHeight,
                ),
                painter: pointUp ? _UpTrianglePainter() : _TrianglePainter(),
              ),
            ),
            Positioned(
              top: pointUp ? ExtinctionMarkers.markerHeight + 4 : null,
              bottom: pointUp ? null : ExtinctionMarkers.markerHeight + 3,
              left: 0,
              right: 0,
              child: Text(label, style: baseStyle, textAlign: TextAlign.center),
            ),
          ],
        ),
      );
      return _wrapExplanation(context, content);
    }

    final textPainter = TextPainter(
      text: TextSpan(text: label, style: majorStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    final triangleWidth = ExtinctionMarkers.majorTriangleWidth;
    final markerWidth = math.max(textPainter.width, triangleWidth);
    final content = SizedBox(
      width: markerWidth,
      height: ExtinctionMarkers.majorMarkerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: pointUp ? 0 : null,
            bottom: pointUp ? null : 0,
            left: (markerWidth - triangleWidth) / 2,
            child: CustomPaint(
              size: Size(triangleWidth, ExtinctionMarkers.majorMarkerHeight),
              painter: pointUp ? _UpTrianglePainter() : _TrianglePainter(),
            ),
          ),
          Positioned(
            top: pointUp ? ExtinctionMarkers.majorMarkerHeight + 4 : null,
            bottom: pointUp ? null : ExtinctionMarkers.majorMarkerHeight + 3,
            left: 0,
            right: 0,
            child: Text(label, style: majorStyle, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
    return _wrapExplanation(context, content);
  }

  Widget _wrapExplanation(BuildContext context, Widget content) {
    final hasExplanation =
        explanation != null && explanation!.trim().isNotEmpty;
    if (!hasExplanation) {
      return content;
    }
    return GestureDetector(
      onLongPress: () => showTimelineExplanationDialog(
        context: context,
        title: label,
        explanation: explanation!.trim(),
      ),
      child: content,
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ExtinctionMarkers.markerColor
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
      ..color = ExtinctionMarkers.markerColor
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

class ExtinctionMarkerLayout {
  const ExtinctionMarkerLayout({
    required this.label,
    required this.shortLabel,
    required this.x,
    required this.isMajor,
    this.explanation,
    this.ma,
  });

  final String label;
  final String shortLabel;
  final double x;
  final bool isMajor;
  final String? explanation;
  final double? ma;
}

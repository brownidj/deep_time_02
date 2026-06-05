part of 'timeline_vertical_columns.dart';

class _LeftTrianglePainter extends CustomPainter {
  const _LeftTrianglePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LeftTrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

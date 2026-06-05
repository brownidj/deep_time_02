part of 'timeline_vertical_columns.dart';

class _CladeColumnScrollbar extends StatelessWidget {
  const _CladeColumnScrollbar({
    required this.width,
    required this.height,
    required this.controller,
  });

  final double width;
  final double height;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    var viewport = height;
    var maxScroll = 0.0;
    var pixels = 0.0;
    if (controller.hasClients) {
      final position = controller.position;
      if (position.hasContentDimensions) {
        viewport = position.viewportDimension;
        maxScroll = position.maxScrollExtent;
      }
      if (position.hasPixels) {
        pixels = position.pixels;
      }
    }
    final content = viewport + maxScroll;
    final trackHeight = height;
    final thumbHeight = math.max(18.0, trackHeight * (viewport / content));
    final scrollFraction = maxScroll <= 0
        ? 0.0
        : (pixels / maxScroll).clamp(0.0, 1.0);
    final thumbTop = (trackHeight - thumbHeight) * scrollFraction;
    return Positioned(
      key: const ValueKey('clade-scrollbar'),
      right: 1,
      top: 1,
      width: 3,
      height: math.max(0.0, height - 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: thumbTop.clamp(
                0.0,
                math.max(0.0, trackHeight - thumbHeight),
              ),
              height: thumbHeight.clamp(0.0, trackHeight),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

part of 'timeline_vertical_columns.dart';

class _VerticalSegmentTile extends StatelessWidget {
  const _VerticalSegmentTile({
    required this.width,
    required this.height,
    required this.color,
    required this.borderColor,
    required this.label,
    required this.rotateLabel,
    required this.horizontalPadding,
  });

  final double width;
  final double height;
  final Color color;
  final Color borderColor;
  final String label;
  final bool rotateLabel;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: DeepTimePalette.darkLabel,
      fontWeight: FontWeight.w700,
    );
    final maxLines = height >= 96
        ? 3
        : height >= 64
        ? 2
        : 1;
    final textWidget = Text(
      label,
      style: textStyle,
      textAlign: TextAlign.center,
      maxLines: rotateLabel ? 1 : maxLines,
      softWrap: !rotateLabel,
      overflow: rotateLabel ? TextOverflow.visible : TextOverflow.ellipsis,
    );
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 8,
              ),
              child: Center(
                child: rotateLabel
                    ? RotatedBox(quarterTurns: 3, child: textWidget)
                    : textWidget,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

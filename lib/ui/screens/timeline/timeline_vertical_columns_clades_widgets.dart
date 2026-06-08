part of 'timeline_vertical_columns.dart';

class _VerticalCladeBarLayout {
  const _VerticalCladeBarLayout({
    required this.clade,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.parent,
    required this.parentLabel,
  });

  final Clade clade;
  final double left;
  final double top;
  final double width;
  final double height;
  final Clade? parent;
  final String? parentLabel;

  String get tooltip {
    return '${clade.label} • '
        '${formatTimeRange(startMa: clade.startMa, endMa: clade.endMa, startPrecision: 1, endPrecision: 1, durationPrecision: 1)}';
  }
}

class _VerticalCladeConnectorLayout {
  const _VerticalCladeConnectorLayout({
    required this.parent,
    required this.child,
    required this.left,
    required this.top,
    required this.width,
  });

  final Clade parent;
  final Clade child;
  final double left;
  final double top;
  final double width;
}

class _VerticalCladeBar extends StatelessWidget {
  const _VerticalCladeBar({
    super.key,
    required this.clade,
    required this.labelText,
    required this.width,
    required this.height,
    required this.hideInlineLabel,
    required this.isDimmed,
    required this.isHighlighted,
    required this.onLongPress,
  });

  final Clade clade;
  final String labelText;
  final double width;
  final double height;
  final bool hideInlineLabel;
  final bool isDimmed;
  final bool isHighlighted;
  final VoidCallback onLongPress;

  static const Color baseColor = Color(0xFF4DB6AC);
  static const Color highlightColor = Color(0xFFFFD978);
  static const Color labelBackgroundColor =
      DeepTimePalette.timelineGapBackground;

  String _formatStartMa(double value) {
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final color = isHighlighted ? highlightColor : baseColor;
    final opacity = isDimmed ? 0.35 : 1.0;
    final showLabel = !hideInlineLabel && height >= 32;
    final lineWidth = isHighlighted ? 3.0 : 2.0;

    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: lineWidth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (showLabel)
              _CladeInlineRotatedLabel(
                lineCenterX: lineWidth / 2,
                top: 10,
                labelText: labelText,
                textColor: Colors.white,
                tooltipMessage: 'Crown age: ${_formatStartMa(clade.startMa)} Ma',
                onTap: null,
                onLongPress: onLongPress,
              ),
          ],
        ),
      ),
    );
  }
}

class _CladeInlineRotatedLabel extends StatelessWidget {
  const _CladeInlineRotatedLabel({
    super.key,
    required this.lineCenterX,
    required this.top,
    required this.labelText,
    required this.textColor,
    required this.tooltipMessage,
    required this.onTap,
    required this.onLongPress,
  });

  final double lineCenterX;
  final double top;
  final String labelText;
  final Color textColor;
  final String tooltipMessage;
  final VoidCallback? onTap;
  final VoidCallback onLongPress;

  static const double labelBandWidth = 28.0;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: textColor,
      fontWeight: FontWeight.w700,
    );

    return Positioned(
      left: lineCenterX - (labelBandWidth / 2),
      top: top,
      width: labelBandWidth,
      child: Center(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: _VerticalCladeBar.labelBackgroundColor,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Tooltip(
              message: tooltipMessage,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: onTap,
                onLongPress: onLongPress,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    labelText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VisibleCladeTopStrip extends StatelessWidget {
  const _VisibleCladeTopStrip({
    required this.height,
    required this.top,
    required this.barLayouts,
    required this.labelMode,
    required this.activeCladeRootId,
    required this.onTapClade,
  });

  final double height;
  final double top;
  final List<_VerticalCladeBarLayout> barLayouts;
  final CladeLabelMode labelMode;
  final String? activeCladeRootId;
  final ValueChanged<Clade> onTapClade;

  @override
  Widget build(BuildContext context) {
    if (height <= 0 || barLayouts.isEmpty) {
      return const SizedBox.shrink();
    }
    const labelBandWidth = 28.0;
    final bottom = top + height;
    final sorted = [
      for (final entry in barLayouts)
        if (entry.top <= bottom) entry,
    ]..sort((a, b) => a.left.compareTo(b.left));
    return Positioned(
      key: const ValueKey('clade-top-strip'),
      left: 0,
      top: top,
      right: 0,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: DeepTimePalette.timelineGapBackground,
              ),
            ),
          ),
          for (final entry in sorted)
            Positioned(
              left: entry.left + 1.0 - (labelBandWidth / 2),
              bottom: 4.0,
              width: labelBandWidth,
              height: height,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: DeepTimePalette.timelineGapBackground,
                  ),
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Tooltip(
                      message:
                          '${entry.tooltip}\n${_cladeActionHint(entry.clade, activeCladeRootId)}',
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => onTapClade(entry.clade),
                        onLongPress: () => showTimelineExplanationDialog(
                          context: context,
                          title: _displayCladeLabel(entry.clade, labelMode),
                          explanation: _buildCladeDetailsText(entry),
                        ),
                        child: Text(
                          _interactiveCladeLabel(
                            entry.clade,
                            labelMode,
                            activeCladeRootId,
                          ),
                          key: ValueKey(
                            'clade-top-strip-label-${entry.clade.id}',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

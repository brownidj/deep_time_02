part of 'timeline_vertical_columns.dart';

class _MaColumn extends StatelessWidget {
  const _MaColumn({
    required this.width,
    required this.height,
    required this.layout,
    required this.metrics,
  });

  final double width;
  final double height;
  final TimelineLayoutSnapshot layout;
  final TimelineBodyMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );
    final uncertaintyStyle = (labelStyle ?? const TextStyle()).copyWith(
      fontSize: ((labelStyle?.fontSize ?? 11) - 2).clamp(8.0, 100.0),
      color: Colors.white.withValues(alpha: 0.9),
      fontWeight: FontWeight.w500,
    );
    final uncertaintyByStartMa = <double, double?>{
      for (final division in layout.divisions)
        division.startMa: division.startMaUncertainty,
    };
    final labels = <_MaLabel>[];
    final seen = <String>{};
    final eonBoundaries = metrics.eonBoundaryYs;
    for (var i = 0; i < eonBoundaries.length; i++) {
      final boundaryStartMa = layout.eonSegments[i + 1].startMa;
      final text = _formatMaLabel(boundaryStartMa);
      if (seen.add(text)) {
        labels.add(
          _MaLabel(
            text: text,
            y: eonBoundaries[i],
            uncertaintyText: _formatUncertainty(
              uncertaintyByStartMa[boundaryStartMa],
            ),
          ),
        );
      }
    }
    final eraBoundaries = metrics.eraBoundaryYs;
    for (var i = 0; i < eraBoundaries.length; i++) {
      final boundaryStartMa = layout.eraSegments[i + 1].startMa;
      final text = _formatMaLabel(boundaryStartMa);
      if (seen.add(text)) {
        labels.add(
          _MaLabel(
            text: text,
            y: eraBoundaries[i],
            uncertaintyText: _formatUncertainty(
              uncertaintyByStartMa[boundaryStartMa],
            ),
          ),
        );
      }
    }
    final periodBoundaries = metrics.periodBoundaryYs;
    for (var i = 0; i < periodBoundaries.length; i++) {
      final boundaryStartMa = layout.periodSegments[i + 1].startMa;
      final text = _formatMaLabel(boundaryStartMa);
      if (seen.add(text)) {
        labels.add(
          _MaLabel(
            text: text,
            y: periodBoundaries[i],
            uncertaintyText: _formatUncertainty(
              uncertaintyByStartMa[boundaryStartMa],
            ),
          ),
        );
      }
    }
    final resolved = _resolveLabelCollisions(
      labels,
      style: labelStyle,
      uncertaintyStyle: uncertaintyStyle,
    );

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: DeepTimePalette.frameBorder),
        child: Stack(
          children: [
            for (final label in resolved)
              _MaLabelWidget(
                label: label,
                width: width,
                height: height,
                style: labelStyle,
                uncertaintyStyle: uncertaintyStyle,
              ),
          ],
        ),
      ),
    );
  }
}

class _MaLabelWidget extends StatelessWidget {
  const _MaLabelWidget({
    required this.label,
    required this.width,
    required this.height,
    required this.style,
    required this.uncertaintyStyle,
  });

  final _MaLabel label;
  final double width;
  final double height;
  final TextStyle? style;
  final TextStyle uncertaintyStyle;

  @override
  Widget build(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(text: label.text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final uncertaintyPainter = label.uncertaintyText == null
        ? null
        : (TextPainter(
            text: TextSpan(
              text: label.uncertaintyText,
              style: uncertaintyStyle,
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout());
    final blockHeight =
        painter.height +
        (uncertaintyPainter == null ? 0 : uncertaintyPainter.height + 1);
    final top = (label.y - (blockHeight / 2)).clamp(0.0, height - blockHeight);
    return Positioned(
      top: top,
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label.text, style: style, textAlign: TextAlign.right),
          if (label.uncertaintyText != null)
            Text(
              label.uncertaintyText!,
              style: uncertaintyStyle,
              textAlign: TextAlign.right,
            ),
        ],
      ),
    );
  }
}

class _MaLabel {
  const _MaLabel({required this.text, required this.y, this.uncertaintyText});

  final String text;
  final double y;
  final String? uncertaintyText;
}

double _labelBlockHeight(
  _MaLabel label, {
  required TextStyle? style,
  required TextStyle uncertaintyStyle,
}) {
  final painter = TextPainter(
    text: TextSpan(text: label.text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  if (label.uncertaintyText == null) {
    return painter.height;
  }
  final uncertaintyPainter = TextPainter(
    text: TextSpan(text: label.uncertaintyText, style: uncertaintyStyle),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  return painter.height + uncertaintyPainter.height + 1;
}

List<_MaLabel> _resolveLabelCollisions(
  List<_MaLabel> labels, {
  required TextStyle? style,
  required TextStyle uncertaintyStyle,
}) {
  if (labels.isEmpty) {
    return labels;
  }
  final sorted = labels.toList()..sort((a, b) => a.y.compareTo(b.y));
  final resolved = <_MaLabel>[];
  var lastBottom = -double.infinity;
  for (final label in sorted) {
    final blockHeight = _labelBlockHeight(
      label,
      style: style,
      uncertaintyStyle: uncertaintyStyle,
    );
    final halfHeight = blockHeight / 2;
    final minCenterY = lastBottom + 4 + halfHeight;
    final y = label.y < minCenterY ? minCenterY : label.y;
    resolved.add(
      _MaLabel(text: label.text, y: y, uncertaintyText: label.uncertaintyText),
    );
    lastBottom = y + halfHeight;
  }
  return resolved;
}

String _formatMaLabel(double value) {
  return value.toStringAsFixed(1);
}

String? _formatUncertainty(double? value) {
  if (value == null) {
    return null;
  }
  return '±${value.toString()}';
}

part of 'timeline_vertical_columns.dart';

class _LeftColorColumn {
  const _LeftColorColumn({
    required this.ranges,
    required this.colorForKey,
  });

  final List<_LeftColorRange> ranges;
  final Color Function(String key) colorForKey;
}

class _LeftColorRange {
  const _LeftColorRange({
    required this.startMa,
    required this.endMa,
    required this.isGap,
    required this.colorKey,
  });

  final double startMa;
  final double endMa;
  final bool isGap;
  final String colorKey;

  bool contains(double ma) => ma <= startMa && ma >= endMa;
}

LinearGradient _buildContinentBlockGradient({
  required TimelineEventSegment event,
  required Color fallbackColor,
  required List<_LeftColorColumn> leftColumns,
}) {
  final spanMa = event.startMa - event.endMa;
  if (spanMa <= 0) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [fallbackColor, fallbackColor],
      stops: const [0.0, 1.0],
    );
  }

  Color resolveLeftColorAt(double ma) {
    for (final column in leftColumns) {
      for (final range in column.ranges) {
        if (!range.contains(ma) || range.isGap || range.colorKey.trim().isEmpty) {
          continue;
        }
        return column.colorForKey(range.colorKey);
      }
    }
    return fallbackColor;
  }

  final boundaries = <double>{event.startMa, event.endMa};
  for (final column in leftColumns) {
    for (final range in column.ranges) {
      if (range.startMa < event.startMa && range.startMa > event.endMa) {
        boundaries.add(range.startMa);
      }
      if (range.endMa < event.startMa && range.endMa > event.endMa) {
        boundaries.add(range.endMa);
      }
    }
  }
  final sorted = boundaries.toList()..sort((a, b) => b.compareTo(a));
  if (sorted.length < 2) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [fallbackColor, fallbackColor],
      stops: const [0.0, 1.0],
    );
  }

  Color sampleInterpolatedColor(double ma) {
    for (var i = 0; i < sorted.length - 1; i += 1) {
      final topMa = sorted[i];
      final bottomMa = sorted[i + 1];
      if (ma <= topMa && ma >= bottomMa) {
        final topColor = resolveLeftColorAt(topMa - 0.000001);
        final bottomColor = resolveLeftColorAt(bottomMa + 0.000001);
        final segmentSpan = topMa - bottomMa;
        if (segmentSpan <= 0) {
          return topColor;
        }
        final t = ((topMa - ma) / segmentSpan).clamp(0.0, 1.0);
        return Color.lerp(topColor, bottomColor, t) ?? topColor;
      }
    }
    return resolveLeftColorAt(ma);
  }

  // Dense sampling to avoid visible banding in tall continent bars.
  const minSampleCount = 256;
  final sampleCount = math.max(
    minSampleCount,
    ((event.startUnit - event.endUnit).abs() * 2).round(),
  );
  final colors = <Color>[];
  final stops = <double>[];
  for (var i = 0; i < sampleCount; i += 1) {
    final stop = i / (sampleCount - 1);
    final ma = event.startMa - (spanMa * stop);
    colors.add(sampleInterpolatedColor(ma));
    stops.add(stop);
  }
  final smoothedColors = _smoothColors(_smoothColors(colors));

  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: smoothedColors,
    stops: stops,
  );
}

List<_LeftColorRange> _rangesFromRowSegments(List<TimelineRowSegment> segments) {
  return [
    for (final segment in segments)
      _LeftColorRange(
        startMa: segment.startMa,
        endMa: segment.endMa,
        isGap: segment.isGap,
        colorKey: segment.colorKey,
      ),
  ];
}

List<_LeftColorRange> _rangesFromBandSegments(List<TimelineBandSegment> segments) {
  return [
    for (final segment in segments)
      _LeftColorRange(
        startMa: segment.startMa,
        endMa: segment.endMa,
        isGap: segment.isGap,
        colorKey: segment.colorKey,
      ),
  ];
}

List<Color> _smoothColors(List<Color> colors) {
  if (colors.length < 3) {
    return colors;
  }
  // Wider Gaussian-like kernel for stronger band suppression.
  const weights = [1.0, 4.0, 7.0, 10.0, 12.0, 10.0, 7.0, 4.0, 1.0];
  const offsets = [-4, -3, -2, -1, 0, 1, 2, 3, 4];
  final smoothed = List<Color>.filled(colors.length, colors.first);
  for (var i = 0; i < colors.length; i += 1) {
    var a = 0.0;
    var r = 0.0;
    var g = 0.0;
    var b = 0.0;
    var total = 0.0;
    for (var j = 0; j < offsets.length; j += 1) {
      final index = (i + offsets[j]).clamp(0, colors.length - 1);
      final w = weights[j];
      final c = colors[index];
      a += (c.a * 255.0) * w;
      r += (c.r * 255.0) * w;
      g += (c.g * 255.0) * w;
      b += (c.b * 255.0) * w;
      total += w;
    }
    smoothed[i] = Color.fromARGB(
      (a / total).round().clamp(0, 255),
      (r / total).round().clamp(0, 255),
      (g / total).round().clamp(0, 255),
      (b / total).round().clamp(0, 255),
    );
  }
  return smoothed;
}

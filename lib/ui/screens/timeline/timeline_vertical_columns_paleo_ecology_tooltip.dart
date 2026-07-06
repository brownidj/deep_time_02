part of 'timeline_vertical_columns.dart';

String _paleoEcologyTooltipMessage(
  PaleoEcologyEntry entry,
  _PaleoBlock block, {
  GeologicRank? inheritedFromRank,
}) {
  final lines = <String>[];

  final hierarchy = _hierarchyPathForTooltip(entry);
  if (hierarchy.isNotEmpty) {
    lines.add(hierarchy);
  }

  final durationMyr = (block.startMa - block.endMa).abs();
  lines.add(
    'Start: ${_formatMaForTooltip(block.startMa)} Ma; Duration: ${_formatMyrForTooltip(durationMyr)} Myr',
  );

  if (entry.avgTempDeltaC != null) {
    lines.add(
      'Temperature delta: ${_formatSignedNumber(entry.avgTempDeltaC!)}°C',
    );
  }
  if (entry.avgHumidityDeltaPercent != null) {
    lines.add(
      'Humidity delta: ${_formatSignedNumber(entry.avgHumidityDeltaPercent!)}%',
    );
  }
  if (entry.seaLevelDeltaM != null) {
    lines.add(
      'Sea level delta: ${_formatSignedNumber(entry.seaLevelDeltaM!)} m',
    );
  }
  if (entry.avgO2Percent != null) {
    lines.add('Oxygen: ${_formatUnsignedNumber(entry.avgO2Percent!)}%');
  }
  if (entry.avgCo2Ppm != null) {
    lines.add('CO2: ${_formatUnsignedNumber(entry.avgCo2Ppm!)} ppm');
  }

  if (entry.icehouseGreenhouseState != null) {
    lines.add('State: ${entry.icehouseGreenhouseState}');
  }
  if (entry.dominantEcology != null) {
    lines.add('Ecology: ${entry.dominantEcology}');
  }
  if (entry.confidence != null) {
    lines.add('Confidence: ${entry.confidence}');
  }
  if (inheritedFromRank != null) {
    lines.add('Inherited geography: ${_formatRankLabel(inheritedFromRank)}');
  }
  if (entry.spatialExtent != null) {
    lines.add('Spatial extent: ${_formatTooltipValue(entry.spatialExtent!)}');
  }
  if (entry.spatialConfidence != null) {
    lines.add(
      'Spatial confidence: ${_formatTooltipValue(entry.spatialConfidence!)}',
    );
  }
  if (entry.hemisphericBias != null) {
    lines.add(
      'Hemispheric bias: ${_formatHemisphericBiasForTooltip(entry.hemisphericBias!)}',
    );
  }
  if (entry.manifestationType.isNotEmpty) {
    lines.add(
      'Manifestation: ${entry.manifestationType.map(_formatTooltipValue).join(', ')}',
    );
  }
  if (entry.geographicAnchor.isNotEmpty) {
    lines.add('Geographic anchor:');
    for (final anchor in entry.geographicAnchor) {
      lines.add('• $anchor');
    }
  }
  if (entry.latitudinalExpression.isNotEmpty) {
    lines.add('Latitudinal expression:');
    for (final line in entry.latitudinalExpression.entries) {
      lines.add('• ${_formatTooltipValue(line.key)}: ${line.value}');
    }
  }
  if (entry.regionalExpression.isNotEmpty) {
    lines.add('Regional expression:');
    for (final line in entry.regionalExpression.entries) {
      lines.add('• ${line.key}: ${line.value}');
    }
  }
  if (entry.note != null) {
    lines.add('Note: ${entry.note}');
  }
  if (entry.sources.isNotEmpty) {
    lines.add('Sources:');
    for (final source in entry.sources) {
      lines.add('• $source');
    }
  }

  return lines.join('\n');
}

String _hierarchyPathForTooltip(PaleoEcologyEntry entry) {
  final depthByRank = <GeologicRank, int>{
    GeologicRank.eon: 1,
    GeologicRank.era: 2,
    GeologicRank.period: 3,
    GeologicRank.epoch: 4,
    GeologicRank.stage: 5,
    GeologicRank.age: 5,
  };
  final maxDepth = depthByRank[entry.rank] ?? entry.path.length;
  final relevant = entry.path
      .take(maxDepth)
      .where((v) => v.trim().isNotEmpty)
      .toList(growable: false)
      .reversed;
  return relevant.join(' \u2190 ');
}

String _formatMaForTooltip(double value) {
  return value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _formatMyrForTooltip(double value) {
  return value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _formatTooltipValue(String value) {
  final normalized = value.trim().replaceAll('_', ' ');
  if (normalized.isEmpty) {
    return normalized;
  }
  return normalized
      .split(RegExp(r'\s+'))
      .map((word) {
        final lower = word.toLowerCase();
        if (lower.length <= 1) {
          return lower.toUpperCase();
        }
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}

String _formatSignedNumber(double value) {
  final sign = value >= 0 ? '+' : '-';
  return '$sign${_formatUnsignedNumber(value.abs())}';
}

String _formatUnsignedNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _formatHemisphericBiasForTooltip(String value) {
  switch (value.trim().toLowerCase()) {
    case 'northern':
      return 'Northern Hemisphere';
    case 'southern':
      return 'Southern Hemisphere';
    case 'both':
      return 'Both hemispheres';
    default:
      return _formatTooltipValue(value);
  }
}

String _formatRankLabel(GeologicRank rank) {
  switch (rank) {
    case GeologicRank.eon:
      return 'Eon';
    case GeologicRank.era:
      return 'Era';
    case GeologicRank.period:
      return 'Period';
    case GeologicRank.epoch:
      return 'Epoch';
    case GeologicRank.stage:
    case GeologicRank.age:
      return 'Stage';
  }
}

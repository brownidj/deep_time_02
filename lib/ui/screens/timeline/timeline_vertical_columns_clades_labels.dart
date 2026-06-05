part of 'timeline_vertical_columns.dart';

String _displayCladeLabel(Clade clade, CladeLabelMode mode) {
  final normalized = clade.label.trim();
  final split = RegExp(r'^\s*(.*?)\s*\((.*?)\)\s*$').firstMatch(normalized);
  final heuristicScientific = (split?.group(1) ?? normalized).trim();
  final heuristicCommon = (split?.group(2) ?? normalized).trim();
  final scientific =
      (clade.scientificLabel ?? clade.openTreeName ?? heuristicScientific)
          .trim();
  final resolvedScientific = scientific.isEmpty ? normalized : scientific;
  final common = heuristicCommon.isEmpty ? normalized : heuristicCommon;
  if (resolvedScientific.toLowerCase() == common.toLowerCase()) {
    return resolvedScientific;
  }
  return '$resolvedScientific ($common)';
}

String _interactiveCladeLabel(
  Clade clade,
  CladeLabelMode mode,
  String? activeCladeRootId,
) {
  final base = _displayCladeLabel(clade, mode);
  if (!clade.zoomable) {
    return base;
  }
  final prefix = activeCladeRootId == clade.id ? '-' : '+';
  return '$prefix $base';
}

String _cladeTooltip(_VerticalCladeBarLayout entry, CladeLabelMode mode) {
  final start = entry.clade.startMa.toStringAsFixed(1);
  final end = entry.clade.endMa.toStringAsFixed(1);
  final duration = (entry.clade.startMa - entry.clade.endMa)
      .abs()
      .toStringAsFixed(1);
  return '${_displayCladeLabel(entry.clade, mode)} • '
      'Crown age: $start Ma - End $end Ma - Myr $duration';
}

part of 'timeline_vertical_columns.dart';

List<Clade> _filterVisibleClades({
  required List<Clade> clades,
  required double visibleStartMa,
  required double visibleEndMa,
  String? displayGroupId,
  required double scale,
  required double availableWidth,
  bool includeAllZoomLevels = false,
  int? preferredVisibleCount,
  bool includeOutsideVisibleRange = false,
}) {
  final resolver = CladeVisibilityResolver(maxClades: 18);
  final widthCap = math.max(
    _maxCladesForWidth(availableWidth),
    preferredVisibleCount ?? 1,
  );
  final baseZoomLevel = resolver.zoomLevelForScale(scale);
  var effectiveZoomLevel = baseZoomLevel;

  List<Clade> filteredForZoom(CladeZoomLevel zoomLevel) {
    var excludedByRange = 0;
    var excludedByZoom = 0;
    var excludedByGroup = 0;
    final filtered =
        clades.where((clade) {
          if (!includeOutsideVisibleRange &&
              !_overlapsVisibleRange(clade, visibleStartMa, visibleEndMa)) {
            excludedByRange += 1;
            return false;
          }
          if (!includeAllZoomLevels &&
              clade.minZoomLevel.index > zoomLevel.index) {
            excludedByZoom += 1;
            return false;
          }
          if (displayGroupId != null &&
              displayGroupId.isNotEmpty &&
              displayGroupId != 'all') {
            if (!clade.displayGroups.contains(displayGroupId)) {
              excludedByGroup += 1;
              return false;
            }
            return true;
          }
          return true;
        }).toList()..sort((a, b) {
          final priorityCompare = a.displayPriority.compareTo(
            b.displayPriority,
          );
          if (priorityCompare != 0) {
            return priorityCompare;
          }
          final durationCompare = b.durationMa.compareTo(a.durationMa);
          if (durationCompare != 0) {
            return durationCompare;
          }
          return a.label.compareTo(b.label);
        });
    _debugCladeZoom(
      'reasons total=${clades.length} pass=${filtered.length} '
      'range=$excludedByRange zoom=$excludedByZoom group=$excludedByGroup '
      'zoomLevel=${zoomLevel.id}',
    );
    return filtered;
  }

  var filtered = filteredForZoom(effectiveZoomLevel);
  while (!includeAllZoomLevels &&
      filtered.length < widthCap &&
      effectiveZoomLevel.index < CladeZoomLevel.epoch.index) {
    effectiveZoomLevel = CladeZoomLevel.values[effectiveZoomLevel.index + 1];
    filtered = filteredForZoom(effectiveZoomLevel);
  }

  AppDebug.log(
    'Clade visibility: width=${availableWidth.toStringAsFixed(1)} cap=$widthCap '
    'candidates=${filtered.length} zoom=${baseZoomLevel.id} '
    'effective=${effectiveZoomLevel.id} allZoom=$includeAllZoomLevels',
  );
  if (filtered.length <= widthCap) {
    _debugCladeZoom(
      'visible=${filtered.length} cap=$widthCap '
      'range=${visibleStartMa.toStringAsFixed(1)}-${visibleEndMa.toStringAsFixed(1)} '
      'allZoom=$includeAllZoomLevels outsideRange=$includeOutsideVisibleRange',
    );
    return filtered;
  }
  final capped = _capCladesByWidth(filtered, widthCap);
  _debugCladeZoom(
    'capped=${capped.length}/${filtered.length} cap=$widthCap '
    'allZoom=$includeAllZoomLevels outsideRange=$includeOutsideVisibleRange',
  );
  return capped;
}

int _maxCladesForWidth(double availableWidth) {
  const minLaneWidth = 30.0;
  const leftRightPadding = 14.0 * 2;
  final usable = math.max(0.0, availableWidth - leftRightPadding - 2.0);
  if (usable <= 0) {
    return 1;
  }
  final lanes = (usable / minLaneWidth).floor();
  return lanes.clamp(1, 200);
}

List<Clade> _capCladesByWidth(List<Clade> sorted, int cap) {
  if (sorted.length <= cap) {
    return sorted;
  }
  final byId = {for (final clade in sorted) clade.id: clade};
  final selectedIds = <String>{};
  final selected = <Clade>[];

  bool addWithAncestors(Clade clade) {
    final chain = <Clade>[];
    Clade? current = clade;
    while (current != null) {
      chain.add(current);
      final parentId = current.parentId;
      current = parentId == null ? null : byId[parentId];
    }
    final needed = chain.where((c) => !selectedIds.contains(c.id)).toList();
    if (selected.length + needed.length > cap) {
      return false;
    }
    for (final candidate in chain.reversed) {
      selectedIds.add(candidate.id);
    }
    return true;
  }

  for (final clade in sorted) {
    if (selected.length >= cap) {
      break;
    }
    if (selectedIds.contains(clade.id)) {
      continue;
    }
    if (!addWithAncestors(clade)) {
      continue;
    }
    selected
      ..clear()
      ..addAll(sorted.where((candidate) => selectedIds.contains(candidate.id)));
  }

  if (selected.length < cap) {
    for (final clade in sorted) {
      if (selected.length >= cap) {
        break;
      }
      if (selectedIds.add(clade.id)) {
        selected.add(clade);
      }
    }
  }

  selected.sort((a, b) {
    final priorityCompare = a.displayPriority.compareTo(b.displayPriority);
    if (priorityCompare != 0) {
      return priorityCompare;
    }
    final durationCompare = b.durationMa.compareTo(a.durationMa);
    if (durationCompare != 0) {
      return durationCompare;
    }
    return a.label.compareTo(b.label);
  });

  return selected;
}

bool _overlapsVisibleRange(
  Clade clade,
  double visibleStartMa,
  double visibleEndMa,
) {
  final cladeMin = clade.endMa;
  final cladeMax = clade.startMa;
  final viewMin = visibleEndMa;
  final viewMax = visibleStartMa;
  return !(cladeMax < viewMin || cladeMin > viewMax);
}

List<_VerticalCladeBarLayout> _layoutCladeBars({
  required List<Clade> visible,
  required Map<String, Clade> allById,
  required _StageRangeMapper mapper,
  required double columnWidth,
  required double columnHeight,
}) {
  const labelHalfWidth = 14.0;
  const padding = labelHalfWidth;
  const minBarHeight = 12.0;
  const lineHitWidth = 72.0;
  final visibleById = {for (final clade in visible) clade.id: clade};

  final layouts = <_VerticalCladeBarLayout>[];
  final ordered = _orderedTreeClades(visible);
  final usable = math.max(0.0, columnWidth - (padding * 2) - 2);
  var skippedZeroHeight = 0;
  var inheritedRangeCount = 0;

  (double, double) effectiveBounds(Clade clade) {
    var start = clade.startMa;
    var end = clade.endMa;
    if (start > end && (start - end).abs() > 0.0001) {
      return (start, end);
    }
    final visited = <String>{clade.id};
    var cursor = clade;
    while (cursor.parentId != null) {
      final parent = allById[cursor.parentId!];
      if (parent == null || !visited.add(parent.id)) {
        break;
      }
      if (parent.startMa > parent.endMa &&
          (parent.startMa - parent.endMa).abs() > 0.0001) {
        inheritedRangeCount += 1;
        return (parent.startMa, parent.endMa);
      }
      cursor = parent;
    }
    return (start, end);
  }

  for (var i = 0; i < ordered.length; i += 1) {
    final clade = ordered[i];
    final (effectiveStartMa, effectiveEndMa) = effectiveBounds(clade);
    final start = (mapper.yForMa(effectiveStartMa) ?? 0.0).clamp(
      0.0,
      columnHeight,
    );
    final end = (mapper.yForMa(effectiveEndMa) ?? columnHeight).clamp(
      0.0,
      columnHeight,
    );
    var top = math.min(start, end).toDouble();
    final span = (end - start).abs();
    var barHeight = math.max(minBarHeight, span);
    if (top + barHeight > columnHeight) {
      barHeight = math.max(0.0, columnHeight - top);
    }
    if (barHeight <= 0 && top >= columnHeight) {
      barHeight = minBarHeight;
      top = math.max(0.0, columnHeight - barHeight);
    }
    if (barHeight <= 0) {
      skippedZeroHeight += 1;
      continue;
    }
    final laneFraction = ordered.length <= 1 ? 0.0 : i / (ordered.length - 1);
    final left = padding + (usable * laneFraction);
    final hitWidth = math.max(12.0, math.min(lineHitWidth, columnWidth - left));
    layouts.add(
      _VerticalCladeBarLayout(
        clade: clade,
        left: left,
        top: top,
        width: hitWidth,
        height: barHeight,
        parent: clade.parentId == null ? null : visibleById[clade.parentId],
        parentLabel: clade.parentId == null
            ? null
            : allById[clade.parentId]?.label,
      ),
    );
  }
  _debugCladeZoom(
    'layout ordered=${ordered.length} laidOut=${layouts.length} skipped=$skippedZeroHeight '
    'inheritedRange=$inheritedRangeCount columnH=${columnHeight.toStringAsFixed(1)}',
  );
  return layouts;
}

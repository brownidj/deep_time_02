part of 'timeline_vertical_columns.dart';

void _debugCladeZoom(String message) {
  debugPrint('[CLADE_DEBUG] $message');
}

List<Clade> _filterCladesForMode({
  required List<Clade> source,
  required List<String> representativeIds,
  required CladeViewMode viewMode,
  required String searchQuery,
  required bool hasActiveRoot,
}) {
  if (!hasActiveRoot && viewMode == CladeViewMode.representativeOnly) {
    return _filterRepresentativeClades(source, representativeIds);
  }
  if (!hasActiveRoot && viewMode == CladeViewMode.searchSpotlight) {
    final query = searchQuery.trim();
    if (query.isEmpty) {
      return _filterRepresentativeClades(source, representativeIds);
    }
    return searchClades(source, query);
  }
  return source;
}

String _displayCladeLabel(Clade clade, CladeLabelMode mode) {
  final normalized = clade.label.trim();
  final split = RegExp(r'^\s*(.*?)\s*\((.*?)\)\s*$').firstMatch(normalized);
  final heuristicScientific = (split?.group(1) ?? normalized).trim();
  final heuristicCommon = (split?.group(2) ?? normalized).trim();
  final scientific =
      (clade.scientificLabel ?? clade.openTreeName ?? heuristicScientific).trim();
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
  final duration = (entry.clade.startMa - entry.clade.endMa).abs().toStringAsFixed(1);
  return '${_displayCladeLabel(entry.clade, mode)} • '
      'Crown age: $start Ma - End $end Ma - Myr $duration';
}

List<Clade> _filterRepresentativeClades(
  List<Clade> source,
  List<String> representativeIds,
) {
  if (representativeIds.isEmpty) {
    return source;
  }
  final byId = {for (final clade in source) clade.id: clade};
  final idSet = <String>{};
  void addWithAncestors(String id) {
    if (!idSet.add(id)) {
      return;
    }
    final parentId = byId[id]?.parentId;
    if (parentId != null) {
      addWithAncestors(parentId);
    }
  }

  for (final id in representativeIds) {
    addWithAncestors(id);
  }
  return source.where((clade) => idSet.contains(clade.id)).toList();
}

List<Clade> _collectDescendants({
  required String rootId,
  required Map<String, List<Clade>> childrenByParentId,
}) {
  final collected = <Clade>[];
  final visited = <String>{};

  void visit(String parentId) {
    final children = childrenByParentId[parentId] ?? const <Clade>[];
    for (final child in children) {
      if (!visited.add(child.id)) {
        continue;
      }
      collected.add(child);
      visit(child.id);
    }
  }

  visit(rootId);
  return collected;
}

List<Clade> _scopeCladesForActiveRoot({
  required List<Clade> source,
  required String? activeRootId,
  required Map<String, List<Clade>> childrenByParentId,
  int targetVisibleCount = 40,
}) {
  final rootId = activeRootId?.trim();
  if (rootId == null || rootId.isEmpty) {
    return source;
  }
  final byId = {for (final clade in source) clade.id: clade};
  final root = byId[rootId];
  if (root == null) {
    _debugCladeZoom('activeRoot=$rootId not found in source (${source.length})');
    return source;
  }
  int compareClades(Clade a, Clade b) {
    final priorityCompare = a.displayPriority.compareTo(b.displayPriority);
    if (priorityCompare != 0) {
      return priorityCompare;
    }
    final durationCompare = b.durationMa.compareTo(a.durationMa);
    if (durationCompare != 0) {
      return durationCompare;
    }
    return a.label.compareTo(b.label);
  }

  final scopedIds = <String>{root.id};
  var frontier = List<Clade>.from(childrenByParentId[root.id] ?? const <Clade>[])
    ..sort(compareClades);
  _debugCladeZoom(
    'scope root=$rootId source=${source.length} directChildren=${frontier.length}',
  );
  var depth = 0;
  while (frontier.isNotEmpty && scopedIds.length < targetVisibleCount) {
    final nextFrontier = <Clade>[];
    var addedAtDepth = 0;
    for (final clade in frontier) {
      if (scopedIds.length >= targetVisibleCount) {
        break;
      }
      if (scopedIds.add(clade.id)) {
        addedAtDepth += 1;
        nextFrontier.addAll(childrenByParentId[clade.id] ?? const <Clade>[]);
      }
    }
    _debugCladeZoom(
      'scope root=$rootId depth=$depth frontier=${frontier.length} '
      'added=$addedAtDepth next=${nextFrontier.length} total=${scopedIds.length}',
    );
    nextFrontier.sort(compareClades);
    frontier = nextFrontier;
    depth += 1;
  }

  // If fewer than target are available across early generations, include all descendants.
  if (scopedIds.length < targetVisibleCount) {
    final descendants = _collectDescendants(
      rootId: rootId,
      childrenByParentId: childrenByParentId,
    );
    scopedIds.addAll(descendants.map((clade) => clade.id));
  }

  _debugCladeZoom(
    'activeRoot=$rootId target=$targetVisibleCount scoped=${scopedIds.length} '
    'sample=${scopedIds.take(10).join(",")}',
  );
  return source.where((clade) => scopedIds.contains(clade.id)).toList();
}

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
    final filtered = clades.where((clade) {
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
    }).toList()
      ..sort((a, b) {
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
    _debugCladeZoom(
      'reasons total=${clades.length} pass=${filtered.length} '
      'range=$excludedByRange zoom=$excludedByZoom group=$excludedByGroup '
      'zoomLevel=${zoomLevel.id}',
    );
    return filtered;
  }

  var filtered = filteredForZoom(effectiveZoomLevel);
  while (
      !includeAllZoomLevels &&
      filtered.length < widthCap &&
      effectiveZoomLevel.index < CladeZoomLevel.epoch.index) {
    effectiveZoomLevel =
        CladeZoomLevel.values[effectiveZoomLevel.index + 1];
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

  // Pass 1: preserve ancestry where possible.
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
      ..addAll(
        sorted.where((candidate) => selectedIds.contains(candidate.id)),
      );
  }

  // Pass 2: fill any remaining width-cap slots with top-ranked clades,
  // even if full ancestor chains are not available within the cap.
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
    // Detail subtrees can include clades with unknown temporal bounds,
    // which map to a zero-span at the present-day edge. Keep them visible.
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
